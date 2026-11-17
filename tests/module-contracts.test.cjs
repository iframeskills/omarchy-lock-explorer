const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");

const root = path.join(__dirname, "..");
const files = fs.readdirSync(root).filter((name) => /^(Service|Explorer|Designer).*\.qml$/.test(name));
const sources = new Map(files.map((name) => [name, fs.readFileSync(path.join(root, name), "utf8")]));

function declarations(source) {
  return new Set([
    ...Array.from(source.matchAll(/\bproperty\s+\w+\s+(\w+)\s*:/g), (match) => match[1]),
    ...Array.from(source.matchAll(/\bfunction\s+(\w+)\s*\(/g), (match) => match[1]),
    ...Array.from(source.matchAll(/\bsignal\s+(\w+)\s*\(/g), (match) => match[1]),
  ]);
}

function objects(source) {
  return new Map(Array.from(source.matchAll(/\b([A-Z]\w*)\s*\{[^{}]*?\bid:\s*(\w+)/g), (match) => [match[2], match[1]]));
}

test("extracted components keep every exported object and property connected", () => {
  let checked = 0;
  for (const [file, source] of sources) {
    const types = objects(source);
    for (const match of source.matchAll(/\bproperty alias (\w+):\s*(\w+)(?:\.(\w+))?/g)) {
      const [, name, object, member] = match;
      assert.ok(types.has(object), `${file}: ${name} targets missing object ${object}`);
      const target = sources.get(types.get(object) + ".qml");
      if (member && target)
        assert.ok(declarations(target).has(member), `${file}: ${name} targets missing member ${object}.${member}`);
      checked++;
    }
  }
  assert.ok(checked > 300);
});

test("entry points forward actions to existing module methods", () => {
  let checked = 0;
  for (const file of ["Service.qml", "Explorer.qml"]) {
    const source = sources.get(file);
    const types = objects(source);
    for (const match of source.matchAll(/function (\w+)\([^)]*\)\s*\{ return (\w+)\.(\w+)\([^)]*\) \}/g)) {
      const [, name, object, method] = match;
      if (object === "Qt") continue;
      const target = sources.get(types.get(object) + ".qml");
      assert.ok(target, `${file}: ${name} targets missing module ${object}`);
      assert.ok(declarations(target).has(method), `${file}: ${name} targets missing method ${object}.${method}`);
      checked++;
    }
  }
  assert.ok(checked > 200);
});
