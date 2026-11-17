const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { test } = require("node:test");

const root = path.join(__dirname, "..");
const modulePattern = /^(Service|Explorer|Designer).*\.qml$/;

function findQmllint() {
  for (const candidate of ["qmllint", "qmllint-qt6", "/usr/lib/qt6/bin/qmllint", "/usr/lib/qt6/libexec/qmllint"]) {
    if (spawnSync(candidate, ["--version"]).status === 0) return candidate;
  }
  return null;
}

const qmllint = findQmllint();
const skip = qmllint ? false : "qmllint is not installed";

function contractProblems(dir) {
  const files = fs.readdirSync(dir).filter((name) => modulePattern.test(name));
  const localTypes = new Set(fs.readdirSync(dir).filter((name) => name.endsWith(".qml")).map((name) => name.slice(0, -4)));
  const run = spawnSync(qmllint, ["--json", "-", ...files], { cwd: dir, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  const report = JSON.parse(run.stdout);
  const problems = [];
  for (const entry of report.files) {
    for (const warning of entry.warnings) {
      const target = /not found on type "(\w+)"/.exec(warning.message);
      const broken = warning.id === "unresolved-alias" || warning.id === "alias-cycle"
        || (warning.id === "missing-property" && target && localTypes.has(target[1]));
      if (broken) problems.push(`${path.basename(entry.filename)}:${warning.line}: ${warning.message}`);
    }
  }
  return { files, problems };
}

function brokenCopy(file, from, to) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "lock-explorer-contracts-"));
  for (const name of fs.readdirSync(root).filter((name) => /\.(qml|js)$/.test(name)))
    fs.copyFileSync(path.join(root, name), path.join(dir, name));
  fs.cpSync(path.join(root, "designs"), path.join(dir, "designs"), { recursive: true });
  fs.cpSync(path.join(root, "explorer-strings"), path.join(dir, "explorer-strings"), { recursive: true });
  const target = path.join(dir, file);
  const source = fs.readFileSync(target, "utf8");
  assert.ok(source.includes(from), `${file} no longer has the fixture line ${from}`);
  fs.writeFileSync(target, source.replace(from, to));
  return dir;
}

test("qmllint resolves every alias and forwarded member of the split modules", { skip }, () => {
  const { files, problems } = contractProblems(root);
  for (const entry of ["Service.qml", "Explorer.qml", "Designer.qml"]) assert.ok(files.includes(entry));
  assert.deepEqual(problems, []);
});

test("the check rejects an alias to a renamed module property", { skip }, () => {
  const dir = brokenCopy("Service.qml", "property alias shell: settingsStore.shell", "property alias shell: settingsStore.shellRenamed");
  try {
    assert.match(contractProblems(dir).problems.join("\n"), /Service\.qml:\d+: Cannot resolve alias "shell"/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("the check rejects a forwarder to a missing module method", { skip }, () => {
  const dir = brokenCopy("Explorer.qml", "return navigation.nextTourStep()", "return navigation.nextTourStepRenamed()");
  try {
    assert.match(contractProblems(dir).problems.join("\n"), /Explorer\.qml:\d+: Member "nextTourStepRenamed" not found on type "ExplorerNavigation"/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
