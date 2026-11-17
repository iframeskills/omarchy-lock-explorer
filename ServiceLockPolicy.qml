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


  // "all" or an output name (see `omarchy-shell lock monitors`). Other
  // monitors get the companion screen.
  property string inputMonitorOverride: ""
  readonly property string configuredInputMonitor: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.inputMonitor) return String(entry.inputMonitor)
    }
    return "all"
  }
  readonly property string inputMonitor: root.inputMonitorOverride.length > 0 ? inputMonitorOverride : root.configuredInputMonitor

  // How the lock screen leaves the screen when the password checks out. Off by
  // default, the unlock stays instant until it is turned on. Saved on the
  // plugin entry as `unlock` and `unlockMs`.
  readonly property var unlockAnimations: ["fade", "zoom", "rise", "none"]
  readonly property int defaultUnlockDuration: 400
  property string unlockOverride: ""
  property int unlockDurationOverride: -1
  readonly property string configuredUnlock: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.unlock) return String(entry.unlock)
    }
    return "none"
  }
  readonly property int configuredUnlockDuration: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.unlockMs !== undefined)
        return Math.max(0, Math.min(2000, Number(entry.unlockMs) || 0))
    }
    return root.defaultUnlockDuration
  }
  readonly property string unlockAnimation: {
    var value = root.unlockOverride.length > 0 ? unlockOverride : root.configuredUnlock
    return root.unlockAnimations.indexOf(value) === -1 ? "none" : value
  }
  readonly property int unlockDuration: root.unlockDurationOverride >= 0 ? unlockDurationOverride : root.configuredUnlockDuration
  readonly property bool unlockAnimated: root.unlockAnimation !== "none" && root.unlockDuration > 0

  // How long the unlock screen stays lit before the display is blanked. The
  // session is locked before every suspend, so on a machine that sleeps this
  // delay is what the user sees on resume: too short and the screen goes dark
  // before there is time to type. Saved on the plugin entry as `blankMs`.
  readonly property int defaultBlankDelay: 5000
  property int blankDelayOverride: -1
  readonly property int configuredBlankDelay: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.blankMs !== undefined)
        return Math.max(1000, Math.min(3600000, Number(entry.blankMs) || root.defaultBlankDelay))
    }
    return root.defaultBlankDelay
  }
  readonly property int blankDelay: root.blankDelayOverride >= 0 ? blankDelayOverride : root.configuredBlankDelay

  // How long after the wake has run the password field stays inert, so the
  // keys that lit a dark panel do not land in the password. Nothing reports a
  // panel as physically lit, so this is the allowance for one to come up; 0
  // drops only the keys pressed before the wake ran. Saved on the plugin entry
  // as `wakeGraceMs`.
  readonly property int defaultWakeGrace: 1000
  readonly property int maxWakeGrace: 5000
  property int wakeGraceOverride: -1
  readonly property int configuredWakeGrace: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.wakeGraceMs !== undefined)
        return Math.max(0, Math.min(root.maxWakeGrace, Number(entry.wakeGraceMs) || 0))
    }
    return root.defaultWakeGrace
  }
  readonly property int wakeInputGrace: root.wakeGraceOverride >= 0 ? wakeGraceOverride : root.configuredWakeGrace

  // When face unlock starts scanning on its own. "wake" (the default) scans
  // when a blanked or sleeping panel comes back -- a lid opened, a key
  // pressed -- but not when the screen is locked while you are sitting in
  // front of it, which would recognise you and unlock again. "always" scans
  // as soon as the session locks, "off" leaves it to Enter on an empty field
  // or the face button. Saved on the plugin entry as `faceStart`.
  readonly property string defaultFaceStart: "wake"
  readonly property var faceStartOptions: ["always", "wake", "off"]
  property string faceStartOverride: ""
  readonly property string configuredFaceStart: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.faceStart !== undefined) {
        var value = String(entry.faceStart)
        if (root.faceStartOptions.indexOf(value) !== -1) return value
      }
    }
    return root.defaultFaceStart
  }
  readonly property string faceStart: root.faceStartOverride.length > 0 ? faceStartOverride : root.configuredFaceStart
  // "wake" needs a moment that says somebody came back. A panel powering on
  // is the clear one, but a screen that never blanks (the keep-lit option, or
  // hardware the display-power helper cannot drive) has none -- so an
  // interaction a while after the lock counts too. The delay keeps the lock
  // you just asked for from scanning the face still sitting in front of it.
  readonly property int faceWakeQuiet: 15000
  readonly property int faceRoundGap: 10000
  property real lockedAt: 0
  property real lastFaceRound: 0

  // Sleep, restart and shut down from the lock screen. Off by default: a
  // locked machine anyone can reboot is a different trade than a locked
  // machine that only takes a password, and that is the owner's call. Saved
  // on the plugin entry as `powerActions`.
  property int powerActionsOverride: -1
  readonly property bool configuredPowerActions: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId) return entry.powerActions === true
    }
    return false
  }
  readonly property bool powerActions: root.powerActionsOverride >= 0 ? root.powerActionsOverride === 1 : root.configuredPowerActions

  // Omarchy's own commands, so a lock screen reboot is the reboot the menu
  // does. Nothing here runs without the setting on and a second click.
  function runPowerAction(action) {
    if (!root.powerActions) return false
    if (action === "suspend") Quickshell.execDetached(["systemctl", "suspend"])
    else if (action === "reboot") Quickshell.execDetached(["omarchy-system-reboot"])
    else if (action === "shutdown") Quickshell.execDetached(["omarchy-system-shutdown"])
    else return false
    root.logEvent("power-action=" + action)
    return true
  }

  // When true the display stays powered while locked: the DPMS-off is skipped
  // entirely, so video designs keep playing and slow monitors are never
  // re-blanked. Takes precedence over blankDelay. Lives on the plugin entry
  // in shell.json.
  property int keepDisplayOnOverride: -1
  readonly property bool configuredKeepDisplayOn: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId) return entry.keepDisplayOn === true
    }
    return false
  }
  readonly property bool keepDisplayOn: root.keepDisplayOnOverride >= 0 ? root.keepDisplayOnOverride === 1 : root.configuredKeepDisplayOn

  // Some monitors drop off the bus when DPMS turns them off (a lone DisplayPort
  // panel on NVIDIA, issue #34). With no output left while the session lock is
  // held the shell dies, relaunches, recovers the stranded lock and blanks
  // again -- a loop for as long as the session stays locked. The blank leaves
  // a marker in the runtime dir that the wake removes, so a shell that starts
  // up and finds it knows its predecessor died with the display off, and
  // keeps the displays lit for the rest of this login instead.
  // Never /tmp: a shared directory where another account could plant a link.
  readonly property string blankMarkerDir: (Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("HOME") + "/.cache")) + "/omarchy-lock-explorer"
  property bool blankCrashed: false

  // Opt-in HDMI workaround; Never still applies independently on every setup.
  readonly property bool displayBlankingSuppressed: root.keepDisplayOn || root.blankCrashed || DisplayPower.keepDisplaysOn(
    root.settingsConfig, root.pluginId, Quickshell.screens)

  // Both off by default. Pulling the security key out locks the session, and
  // plugging it in lights a blanked lock screen ready for a touch. Saved on
  // the plugin entry as `lockOnKeyRemoval` and `wakeOnKeyInsert`, only when on.
  property int lockOnKeyRemovalOverride: -1
  readonly property bool configuredLockOnKeyRemoval: root.pluginFlag("lockOnKeyRemoval")
  readonly property bool lockOnKeyRemoval: root.lockOnKeyRemovalOverride >= 0 ? root.lockOnKeyRemovalOverride === 1 : root.configuredLockOnKeyRemoval
  property int wakeOnKeyInsertOverride: -1
  readonly property bool configuredWakeOnKeyInsert: root.pluginFlag("wakeOnKeyInsert")
  readonly property bool wakeOnKeyInsert: root.wakeOnKeyInsertOverride >= 0 ? root.wakeOnKeyInsertOverride === 1 : root.configuredWakeOnKeyInsert

  function pluginFlag(name) {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId) return entry[name] === true
    }
    return false
  }

  function setPluginFlag(name, value) {
    var on = value === true || value === "true" || value === 1 || value === "1" || value === "on"
    var off = value === false || value === "false" || value === 0 || value === "0" || value === "off"
    if (!on && !off) return false
    if (name === "lockOnKeyRemoval") root.lockOnKeyRemovalOverride = on ? 1 : 0
    else if (name === "wakeOnKeyInsert") root.wakeOnKeyInsertOverride = on ? 1 : 0
    else return false
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) current[name] = true
      else delete current[name]
      root.writeEntry(current)
    }
    root.logEvent(name + "=" + (on ? "on" : "off"))
    return true
  }

  function setLockOnKeyRemoval(value) { return root.setPluginFlag("lockOnKeyRemoval", value) }
  function setWakeOnKeyInsert(value) { return root.setPluginFlag("wakeOnKeyInsert", value) }

  // Security-key unlock, on whenever a key is set up. Saved on the plugin
  // entry as `fido2Off` only when it is turned off, so a setup that never
  // touches this keeps the entry it always had.
  property int fido2EnabledOverride: -1
  readonly property bool configuredFido2Enabled: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.fido2Off !== undefined)
        return !(entry.fido2Off === true || String(entry.fido2Off) === "true")
    }
    return true
  }
  readonly property bool fido2Enabled: root.fido2EnabledOverride >= 0 ? root.fido2EnabledOverride === 1 : root.configuredFido2Enabled

  function setFido2Enabled(v) {
    var on = v === true || v === 1 || v === "true" || v === "on"
    root.fido2EnabledOverride = on ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) delete current.fido2Off
      else current.fido2Off = true
      root.writeEntry(current)
    }
    // Turning it off mid-lock hands the screen back to the password.
    if (!on && root.fido2Active) root.setAuthMode("password")
    root.logEvent("fido2=" + (on ? "on" : "off"))
    return true
  }

  readonly property string backgroundUrl: {
    if (root.backgroundPath.length === 0) return ""
    var encoded = String(root.backgroundPath).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + root.backgroundVersion
  }

  function showsInput(screen) {
    if (root.inputMonitor === "all" || !screen) return true
    var names = []
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) if (screens[i] && screens[i].name) names.push(screens[i].name)
    if (names.indexOf(root.inputMonitor) === -1) return true
    return screen.name === root.inputMonitor
  }

  function setInputMonitor(name) {
    var value = String(name || "all")
    root.inputMonitorOverride = value
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (value === "all") delete current.inputMonitor
      else current.inputMonitor = value
      root.writeEntry(current)
    }
    root.logEvent("input-monitor=" + value)
    return true
  }

  function setUnlockAnimation(name) {
    var value = String(name || "").trim().toLowerCase()
    if (root.unlockAnimations.indexOf(value) === -1) return false

    root.unlockOverride = value
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (value === "none") delete current.unlock
      else current.unlock = value
      root.writeEntry(current)
    }
    root.logEvent("unlock=" + value)
    return true
  }

  function setUnlockDuration(ms) {
    var text = String(ms === undefined ? "" : ms).trim()
    var value = Math.round(Number(text))
    if (text.length === 0 || !isFinite(value) || value < 0 || value > 2000) return false

    root.unlockDurationOverride = value
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (value === root.defaultUnlockDuration) delete current.unlockMs
      else current.unlockMs = value
      root.writeEntry(current)
    }
    root.logEvent("unlock-ms=" + value)
    return true
  }

  function setPowerActions(value) {
    var on = value === true || value === "true" || value === 1 || value === "1" || value === "on"
    var off = value === false || value === "false" || value === 0 || value === "0" || value === "off"
    if (!on && !off) return false

    root.powerActionsOverride = on ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) current.powerActions = true
      else delete current.powerActions
      root.writeEntry(current)
    }
    root.logEvent("power-actions=" + (on ? "on" : "off"))
    return true
  }

  function setFaceStart(value) {
    var text = String(value === undefined ? "" : value).trim().toLowerCase()
    if (root.faceStartOptions.indexOf(text) === -1) return false

    root.faceStartOverride = text
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (text === root.defaultFaceStart) delete current.faceStart
      else current.faceStart = text
      root.writeEntry(current)
    }
    root.logEvent("face-start=" + text)
    if (text === "off") root.stopFace()
    return true
  }

  function setWakeGrace(ms) {
    var text = String(ms === undefined ? "" : ms).trim()
    var value = Math.round(Number(text))
    if (text.length === 0 || !isFinite(value) || value < 0 || value > root.maxWakeGrace) return false

    root.wakeGraceOverride = value
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (value === root.defaultWakeGrace) delete current.wakeGraceMs
      else current.wakeGraceMs = value
      root.writeEntry(current)
    }
    root.logEvent("wake-grace=" + value)
    return true
  }

  function setBlankDelay(ms) {
    var text = String(ms === undefined ? "" : ms).trim()
    var value = Math.round(Number(text))
    if (text.length === 0 || !isFinite(value) || value < 1000 || value > 3600000) return false

    root.blankDelayOverride = value
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (value === root.defaultBlankDelay) delete current.blankMs
      else current.blankMs = value
      root.writeEntry(current)
    }
    root.logEvent("blank-ms=" + value)
    return true
  }

  function setKeepDisplayOn(on) {
    var value = on === true || on === "true" || on === 1 || on === "1" || on === "on"
    var off = on === false || on === "false" || on === 0 || on === "0" || on === "off"
    if (!value && !off) return false
    root.keepDisplayOnOverride = value ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (!value) delete current.keepDisplayOn
      else current.keepDisplayOn = true
      root.writeEntry(current)
    }
    root.logEvent("keep-display-on=" + value)
    return true
  }
}
