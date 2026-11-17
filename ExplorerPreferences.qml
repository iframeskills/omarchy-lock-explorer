import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "designs"
import "Designs.js" as Designs
import "Designer.js" as Layout
import "Bridge.js" as Bridge
import "ExplorerStrings.js" as UiText

Item {
  required property var root
  // Things that stop part of the plugin working here, each with the way out.
  // Shown at the top of Settings, and only when there is something to say.
  readonly property bool multimediaMissing: !!root.service && root.service.multimediaAvailable === false
  readonly property var healthIssues: {
    var list = []
    if (root.multimediaMissing)
      list.push({ text: root.tr("Video designs, clip designs and the unlock clip need qt6-multimedia, which Omarchy does not install."),
                  packages: ["qt6-multimedia"] })
    if (root.wallpaperBroken && root.wallpaperIsWebp)
      list.push({ text: root.tr("Your wallpaper is WebP, which the shell can only read with qt6-imageformats."),
                  packages: ["qt6-imageformats"] })
    var dirs = root.service && root.service.shadowingDirs ? root.service.shadowingDirs : []
    if (dirs.length > 0)
      list.push({ text: root.tr("Another copy of this plugin may load instead of this one: %1. Move it out of ~/.config/omarchy/plugins/ (to ~/.local/share/omarchy/lock-explorer-backups) and restart the shell.").arg(dirs.join(", ")),
                  packages: [], fix: "copies" })
    var rivals = root.service && root.service.rivalLockPlugins ? root.service.rivalLockPlugins : []
    if (rivals.length > 0)
      list.push({ text: root.tr("Another lock screen plugin is enabled too: %1. Only one of them gets omarchy-shell lock. Keep one: omarchy plugin disable %2 && omarchy restart shell").arg(rivals.join(", ")).arg(rivals[0]),
                  packages: [] })
    return list
  }

  function installPackages(names) {
    if (!root.service || typeof root.service.installPackages !== "function") return
    root.dismiss()
    root.service.installPackages(names)
  }

  readonly property bool movingCopies: !!root.service && root.service.movingCopies === true
  function moveCopies() {
    if (!root.service || typeof root.service.moveCopies !== "function" || root.movingCopies) return
    root.service.moveCopies()
  }

  function runDoctor() {
    if (!root.service || typeof root.service.runDoctor !== "function") return
    root.dismiss()
    root.service.runDoctor()
  }

  // Quick setting for the unlock animation, the same one `omarchy-shell lock
  // setUnlockAnimation` writes. Off by default.
  readonly property var unlockOptions: [
    { id: "none", name: "Off", hint: "The lock screen disappears at once" },
    { id: "fade", name: "Fade", hint: "It fades into the wallpaper" },
    { id: "zoom", name: "Zoom", hint: "It fades and pushes in a little" },
    { id: "rise", name: "Rise", hint: "It fades upwards off the screen" }
  ]
  readonly property var unlockDurations: [200, 300, 400, 600, 800]
  readonly property string unlockAnimation: root.service ? root.service.unlockAnimation : "none"
  readonly property int unlockDuration: root.service ? root.service.unlockDuration : 400
  readonly property bool keepDisplayOn: root.service ? root.service.keepDisplayOn : false
  readonly property int blankDelay: root.service ? root.service.blankDelay : 5000
  readonly property var blankPresets: [5000, 15000, 30000, 60000, 300000]
  readonly property int wakeGrace: root.service && root.service.wakeGrace !== undefined ? root.service.wakeGrace : 1000
  readonly property bool powerActions: root.service && root.service.powerActions === true
  readonly property bool awayReport: !root.service || root.service.awayReport !== false
  readonly property bool lockOnKeyRemoval: root.service && root.service.lockOnKeyRemoval === true
  readonly property bool wakeOnKeyInsert: root.service && root.service.wakeOnKeyInsert === true
  readonly property string wallpaperBlur: root.service && root.service.wallpaperBlur !== undefined ? String(root.service.wallpaperBlur) : "design"
  readonly property string wallpaperDim: root.service && root.service.wallpaperDim !== undefined ? String(root.service.wallpaperDim) : "design"
  readonly property real wallpaperBlurValue: root.service && root.service.wallpaperBlurValue !== undefined ? root.service.wallpaperBlurValue : -1
  readonly property real wallpaperDimShift: root.service && root.service.wallpaperDimShift !== undefined ? root.service.wallpaperDimShift : 0
  readonly property string reduceMotion: root.service && root.service.reduceMotion !== undefined ? String(root.service.reduceMotion) : "off"
  readonly property bool motionReduced: !!root.service && root.service.motionReduced === true
  readonly property real uiScale: root.service && root.service.uiScale !== undefined ? root.service.uiScale : 1
  readonly property string accountName: root.service && root.service.accountName !== undefined ? String(root.service.accountName) : ""
  readonly property string lockLanguage: root.service && root.service.language !== undefined ? String(root.service.language) : "en"
  // The explorer speaks the lock screen's language (ExplorerStrings.js).
  function tr(text) { return UiText.tr(root.lockLanguage, text) }
  readonly property string languageSetting: root.service && root.service.languageSetting !== undefined ? String(root.service.languageSetting) : "auto"
  readonly property var languageChoices: {
    var list = root.service && root.service.languages ? root.service.languages : []
    var system = root.service && root.service.systemLanguage ? String(root.service.systemLanguage) : "en"
    var sysName = "English"
    for (var i = 0; i < list.length; i++) if (list[i].id === system) sysName = list[i].name
    return [{ id: "auto", name: root.tr("System (%1)").arg(sysName) }].concat(list.map(function(l) { return { id: l.id, name: l.name } }))
  }
  readonly property var reduceMotionChoices: [
    { id: "off", name: root.tr("Off") }, { id: "on", name: root.tr("On") }, { id: "battery", name: root.tr("On battery") }
  ]
  readonly property var uiScaleChoices: [
    { id: 1, name: "100%" }, { id: 1.25, name: "125%" }, { id: 1.5, name: "150%" }
  ]
  readonly property var wallpaperBlurChoices: [
    { id: "design", name: root.tr("As designed") }, { id: "sharp", name: root.tr("Sharp") },
    { id: "soft", name: root.tr("Soft") }, { id: "heavy", name: root.tr("Heavy") }
  ]
  readonly property var wallpaperDimChoices: [
    { id: "lighter", name: root.tr("Lighter") }, { id: "design", name: root.tr("As designed") }, { id: "darker", name: root.tr("Darker") }
  ]
  readonly property bool faceConfigured: root.service && root.service.faceConfigured === true
  readonly property string faceStart: root.service && root.service.faceStart !== undefined ? String(root.service.faceStart) : "wake"
  readonly property var onOffOptions: [{ id: "on", name: root.tr("On") }, { id: "off", name: root.tr("Off") }]
  readonly property var shownHiddenOptions: [{ id: "show", name: root.tr("Show") }, { id: "hide", name: root.tr("Hide") }]
  // What the password field shows beside the text (Settings > Password field).
  readonly property bool showLayoutBadge: !root.service || root.service.showLayoutBadge !== false
  readonly property bool showCapsBadge: !root.service || root.service.showCapsBadge !== false
  readonly property bool allowPasswordToggle: !root.service || root.service.allowPasswordToggle !== false
  readonly property bool showAuthIcons: !root.service || root.service.showAuthIcons !== false
  function setFieldItem(name, show) {
    if (!root.service || typeof root.service.setFieldItem !== "function") return
    root.service.setFieldItem(name, show)
  }
  property bool customDelayEditing: false
  property string customDelayText: ""
  readonly property bool blankDelayIsCustom: !root.keepDisplayOn && root.blankPresets.indexOf(root.blankDelay) === -1
  readonly property string unlockLabel: {
    for (var i = 0; i < root.unlockOptions.length; i++)
      if (root.unlockOptions[i].id === root.unlockAnimation) return root.tr(root.unlockOptions[i].name)
    return root.tr("Off")
  }

  readonly property bool clipWallpaper: root.service && root.service.clipWallpaper !== undefined ? root.service.clipWallpaper : false

  function toggleClipWallpaper() {
    if (root.service && typeof root.service.setClipWallpaper === "function") root.service.setClipWallpaper(!root.clipWallpaper)
  }

  readonly property real clipSpeed: root.service && root.service.clipSpeed !== undefined ? root.service.clipSpeed : 1
  readonly property var clipSpeeds: [0.5, 0.75, 1, 1.25, 1.5, 2]

  function setClipSpeed(v) {
    if (root.service && typeof root.service.setClipSpeed === "function") root.service.setClipSpeed(v)
  }

  readonly property bool twelveHour: root.service && root.service.twelveHour !== undefined ? root.service.twelveHour : false
  readonly property var clockFormats: [{ id: "24", name: "24h" }, { id: "12", name: "12h AM/PM" }]

  function setTwelveHour(on) {
    if (root.service && typeof root.service.setTwelveHour === "function") root.service.setTwelveHour(on)
  }

  // The launcher and Omarchy menu entries, see extras/install.sh.
  readonly property bool menuEntryInstalled: root.service && root.service.menuEntryInstalled === true
  readonly property var menuEntryOptions: [{ id: "on", name: root.tr("Added") }, { id: "off", name: root.tr("Not added") }]

  function setMenuEntry(on) {
    if (root.service && typeof root.service.setMenuEntry === "function") root.service.setMenuEntry(on)
  }

  // Security-key unlock. The row only appears once the PAM side is in place
  // (extras/setup-fido2.sh); the toggle decides whether the lock screen uses
  // it, and never touches PAM itself.
  readonly property bool fido2Installed: root.service && root.service.fido2Installed === true
  readonly property bool fido2Enabled: root.service && root.service.fido2Enabled !== undefined ? root.service.fido2Enabled : true
  readonly property var fido2Options: [{ id: "on", name: root.tr("On") }, { id: "off", name: root.tr("Off") }]

  function setFido2Enabled(on) {
    if (root.service && typeof root.service.setFido2Enabled === "function") root.service.setFido2Enabled(on)
  }

  // The overlay owns the keyboard, so the file dialog needs it out of the way.
  // The service brings the explorer back when the dialog is answered.
  function pickAvatar() {
    if (!root.service) return
    root.dismiss()
    root.service.pickAvatar(true)
  }

  function clearAvatar() {
    if (root.service) root.service.clearAvatar()
  }

  // Same story as the avatar: the dialog needs the keyboard, so step aside.
  function pickVideo(target) {
    if (!root.service) return
    root.dismiss()
    root.service.pickVideo(true, target || "video")
  }

  // Your own video as an unlock clip: pick a file, the service writes the
  // one-line ClipDesign and it appears under Animation.
  function newClipDesign() {
    root.pickVideo("clip")
  }

  function clearVideo() {
    if (root.service) root.service.clearVideo()
  }

  function clearSting() {
    if (root.service) root.service.clearSting()
  }

  function previewSting() {
    if (!root.service || !root.service.stingPath) return
    root.dismiss()
    root.service.playSting()
  }

  function setUnlock(id) {
    if (root.service) root.service.setUnlockAnimation(id)
  }

  function setUnlockDuration(ms) {
    if (root.service) root.service.setUnlockDuration(ms)
  }

  function setBlankAfter(ms) {
    if (!root.service) return
    root.customDelayEditing = false
    if (ms === 0) {
      root.service.setKeepDisplayOn(true)
      return
    }
    root.service.setKeepDisplayOn(false)
    root.service.setBlankDelay(ms)
  }

  // How long the field stays inert after a key has woken the display, so the
  // keys that lit the panel stay out of the password.
  // Sleep, restart and shut down on the lock screen. Off by default: with it
  // on, anyone at the machine can restart it without the password.
  readonly property bool mediaControls: root.service && root.service.mediaControls === true
  function setMediaControls(on) {
    if (!root.service || typeof root.service.setMediaControls !== "function") return
    root.service.setMediaControls(on)
  }

  function setPowerActions(on) {
    if (!root.service || typeof root.service.setPowerActions !== "function") return
    root.service.setPowerActions(on)
  }

  function setWallpaperBlur(id) {
    if (!root.service || typeof root.service.setWallpaperBlur !== "function") return
    root.service.setWallpaperBlur(id)
  }

  function setReduceMotion(id) {
    if (!root.service || typeof root.service.setReduceMotion !== "function") return
    root.service.setReduceMotion(id)
  }

  function setLanguage(id) {
    if (!root.service || typeof root.service.setLanguage !== "function") return
    root.service.setLanguage(id)
  }

  function setUiScale(id) {
    if (!root.service || typeof root.service.setUiScale !== "function") return
    root.service.setUiScale(id)
  }

  function setWallpaperDim(id) {
    if (!root.service || typeof root.service.setWallpaperDim !== "function") return
    root.service.setWallpaperDim(id)
  }

  function setAwayReport(on) {
    if (!root.service || typeof root.service.setAwayReport !== "function") return
    root.service.setAwayReport(on)
  }

  function setFollowTheme(on) {
    if (!root.service || typeof root.service.setFollowTheme !== "function") return
    root.service.setFollowTheme(on)
  }

  function setRotateDesigns(id) {
    if (!root.service || typeof root.service.setRotateDesigns !== "function") return
    root.service.setRotateDesigns(id)
  }

  function setOwnerMessage(text) {
    if (!root.service || typeof root.service.setOwnerMessage !== "function") return
    root.service.setOwnerMessage(text)
  }

  function setLockOnKeyRemoval(on) {
    if (!root.service || typeof root.service.setLockOnKeyRemoval !== "function") return
    root.service.setLockOnKeyRemoval(on)
  }

  function setWakeOnKeyInsert(on) {
    if (!root.service || typeof root.service.setWakeOnKeyInsert !== "function") return
    root.service.setWakeOnKeyInsert(on)
  }

  function setWakeGrace(ms) {
    if (!root.service || typeof root.service.setWakeGrace !== "function") return
    root.service.setWakeGrace(ms)
  }

  function setFaceStart(value) {
    if (!root.service || typeof root.service.setFaceStart !== "function") return
    root.service.setFaceStart(value)
  }

  function beginCustomDelay() {
    root.customDelayText = root.keepDisplayOn ? "" : String(Math.max(1, Math.round(root.blankDelay / 60000)))
    root.customDelayEditing = true
    Qt.callLater(function() {
      root.customDelayInput.forceActiveFocus()
      root.customDelayInput.selectAll()
    })
  }

  function commitCustomDelay() {
    var minutes = Math.round(Number(root.customDelayText))
    if (!isFinite(minutes) || minutes < 1 || minutes > 60) return
    if (!root.service) return
    root.service.setKeepDisplayOn(false)
    root.service.setBlankDelay(minutes * 60000)
    root.customDelayEditing = false
    root.keyCatcher.forceActiveFocus()
  }
}
