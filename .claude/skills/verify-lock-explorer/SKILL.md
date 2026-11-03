---
name: verify-lock-explorer
description: "Verify a change to omarchy-lock-explorer, the Omarchy shell plugin with the lock screen designs, the explorer overlay, the designer and the bar icon. Use in a gate run or after any edit to the QML, JS or extras scripts, to prove it with runs and keep evidence."
---

# Verify omarchy-lock-explorer

The repo is a Quickshell plugin that the running `omarchy-shell` loads from
`~/.config/omarchy/plugins`. Its surfaces are the lock screen, the explorer overlay
(`Explorer.qml`), the bar icon (`BarWidget.qml`) and the `omarchy-shell lock <command>` IPC.
Only the user's own shell runs these. Never install, reload or drive the user's shell, and
never lock the screen. Verification here runs the repo's checks and drives the extras
scripts in a throwaway `HOME`.

## Launch

There is no app to start. One command runs every step:

```
.claude/skills/verify-lock-explorer/verify.sh run
```

`verify.sh static` runs the checks only; `verify.sh bar-icon` runs only the bar icon drive.
Each step writes its log to the evidence folder. Exit 0 means every step passed.

## Doctor

Run `verify.sh` bare. It prints the repo path and the `qmllint` that it found. If `qmllint`
is missing, `extras/qml-syntax-check.sh` prints a note and passes, so the QML parse proves
nothing; install `qt6-declarative` first. Also needed: `node`, `python3`, `jq`, `shellcheck`.

## Drive

- QML parse: `extras/qml-syntax-check.sh` parses all `.qml` files with `qmllint`. A file
  that does not parse cannot load in the shell. Warnings for `qs.Commons` and Quickshell
  imports are expected and filtered.
- Logic: `node --test tests/*.test.cjs` runs the JS tests of `Bridge.js`, `Designs.js` and
  more.
- UI to service contract: `extras/test-service-api.py` checks that every service member that
  the UI uses exists.
- Bar icon: `extras/bar-icon.sh` adds, reports and removes the widget in
  `$HOME/.config/omarchy/shell.json`. `verify.sh bar-icon` sets `HOME` to a temp folder and
  checks the JSON with `jq`. See `features/bar-icon.md`.

## Evidence

The evidence folder is `/tmp/verify-lock-explorer-<timestamp>`, or `$VERIFY_EVIDENCE` if
set. It holds one `.log` per step and `shell.json.after-add` and `shell.json.after-remove`.
Quote the `ok`/`FAIL` lines and the folder path in the gate report.

## Cleanup

`verify.sh` removes its temp `HOME` itself. It starts no process. Keep the evidence folder.

## Gotchas

- Open question: there is no way yet to render a QML file headless, because the plugin
  imports `qs.Commons` from the shell. A visual change (icon, design, layout) is proven
  only to parse, not to look right. A nested `omarchy-shell` with its own `HOME` and
  Wayland socket is untested.
- Open question: `Service.qml` logic such as `addBarIconOnceOnFirstStart()` runs only in the shell.
  Nothing here drives its timers; the bar icon drive proves only the script that it calls.
- `extras/boot-vm-test.sh` and `extras/addon-vm-test.sh` boot QEMU and read the host UKI.
  Run them only for a change under `plymouth/`; they are slow and not part of `verify.sh`.
- A comment-only change in QML: the QML parse and the facade test are the proof.
