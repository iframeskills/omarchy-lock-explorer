import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import "Designs.js" as Designs
import "DisplayPower.js" as DisplayPower
import "Bridge.js" as Bridge
import "designs/Strings.js" as Strings
import "designs" as Parts

Item {
  required property var root
  readonly property alias barIconApplyProc: barIconApplyProc
  readonly property alias duplicatePluginProc: duplicatePluginProc
  readonly property alias rivalLockCheckTimer: rivalLockCheckTimer
  readonly property alias themeBackgroundTimer: themeBackgroundTimer


  readonly property string pluginDir: {
    var u = String(Qt.resolvedUrl("."))
    return decodeURIComponent(u.replace(/^file:\/\//, "")).replace(/\/$/, "")
  }

  // A timestamped backup copy left in ~/.config/omarchy/plugins/ is found as a
  // second plugin with this same id, and which of the two the shell loads is
  // not something either copy decides. It costs an afternoon to work out from
  // the symptoms, so say it plainly at startup (issue #29).
  property var shadowingDirs: []

  Process {
    id: duplicatePluginProc
    // The id is matched in the manifest rather than parsed out of it: a
    // grep says whether this file claims the same id, which is the whole
    // question. Hidden directories count, and a backup copy is usually one.
    command: ["bash", "-c",
      "find \"$1\" -mindepth 2 -maxdepth 2 -name manifest.json -type f 2>/dev/null | while read -r m; do " +
      "grep -D skip -q \"\\\"id\\\"[[:space:]]*:[[:space:]]*\\\"$2\\\"\" \"$m\" && dirname \"$m\"; done",
      "bash", Quickshell.env("HOME") + "/.config/omarchy/plugins", root.pluginId]
    stdout: StdioCollector { id: duplicatePluginStdout; waitForEnd: true }
    onExited: {
      var found = String(duplicatePluginStdout.text || "").split("\n")
        .map(function(line) { return line.trim().replace(/\/$/, "") })
        .filter(function(line) { return line.length > 0 && line !== root.pluginDir })
      root.shadowingDirs = found
      if (found.length === 0) return
      root.logEvent("shadowed-by " + found.join(" "))
      console.warn("lock-explorer: another copy of this plugin is installed under the same id and"
        + " may load instead of this one: " + found.join(", ")
        + ". Move it out of ~/.config/omarchy/plugins/ (a backup belongs anywhere else).")
    }
  }

  // Another enabled plugin that also replaces omarchy.lock registers the same
  // `lock` IPC target. Whichever loads first keeps it, so `omarchy-shell lock
  // explore` answers "Function not found" and nothing in the shell says why
  // (issue #41). Ask the shell which plugins are on and name the other one.
  property var rivalLockPlugins: []
  property bool rivalLockNotified: false

  Timer {
    id: rivalLockCheckTimer
    // After the shell has settled; right after a reload it may still list the
    // stock lock being swapped out.
    interval: 5000
    onTriggered: if (!rivalLockProc.running) rivalLockProc.running = true
  }

  Process {
    id: rivalLockProc
    command: ["omarchy-shell", "shell", "listPlugins"]
    stdout: StdioCollector { id: rivalLockStdout; waitForEnd: true }
    onExited: {
      var plugins = []
      try { plugins = JSON.parse(String(rivalLockStdout.text || "[]")) } catch (e) { return }
      if (!Array.isArray(plugins)) return
      var found = plugins.filter(function(p) {
        return p && p.enabled === true && String(p.clonedFrom || "") === "omarchy.lock"
          && String(p.id || "") !== root.pluginId
      }).map(function(p) { return String(p.id) })
      root.rivalLockPlugins = found
      if (found.length === 0) return
      root.logEvent("rival-lock " + found.join(" "))
      console.warn("lock-explorer: another lock screen plugin is enabled and may own the `lock` IPC target: "
        + found.join(", ") + ". Keep one: omarchy plugin disable " + found[0] + " && omarchy restart shell")
      if (root.rivalLockNotified) return
      root.rivalLockNotified = true
      Quickshell.execDetached(["notify-send", "-a", "Lock Screen Explorer", found.join(", ") + " is also enabled",
        "Two lock screen plugins are on. Keep one:\nomarchy plugin disable " + found[0] + "\nomarchy restart shell"])
    }
  }

  // What the explorer's Settings offers when something is missing. Both run
  // in a terminal the user can see: pacman asks for the password there, and
  // the doctor's report stays on screen until a key is pressed. Only the
  // packages the plugin itself uses can be asked for.
  readonly property var installablePackages: ["qt6-multimedia", "qt6-imageformats"]
  readonly property string doctorPath: root.pluginDir + "/extras/doctor.sh"

  function shellQuote(text) { return "'" + String(text).replace(/'/g, "'\\''") + "'" }

  // The terminal is Omarchy's floating one. Whether it came up is read off
  // Hyprland's window list: a terminal that cannot start (Ghostty without
  // OpenGL 4.3, a missing default) would otherwise close the explorer onto
  // nothing at all, so then a notification gives the command to run by hand.
  property string terminalFallback: ""
  Process {
    id: terminalProc
    onExited: function(exitCode) {
      if (exitCode === 0) return
      root.logEvent("terminal-missing")
      Quickshell.execDetached(["notify-send", "-a", "Lock Screen Explorer", "No terminal opened",
                               "Run this in a terminal instead:\n" + root.terminalFallback])
    }
  }

  function openInTerminal(command, fallback) {
    if (terminalProc.running) return false
    root.terminalFallback = fallback || command
    terminalProc.command = ["bash", "-c", "count() { hyprctl clients -j 2>/dev/null | jq '[.[] | select(.class == \"org.omarchy.terminal\")] | length' 2>/dev/null; }; launch() { setsid -f omarchy-launch-floating-terminal-with-presentation \"$1\" >/dev/null 2>&1; }; if ! command -v hyprctl >/dev/null || ! command -v jq >/dev/null; then launch \"$1\"; exit 0; fi; before=$(count); before=${before:-0}; launch \"$1\"; for _ in $(seq 24); do sleep 0.25; now=$(count); (( ${now:-0} > before )) && exit 0; done; exit 1", "bash", command]
    terminalProc.running = true
    return true
  }

  function installPackages(names) {
    var list = (names || []).map(String).filter(function(n) { return root.installablePackages.indexOf(n) !== -1 })
    if (list.length === 0) return false
    root.openInTerminal("omarchy-pkg-add " + list.join(" ") + " && omarchy restart shell",
                   "omarchy pkg add " + list.join(" ") + " && omarchy restart shell")
    root.logEvent("install " + list.join(" "))
    return true
  }

  // A second copy of the plugin found at startup (shadowingDirs), moved out of
  // the plugins folder by the doctor's --fix, which only ever moves what its
  // own check found. The check runs again after, so the warning goes.
  property bool movingCopies: false
  Process {
    id: moveCopiesProc
    command: ["bash", root.doctorPath, "--fix"]
    onExited: {
      root.movingCopies = false
      root.logEvent("doctor-fix exit=" + exitCode)
      duplicatePluginProc.running = true
    }
  }
  function moveCopies() {
    if (moveCopiesProc.running || root.shadowingDirs.length === 0) return false
    root.movingCopies = true
    moveCopiesProc.running = true
    return true
  }

  function runDoctor() {
    root.openInTerminal("bash " + root.shellQuote(root.doctorPath), "bash " + root.shellQuote(root.doctorPath))
    root.logEvent("doctor")
    return true
  }

  readonly property string checkFaceAuthPath: root.pluginDir + "/check-face-auth.sh"
  readonly property string checkFido2AuthPath: root.pluginDir + "/check-fido2-auth.sh"

  // The app launcher entry and the Omarchy menu entry (Style -> Lock Screen).
  // A plugin cannot run anything when it is installed, so they are opt-in:
  // the Settings tab's "Omarchy menu" row and `omarchy-shell lock setMenuEntry`
  // run extras/install.sh, which also takes them out again.
  readonly property string menuInstallPath: root.pluginDir + "/extras/install.sh"
  // The lock in the bar (BarWidget.qml), a custom module in the bar layout
  // of shell.json put there by extras/bar-icon.sh: the Settings tab's "Bar
  // icon" row and `omarchy-shell lock setBarIcon on`. Whether it is there is
  // read off the file, which the shell rewrites when the layout changes.
  readonly property string barIconPath: root.pluginDir + "/extras/bar-icon.sh"
  readonly property bool barIconShown: root.localSettings.barHasWidget

  function setBarIcon(v) {
    var on = v === true || v === 1 || v === "true" || v === "on" || v === "1"
    if (barIconApplyProc.running) return false
    barIconApplyProc.command = on ? ["bash", root.barIconPath] : ["bash", root.barIconPath, "--remove"]
    barIconApplyProc.running = true
    root.logEvent("bar-icon=" + (on ? "on" : "off"))
    return true
  }

  Process {
    id: barIconApplyProc
    onExited: root.localSettings.reload()
  }

  // Every embedded script that writes a file of the user's sources this first
  // (it arrives as the script's $0): an owner-checked, symlink-free directory
  // chain under $HOME and atomic replacement from inside the target directory.
  readonly property string safePathsLib: root.pluginDir + "/extras/safe-paths.sh"
  property bool menuEntryInstalled: false

  function refreshMenuEntry() {
    if (!menuEntryStatusProc.running) menuEntryStatusProc.running = true
  }

  function setMenuEntry(v) {
    var on = v === true || v === 1 || v === "true" || v === "on" || v === "1"
    if (menuEntryApplyProc.running) return false
    menuEntryApplyProc.command = on ? [root.menuInstallPath] : [root.menuInstallPath, "--remove"]
    menuEntryApplyProc.running = true
    root.logEvent("menu-entry=" + (on ? "on" : "off"))
    return true
  }

  Process {
    id: menuEntryStatusProc
    command: [root.menuInstallPath, "--status"]
    stdout: StdioCollector { id: menuEntryStatusOut; waitForEnd: true }
    onExited: root.menuEntryInstalled = String(menuEntryStatusOut.text || "").trim() === "installed"
  }

  Process {
    id: menuEntryApplyProc
    onExited: root.refreshMenuEntry()
  }
  // The layout being typed on, as a short code ("DK"), and whether that is
  // something other than a plain US keyboard. A password is typed blind, so a
  // layout switched since last time is invisible without this: the field shows
  // the code when it is not US. Read from Hyprland, which is what the session
  // is running under; anywhere else this stays empty and nothing is shown.
  property string keyboardLayout: ""
  // Caps lock, the other thing a password typed blind cannot show. The state
  // is read from Hyprland, never inferred from a key: Omarchy maps Caps Lock
  // to Compose by default (`compose:caps`), so the key that looks like it
  // toggles caps usually does not, and a lock screen that says CAPS when it
  // does not is worse than one that says nothing. Hyprland raises no event
  // for it either, so the lock screen asks while someone is typing into it,
  // at most this often.
  property bool capsLock: false
  readonly property int capsProbeInterval: 1500
  property double lastCapsProbe: 0

  function probeCapsLock() {
    var now = Date.now()
    if (now - root.lastCapsProbe < root.capsProbeInterval) return
    root.lastCapsProbe = now
    root.refreshKeyboardLayout()
  }
  readonly property bool foreignLayout: root.keyboardLayout.length > 0 && root.keyboardLayout !== "US"
  // With more than one layout configured the badge in the field switches to
  // the next one when clicked, the same as Hyprland's own layout toggle.
  property int keyboardLayoutCount: 1
  property string keyboardDevice: ""

  Process {
    id: switchLayoutProc
    command: ["hyprctl", "switchxkblayout", root.keyboardDevice.length > 0 ? root.keyboardDevice : "all", "next"]
    onExited: root.refreshKeyboardLayout()
  }

  function switchKeyboardLayout() {
    if (root.keyboardLayoutCount < 2 || switchLayoutProc.running) return false
    switchLayoutProc.running = true
    root.logEvent("layout-switch")
    return true
  }

  function refreshKeyboardLayout() {
    if (!keyboardLayoutProc.running) keyboardLayoutProc.running = true
  }

  function refreshBackground() {
    if (!readlinkProc.running) readlinkProc.running = true
  }

  Process {
    id: readlinkProc
    command: ["readlink", "-f", root.currentBackgroundLink]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text || "").trim()
        if (next !== root.backgroundPath) {
          root.backgroundPath = next
          root.backgroundVersion += 1
        }
      }
    }
  }

  // The background is a symlink retarget with no file content to watch, so
  // poll it the way the stock background plugin does. Keeps backgroundPath
  // live for the boot-screen background resync.
  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refreshBackground()
  }

  // A theme switch changes the colors at once and points the link at the new
  // theme's wallpaper with them: look straight away, and once more in case the
  // link moved just after, instead of showing the old wallpaper under the new
  // colors until the next poll -- or missing a theme picked within it.
  readonly property color themeColorProbe: Commons.Color.background
  Timer {
    id: themeBackgroundTimer
    interval: 150
    onTriggered: { root.refreshBackground(); themeBackgroundLateTimer.restart() }
  }
  Timer {
    id: themeBackgroundLateTimer
    interval: 900
    onTriggered: root.refreshBackground()
  }

  // The active layout of the keyboard being typed on. `layout` is the list
  // from the config ("us,dk") and `active_layout_index` picks from it, which
  // gives a short code without a table to look it up in.
  Process {
    id: keyboardLayoutProc
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector { id: keyboardLayoutStdout; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) { root.keyboardLayout = ""; return }
      var listed = []
      try {
        listed = JSON.parse(String(keyboardLayoutStdout.text || "{}")).keyboards || []
      } catch (e) {
        root.keyboardLayout = ""
        return
      }
      var kb = null
      for (var i = 0; i < listed.length; i++) {
        if (!listed[i] || !listed[i].active_keymap) continue
        if (listed[i].main === true) { kb = listed[i]; break }
        if (!kb) kb = listed[i]
      }
      if (!kb) { root.keyboardLayout = ""; return }
      var codes = String(kb.layout === undefined ? "" : kb.layout).split(",")
      var at = Number(kb.active_layout_index || 0)
      var code = codes.length > at ? codes[at] : codes[0]
      // Hyprland reports the configured layout verbatim, and a custom XKB
      // layout is a free-form name. The badge bounds what it draws; this
      // bounds what is kept.
      root.keyboardLayout = String(code || "").trim().toUpperCase().substring(0, 24)
      root.keyboardLayoutCount = codes.filter(function(c) { return String(c).trim().length > 0 }).length
      root.keyboardDevice = String(kb.name || "")
      // Older Hyprland does not report it; then it stays off rather than lying.
      root.capsLock = kb.capsLock === true
    }
  }

  // Hyprland announces a layout switch on its event socket, so the code stays
  // right when the layout is toggled with the screen already locked.
  Socket {
    id: hyprEvents
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000") + "/hypr/"
      + (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") + "/.socket2.sock"
    connected: root.locked && (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "").length > 0
    parser: SplitParser {
      onRead: function(line) {
        if (String(line).indexOf("activelayout") === 0) root.refreshKeyboardLayout()
      }
    }
  }
}
