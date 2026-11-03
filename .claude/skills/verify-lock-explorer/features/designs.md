# Lock screen designs

The designs under `designs/` are the lock screens. The explorer overlay previews them and
switches between them, and the designer builds new ones.

## Sub-features

- `design-load`: each design QML parses.
- `design-strings`: the explorer labels in `ExplorerStrings.js`.
- `design-facade`: every service member that the explorer uses exists.

## How to get to it (user POV)

- Click the bar icon, or run `omarchy-shell lock explore`.

## Driving it with verify.sh

Run `.claude/skills/verify-lock-explorer/verify.sh static`. Require `ok` on `qml-syntax`,
`node-tests` and `service-facade`. `qml-syntax.log` names the file count, for example
`qml syntax: OK (107 of 107 files reported)`.

## Gotchas

- No headless render exists, so a visual change is not proven to look right.
- Never run `omarchy-shell lock` commands here: they reach the user's own shell.
