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
  readonly property alias barIconFirstStartRetryTimer: barIconFirstStartRetryTimer
  readonly property alias localSettings: localSettings
  readonly property alias settingsRestoreTimer: settingsRestoreTimer


  property var shell: null
  property var manifest: null
  property string omarchyPath: ""

  LocalSettings { id: localSettings; pluginId: root.pluginId }
  readonly property var settingsConfig: root.shell && root.shell.shellConfig
    ? root.shell.shellConfig : localSettings.config

  // selected design lives on this plugin's entry in shell.json
  readonly property string pluginId: root.manifest && root.manifest.id ? String(root.manifest.id) : "io.github.sirjul1337.lock-explorer"

  function pluginEntry() {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++)
      if (list[i] && String(list[i].id || "") === root.pluginId) return Util.cloneJson(list[i])
    return {}
  }

  // Every setting is saved read-modify-write on this plugin's entry, and the
  // host replaces the entry with what it is handed. The write-through copy in
  // LocalSettings is what keeps two changes made back to back from clobbering
  // each other while the file watcher catches up.
  function writeEntry(entry) {
    if (entry.openAs === undefined) entry.openAs = root.openAs
    localSettings.remember(entry)
    root.saveSettingsBackup(entry)
    return root.shell.updateEntryInline(root.pluginId, entry)
  }

  // A copy of these settings outside ~/.config/omarchy/plugins/. Omarchy drops
  // a plugin's entry from shell.json when the plugin is removed, so removing
  // and adding it again -- the usual way out of a broken install -- started
  // over from every default. Every write is mirrored here, and at startup an
  // entry with no settings left takes them back from the copy. The copy always
  // matches the last write, so settings put back to their defaults stay that
  // way; deleting the file is how to really start over.
  readonly property string settingsBackupPath: root.home + "/.config/omarchy/lock-explorer.json"
  // Keys Omarchy keeps on the entry for itself.
  readonly property var hostEntryKeys: ["id", "enabled"]
  property bool settingsRestoreChecked: false
  // The copy is a few hundred bytes of settings; anything bigger is not it.
  readonly property int settingsCopyMaxBytes: 65536

  // Writes only. The file is the user's to edit or replace with anything, and
  // a FileView loads whatever sits at its path: a FIFO would stall the shell
  // and an oversized file would sit in its memory. Reads go through
  // settingsCopyRead, which checks the file before handing it over.
  FileView {
    id: settingsBackup
    path: root.settingsBackupPath
    preload: false
    atomicWrites: true
    printErrors: false
  }

  function settingKeys(entry) {
    return Object.keys(entry || {}).filter(function(k) { return root.hostEntryKeys.indexOf(k) === -1 })
  }

  function saveSettingsBackup(entry) {
    var copy = {}
    root.settingKeys(entry).forEach(function(k) { copy[k] = entry[k] })
    settingsBackup.setText(JSON.stringify(copy, null, 2) + "\n")
  }

  // Exit 0 with the file on stdout, 1 when there is nothing at the path,
  // 2 when what is there is not a plain file (a symlink or FIFO included),
  // 3 when it is over the cap. The cap bounds the read as well as the
  // check, so a file growing in between still cannot get past it.
  Process {
    id: settingsCopyRead
    command: ["bash", "-c",
      "f=$1; max=$2; " +
      "[ -e \"$f\" ] || [ -L \"$f\" ] || exit 1; " +
      "[ -f \"$f\" ] && [ ! -L \"$f\" ] || exit 2; " +
      "[ \"$(stat -c %s -- \"$f\")\" -le \"$max\" ] || exit 3; " +
      "head -c \"$max\" -- \"$f\"",
      "bash", root.settingsBackupPath, String(root.settingsCopyMaxBytes)]
    stdout: StdioCollector { id: settingsCopyOut; waitForEnd: true }
    onExited: function(exitCode) { root.applySettingsCopy(exitCode, String(settingsCopyOut.text || "")) }
  }

  function restoreSettings() {
    if (root.settingsRestoreChecked) return
    root.settingsRestoreChecked = true
    if (!root.shell || typeof root.shell.updateEntryInline !== "function") return
    var current = root.pluginEntry()
    if (root.settingKeys(current).length > 0) {
      // The entry is the settings; the copy only has to match it. Writing it
      // here, without reading it first, is also what gives an install from
      // before the copy existed one.
      root.saveSettingsBackup(current)
      return
    }
    settingsCopyRead.running = true
  }

  function applySettingsCopy(exitCode, text) {
    if (exitCode === 1) return
    if (exitCode !== 0) {
      root.logEvent("settings-copy-skipped: " + (exitCode === 2 ? "not a plain file" : "over " + root.settingsCopyMaxBytes + " bytes"))
      return
    }
    var saved = null
    try { saved = JSON.parse(text) } catch (e) { saved = null }
    if (!saved || typeof saved !== "object" || Array.isArray(saved)) return
    var keys = root.settingKeys(saved)
    if (keys.length === 0) return
    // A setting saved while the copy was being read is newer than the copy.
    var current = root.pluginEntry()
    if (root.settingKeys(current).length > 0) return
    keys.forEach(function(k) { current[k] = saved[k] })
    root.writeEntry(current)
    root.logEvent("settings-restored " + keys.join(","))
  }

  // Once the entry has been read and the host has settled after a reload.
  Timer {
    id: settingsRestoreTimer
    interval: 2000
    onTriggered: root.restoreSettings()
  }

  function addBarIconOnceOnFirstStart() {
    if (root.pluginEntry().barIconDefaulted === true) return
    if (!root.shell || typeof root.shell.updateEntryInline !== "function") return
    if (root.barIconApplyProc.running) { barIconFirstStartRetryTimer.restart(); return }
    if (localSettings.barHasWidget) {
      var current = root.pluginEntry()
      current.barIconDefaulted = true
      root.writeEntry(current)
      root.logEvent("bar-icon-defaulted")
      return
    }
    if (barIconFirstStartRetryTimer.attempts++ < 5) {
      root.setBarIcon(true)
      barIconFirstStartRetryTimer.restart()
    }
  }

  Timer {
    id: barIconFirstStartRetryTimer
    property int attempts: 0
    interval: 3000
    onTriggered: root.addBarIconOnceOnFirstStart()
  }

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: root.home + "/.local/state"
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
  readonly property string currentBackgroundLink: root.stateHome + "/omarchy/current/background"
}
