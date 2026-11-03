# Bar icon

The bar icon is a lock with a small cog at the end of the bar's right section. A click opens
the explorer, a right click opens the full explorer. The plugin adds it once on the first
start and records `barIconDefaulted`, so that a removal sticks.

## Sub-features

- `bar-icon-add`: `extras/bar-icon.sh` adds a `qml` module with id `lock-explorer`.
- `bar-icon-status`: `extras/bar-icon.sh --status` prints `installed` or `missing`.
- `bar-icon-remove`: `extras/bar-icon.sh --remove` takes it off.
- `bar-icon-default`: `addBarIconOnceOnFirstStart()` in `Service.qml` calls the script on the first start.

## How to get to it (user POV)

- The Settings tab of the explorer, row "Bar icon".
- `omarchy-shell lock setBarIcon on` or `off`.

## Driving it with verify.sh

Run `.claude/skills/verify-lock-explorer/verify.sh bar-icon`. In a temp `HOME` it checks:
status `missing`, add, status `installed`, exactly one `lock-explorer` entry with the repo's
`BarWidget.qml` as `source`, a second add keeps one entry, remove, status `missing`.
The evidence is `shell.json.after-add` and `shell.json.after-remove`.

## Gotchas

- Without a `shell.json`, the script copies the defaults from
  `${OMARCHY_PATH:-/usr/share/omarchy}/config/omarchy/shell.json`, so the result depends on
  the installed Omarchy version.
- `bar-icon-default` and the icon drawing in `BarWidget.qml` are not driven; only the QML
  parse covers them.
