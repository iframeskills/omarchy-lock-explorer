const assert = require("node:assert/strict");
const { spawn, spawnSync } = require("node:child_process");
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

function copyPlugin(dir, edit) {
  fs.mkdirSync(dir, { recursive: true });
  for (const name of fs.readdirSync(root).filter((name) => /\.(qml|js)$/.test(name)))
    fs.copyFileSync(path.join(root, name), path.join(dir, name));
  fs.cpSync(path.join(root, "designs"), path.join(dir, "designs"), { recursive: true });
  fs.cpSync(path.join(root, "explorer-strings"), path.join(dir, "explorer-strings"), { recursive: true });
  if (!edit) return;
  const [file, from, to] = edit;
  const target = path.join(dir, file);
  const source = fs.readFileSync(target, "utf8");
  assert.ok(source.includes(from), `${file} no longer has the fixture line ${from}`);
  fs.writeFileSync(target, source.replace(from, to));
}

function brokenCopy(file, from, to) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "lock-explorer-contracts-"));
  copyPlugin(dir, [file, from, to]);
  return dir;
}

const quickshellSkip = spawnSync("quickshell", ["--version"]).status === 0 ? false : "quickshell is not installed";

const cardProbe = `import QtQuick
Item {
  id: top
  readonly property var marker: ({ tag: "explorer-root" })
  ExplorerCard { id: card; root: top.marker }
  function modules(o, out) {
    if (!o) return out
    if (o !== card && "root" in o) out.push({ type: String(o).split(/_QMLTYPE_|\\(/)[0], ok: o.root === top.marker })
    var kids = o.data || []
    for (var i = 0; i < kids.length; i++) modules(kids[i], out)
    return out
  }
  Component.onCompleted: console.warn("RESULT " + JSON.stringify({ card: card.root === top.marker, modules: modules(card, []) }))
}
`;

function nestedRoots(edit) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "lock-explorer-roots-"));
  const shell = path.join(dir, "shell");
  copyPlugin(path.join(shell, "app"), edit);
  fs.writeFileSync(path.join(shell, "app", "CardProbe.qml"), cardProbe);
  fs.writeFileSync(path.join(shell, "shell.qml"), 'import Quickshell\nimport "app"\nShellRoot { CardProbe {} }\n');
  fs.mkdirSync(path.join(shell, "Commons"));
  for (const name of ["Style", "Color", "Settings"])
    fs.writeFileSync(path.join(shell, "Commons", `${name}.qml`), "pragma Singleton\nimport QtQml\nQtObject {}\n");
  fs.mkdirSync(path.join(shell, "Ui"));
  fs.writeFileSync(path.join(shell, "Ui", "BorderSurface.qml"), "import QtQuick\nRectangle {\n  property var borderSpec\n  property var padding\n}\n");
  const home = path.join(dir, "home");
  const runtime = path.join(dir, "runtime");
  fs.mkdirSync(home);
  fs.mkdirSync(runtime, { mode: 0o700 });
  const env = { ...process.env, HOME: home, XDG_RUNTIME_DIR: runtime, XDG_CONFIG_HOME: path.join(home, ".config"),
    XDG_STATE_HOME: path.join(home, ".state"), XDG_CACHE_HOME: path.join(home, ".cache"), QT_QPA_PLATFORM: "offscreen" };
  delete env.WAYLAND_DISPLAY;
  delete env.DISPLAY;
  return new Promise((resolve, reject) => {
    const child = spawn("quickshell", ["-p", path.join(shell, "shell.qml")], { env, stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    let result = null;
    const timer = setTimeout(() => child.kill("SIGKILL"), 30000);
    const read = (chunk) => {
      output += chunk;
      const match = /RESULT (\{.*\})/.exec(output);
      if (match && !result) {
        result = JSON.parse(match[1]);
        child.kill("SIGTERM");
      }
    };
    child.stdout.on("data", read);
    child.stderr.on("data", read);
    child.on("close", () => {
      clearTimeout(timer);
      fs.rmSync(dir, { recursive: true, force: true });
      if (result) resolve(result);
      else reject(new Error(`quickshell printed no result:\n${output.slice(-2000)}`));
    });
  });
}

const cardModules = ["ExplorerBootPage", "ExplorerGrid", "ExplorerHeader", "ExplorerPreviewPanel", "ExplorerSettingsPage", "ExplorerSettingsPane"];

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

test("every module nested in the explorer card receives the explorer root", { skip: quickshellSkip }, async () => {
  const result = await nestedRoots();
  assert.equal(result.card, true);
  assert.deepEqual([...new Set(result.modules.map((m) => m.type))].filter((t) => cardModules.includes(t)).sort(), cardModules);
  assert.deepEqual(result.modules.filter((m) => !m.ok), []);
});

test("the root check rejects a nested module that binds root to itself", { skip: quickshellSkip }, async () => {
  const result = await nestedRoots(["ExplorerSettingsPane.qml", "ExplorerSettingsPage { id: settingsPage; root: settingsPane.root }", "ExplorerSettingsPage { id: settingsPage; root: root }"]);
  assert.deepEqual(result.modules.filter((m) => !m.ok).map((m) => m.type), ["ExplorerSettingsPage"]);
});
