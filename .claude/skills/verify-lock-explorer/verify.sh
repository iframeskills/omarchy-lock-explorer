#!/bin/bash
set -uo pipefail
repo=$(cd "$(dirname "$(realpath "$0")")/../../.." && pwd)
run=${1:-}
help_block() {
  echo "help[3]:"
  echo "  verify.sh run        static checks and the bar-icon drive"
  echo "  verify.sh static     tests, QML parse and security checks only"
  echo "  verify.sh bar-icon   add and remove the bar icon in a throwaway HOME"
}
case $run in
  ""|-h|--help)
    echo "bin: verify.sh"
    echo "description: proves omarchy-lock-explorer changes without the user's own shell"
    echo "repo: $repo"
    echo "qmllint: $(command -v qmllint /usr/lib/qt6/bin/qmllint 2>/dev/null | head -1 || echo missing)"
    help_block; exit 0 ;;
  run|static|bar-icon) ;;
  *) echo "error: unknown command '$run'"; help_block; exit 2 ;;
esac
evidence=${VERIFY_EVIDENCE:-/tmp/verify-lock-explorer-$(date +%Y%m%d-%H%M%S)}
mkdir -p "$evidence"
cd "$repo" || exit 1
status=0

step() {
  local name=$1; shift
  if "$@" >"$evidence/$name.log" 2>&1; then
    echo "ok    $name"
  else
    echo "FAIL  $name (exit $?, see $evidence/$name.log)"
    status=1
  fi
}

static() {
  step node-tests node --test tests/*.test.cjs
  step qml-report-test python3 tests/qml-syntax-report.test.py
  step qml-syntax bash extras/qml-syntax-check.sh
  step service-facade python3 extras/test-service-api.py
  step clip-filenames python3 extras/test-clip-filenames.py
  step security bash extras/security-check.sh
  step safe-paths bash extras/test-safe-paths.sh
  step root-theme bash extras/test-root-theme.sh
  step layout-values bash extras/test-layout-values.sh
}

bar_icon_drive() {
  local home
  home=$(mktemp -d /tmp/verify-lock-explorer-home.XXXXXX)
  (
    set -e
    export HOME=$home
    unset XDG_CONFIG_HOME
    test "$(bash extras/bar-icon.sh --status)" = missing
    bash extras/bar-icon.sh
    test "$(bash extras/bar-icon.sh --status)" = installed
    jq -e --arg src "$repo/BarWidget.qml" '[.bar.layout.right[] | select(.id == "lock-explorer" and .type == "qml" and .source == $src)] | length == 1' "$HOME/.config/omarchy/shell.json"
    cp "$HOME/.config/omarchy/shell.json" "$evidence/shell.json.after-add"
    bash extras/bar-icon.sh
    jq -e '[.bar.layout.right[] | select(.id == "lock-explorer")] | length == 1' "$HOME/.config/omarchy/shell.json"
    bash extras/bar-icon.sh --remove
    test "$(bash extras/bar-icon.sh --status)" = missing
    cp "$HOME/.config/omarchy/shell.json" "$evidence/shell.json.after-remove"
  )
  local rc=$?
  rm -rf -- "$home"
  return $rc
}

case $run in
  run) static; step bar-icon bar_icon_drive ;;
  static) static ;;
  bar-icon) step bar-icon bar_icon_drive ;;
esac
echo "evidence: $evidence"
help_block
exit $status
