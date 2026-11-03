---
name: formal-bar-icon-first-start
description: "Formal check of the bar icon first start in omarchy-lock-explorer: addBarIconOnceOnFirstStart, its retry timer, setBarIcon and barIconApplyProc in Service.qml. Use when a change touches that code, the barIconDefaulted flag, or extras/bar-icon.sh, and in a gate run that names Service.qml."
metadata:
  covers: "Service.qml LocalSettings.qml extras/bar-icon.sh"
  sync: c20907c7a3397a59e801fd863b3b2a3a936bea8a
  check: ".claude/skills/formal-bar-icon-first-start/check"
---

# Formal check of the bar icon first start

On the first start the plugin puts its lock icon on the bar once, and records
`barIconDefaulted` on its entry in `~/.config/omarchy/shell.json`. Two processes write that
file: `extras/bar-icon.sh` (run by `setBarIcon` through `barIconApplyProc`) and the plugin's
own `writeEntry`.

## Properties

- `DefaultedNeverWrittenWhileBarIconScriptRuns`: the first-start function never writes the
  entry while `bar-icon.sh` runs. Harm if broken: one write overwrites the other, and the icon
  or a setting is lost.
- `NoAutoAddOnceDefaulted`: once `barIconDefaulted` is true, the plugin never adds the icon by
  itself again, also after a restart. Harm if broken: the user turns the icon off and it comes
  back.

## Run

```
.claude/skills/formal-bar-icon-first-start/check
```

Exit 0: every property holds. Exit 1: a property breaks, or a code anchor is gone. Exit 2:
TLC cannot run. It needs `tla2tools.jar` 1.7.4 (mise `http-tla2tools`) and Java 25 (mise
`java temurin-25`). Set `TLA2TOOLS_JAR` or `JAVA` to override. A run takes about 2 seconds.

The check does two things. It runs TLC on `BarIconFirstStart.tla` with `ok.cfg`. Then it
reads `Service.qml` and fails if a guard in `addBarIconOnceOnFirstStart` is gone or moved, if
`setBarIcon` lost `if (barIconApplyProc.running) return false`, or if
`barIconFirstStartRetryTimer.start()` is gone. The anchors tie the model to the code.

Read each TLC result with the `/statechart` skill. It shows an invariant violation as its
shortest path in plain words.

## Model to code

| Model | Code |
|---|---|
| `TimerFires` (one step) | one call of `addBarIconOnceOnFirstStart` in `Service.qml`. QML runs JS on one thread, so one call is one step. |
| `CheckDefaultedGuard` | `if (pluginEntry().barIconDefaulted === true) return` |
| `CheckProcGuard` | `if (barIconApplyProc.running) { barIconFirstStartRetryTimer.restart(); return }` |
| `barHasWidget` | `localSettings.barHasWidget`, set in `parse()` of `LocalSettings.qml` |
| `attempts`, `MaxAttempts = 5` | `barIconFirstStartRetryTimer.attempts++ < 5` |
| `procRunning`, `procAdds` | `barIconApplyProc.running`, and its command with or without `--remove` |
| `ProcExits`, `Reload` | `onExited: localSettings.reload()`. The reload is a separate step, because the file view can lag. |
| `UserSetsBarIcon` | the Settings "Bar icon" row and `omarchy-shell lock setBarIcon`, both through `setBarIcon` |
| `PluginRestarts` | `Component.onCompleted` starts the timer. `barIconDefaulted` survives in shell.json. |

## Proof that it can fail

- `broken-proc-guard.cfg` removes the running guard. `DefaultedNeverWrittenWhileBarIconScriptRuns`
  breaks in 3 steps: the timer adds the icon, the script still runs, the timer writes the flag.
- `broken-defaulted-guard.cfg` removes the flag guard. `NoAutoAddOnceDefaulted` breaks after
  a restart with the icon removed.
- Real code: if the running guard in `Service.qml` becomes `if (false)`, `check` exits 1.
  This was done at `sync`, then reverted.

To run a variant by hand, run this from this folder:
`java -cp <tla2tools.jar> tlc2.TLC -deadlock -config <variant>.cfg BarIconFirstStart.tla`

## Finding

`user-off-window.cfg` checks `NoAutoAddAfterUserTurnedOff`, and it breaks on the current code.
Steps: the first start adds the icon. Before the next 3 s timer tick records
`barIconDefaulted`, the user turns the icon off. The script removes it. The timer sees no
icon and runs `setBarIcon(true)` again. The user's choice is lost in the first seconds after
the first start. It is not in `check`, because the documented promise covers only the time
after the flag is recorded. Product code is unchanged.

## Scope

Verified: every order of timer ticks, script exits, reloads, user toggles and restarts, with
5 attempts, from both start states (icon on the bar or not). Left out: other `writeEntry`
callers (the settings rows) while `bar-icon.sh` runs, the shell's own writes to shell.json,
a failing `bar-icon.sh`, a missing `shell.updateEntryInline`, and the contents of
`bar-icon.sh`. `BarWidget.qml` holds only drawing and is not modeled.

## Open questions

- Must a user's "off" in the first seconds after the first start win? If yes, the finding is
  a bug, and `NoAutoAddAfterUserTurnedOff` can move into `ok.cfg` after the fix.
- Can a settings-row `writeEntry` run while `bar-icon.sh` runs and overwrite its change? The
  model does not cover it.

## When the code changes

If a change renames or reorders the guards on purpose, update the table, the anchors in
`check` and the model in one change. Rerun the broken variants, and move `sync` to the new
commit only after `check` exits 0. If `check` fails and the change was not meant to alter the
first-start logic, it is a real bug: report the steps, and do not weaken the model.
`/maintain-formal-verification-skill` brings this skill back in line after changes that did
not recheck it.
