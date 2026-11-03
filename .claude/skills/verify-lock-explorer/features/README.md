# Lock explorer verification map

Each file here is one user-facing feature and the steps that prove it without the user's
own shell.

## Baseline preconditions

- Run from the repo root of the checkout under test.
- `qmllint`, `node`, `python3`, `jq` and `shellcheck` are installed.
- Every drive that writes config sets `HOME` to a new temp folder.

## Features

- [`bar-icon.md`](bar-icon.md): the lock icon on the Omarchy bar.
- [`designs.md`](designs.md): the lock screen designs and the explorer that picks one.

## Proof and skip reporting

- Report the `verify.sh` lines, the exit code and the evidence folder.
- Report a visual change as "parses, not rendered". Do not claim that it looks right.
