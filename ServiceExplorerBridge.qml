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


  // ------------------------------------------------- explorer facade
  // What the explorer, editor and designer get to see of this service on
  // Omarchy 4.0.3+, where the host keeps authentication services private
  // and hands the overlay `service = null` (issue #16). Published through
  // Bridge.js; it has no QObject parent and no reference back to this
  // object, so nothing here leads to the PAM contexts or the typed
  // password. extras/test-service-api.py keeps it in step with the UI.
  property var explorerApi: null

  Component {
    id: explorerApiComponent
    QtObject {
      readonly property string designId: root.designId
      readonly property string safePathsLib: root.safePathsLib
      readonly property int designsRevision: root.designsRevision
      readonly property var userDesigns: root.userDesigns
      readonly property string backgroundPath: root.backgroundPath
      readonly property int backgroundVersion: root.backgroundVersion
      readonly property string avatarPath: root.avatarPath
      readonly property int avatarVersion: root.avatarVersion
      readonly property string avatarUrl: root.avatarUrl
      readonly property string videoPath: root.videoPath
      readonly property string stingPath: root.stingPath
      readonly property int stingVolume: root.stingVolume
      readonly property real clipSpeed: root.clipSpeed
      readonly property bool clipWallpaper: root.clipWallpaper
      readonly property bool twelveHour: root.twelveHour
      readonly property string inputMonitor: root.inputMonitor
      readonly property string unlockAnimation: root.unlockAnimation
      readonly property int unlockDuration: root.unlockDuration
      readonly property var unlockAnimations: root.unlockAnimations
      readonly property int defaultUnlockDuration: root.defaultUnlockDuration
      readonly property int blankDelay: root.blankDelay
      readonly property int defaultBlankDelay: root.defaultBlankDelay
      readonly property int wakeGrace: root.wakeInputGrace
      readonly property int defaultWakeGrace: root.defaultWakeGrace
      readonly property bool powerActions: root.powerActions
      readonly property bool mediaControls: root.mediaControls
      readonly property bool followTheme: root.followTheme
      readonly property var themeDesigns: root.themeDesigns
      readonly property string rotateDesigns: root.rotateDesigns
      readonly property string ownerMessage: root.ownerMessage
      readonly property int ownerMessageMaxLength: root.ownerMessageMaxLength
      readonly property bool awayReport: root.awayReport
      readonly property string openAs: root.openAs
      readonly property bool barIconShown: root.barIconShown
      readonly property bool tourSeen: root.tourSeen
      readonly property bool lockOnKeyRemoval: root.lockOnKeyRemoval
      readonly property bool wakeOnKeyInsert: root.wakeOnKeyInsert
      readonly property var favorites: root.favorites
      readonly property bool showLayoutBadge: root.showLayoutBadge
      readonly property string accountName: root.accountName
      readonly property bool showCapsBadge: root.showCapsBadge
      readonly property bool allowPasswordToggle: root.allowPasswordToggle
      readonly property bool showAuthIcons: root.showAuthIcons
      readonly property var shadowingDirs: root.shadowingDirs
      readonly property var rivalLockPlugins: root.rivalLockPlugins
      readonly property string doctorPath: root.doctorPath
      readonly property string wallpaperBlur: root.wallpaperBlur
      readonly property string wallpaperDim: root.wallpaperDim
      readonly property real wallpaperBlurValue: root.wallpaperBlurValue
      readonly property real wallpaperDimShift: root.wallpaperDimShift
      readonly property string reduceMotion: root.reduceMotion
      readonly property bool motionReduced: root.motionReduced
      readonly property real uiScale: root.uiScale
      readonly property var languages: root.languages
      readonly property string language: root.language
      readonly property string languageSetting: root.languageSetting
      readonly property string systemLanguage: root.systemLanguage
      readonly property bool keepDisplayOn: root.keepDisplayOn
      readonly property bool displayBlankingSuppressed: root.displayBlankingSuppressed
      readonly property bool fingerprintConfigured: root.fingerprintConfigured
      readonly property bool faceConfigured: root.faceConfigured
      readonly property string faceStart: root.faceStart
      readonly property bool fido2Configured: root.fido2Configured
      readonly property bool fido2Installed: root.fido2Installed
      readonly property bool fido2Enabled: root.fido2Enabled
      readonly property bool multimediaAvailable: root.multimediaAvailable
      readonly property bool menuEntryInstalled: root.menuEntryInstalled
      readonly property var components: root.components
      readonly property bool locked: root.locked
      readonly property bool previewVisible: root.previewVisible
      readonly property bool stingPlaying: root.stingPlaying
      readonly property string bootSetting: root.bootSetting
      readonly property bool bootApplying: root.bootApplying
      readonly property string bootApplied: root.bootApplied
      readonly property int bootAppliedVersion: root.bootAppliedVersion
      readonly property string bootAppliedTheme: root.bootAppliedTheme
      readonly property string bootCurrentTheme: root.bootCurrentTheme
      readonly property bool bootResync: root.bootResync
      readonly property int bootPreviewsVersion: root.bootPreviewsVersion
      readonly property bool bootPreviewsRunning: root.bootPreviewsRunning
      readonly property bool bootPreviewsPending: root.bootPreviewsPending
      readonly property var bootVideos: root.bootVideos
      readonly property var bootCustomDesigns: root.bootCustomDesigns
      readonly property int bootClipSeconds: root.bootClipSeconds
      readonly property var bootRotation: root.bootRotation

      signal designCustomized(string id, string path)
      signal designerDesignCreated(string id, string path)
      signal imagePicked(string path)
      signal clipDesignAdded(string id)
      signal bootResnapshotRequested(string designId, bool persist)
      signal exploreTabRequested(string tab)
      signal exploreViewRequested(string view)
      signal bootDesignLoaded(string name, string content)

      function setDesign(id, how) { return root.setDesign(id, how) }
      function customizeDesign(id) { return root.customizeDesign(id) }
      function createDesignerDesign(content) { return root.createDesignerDesign(content) }
      function deleteDesign(id) { return root.deleteDesign(id) }
      function rescanUserDesigns() { return root.rescanUserDesigns() }
      function reloadDesigns() { return root.reloadDesigns() }
      function rescanComponents() { return root.rescanComponents() }
      function saveComponent(slug, json) { return root.saveComponent(slug, json) }
      function deleteComponent(slug) { return root.deleteComponent(slug) }
      function pickAvatar(reopenExplorer) { return root.pickAvatar(reopenExplorer) }
      function setAvatar(path) { return root.setAvatar(path) }
      function clearAvatar() { return root.clearAvatar() }
      function resetAvatar() { return root.resetAvatar() }
      function pickImage(reopenExplorer) { return root.pickImage(reopenExplorer) }
      function pickVideo(reopenExplorer, target) { return root.pickVideo(reopenExplorer, target) }
      function setVideo(path) { return root.setVideo(path) }
      function clearVideo() { return root.clearVideo() }
      function setSting(path) { return root.setSting(path) }
      function clearSting() { return root.clearSting() }
      function setStingVolume(value) { return root.setStingVolume(value) }
      function playSting() { return root.playSting() }
      function endSting() { return root.endSting() }
      function createClipDesign(path) { return root.createClipDesign(path) }
      function setClipSpeed(v) { return root.setClipSpeed(v) }
      function setClipWallpaper(on) { return root.setClipWallpaper(on) }
      function setTwelveHour(v) { return root.setTwelveHour(v) }
      function setInputMonitor(name) { return root.setInputMonitor(name) }
      function setUnlockAnimation(name) { return root.setUnlockAnimation(name) }
      function setUnlockDuration(ms) { return root.setUnlockDuration(ms) }
      function setBlankDelay(ms) { return root.setBlankDelay(ms) }
      function setWakeGrace(ms) { return root.setWakeGrace(ms) }
      function setFaceStart(value) { return root.setFaceStart(value) }
      function setPowerActions(value) { return root.setPowerActions(value) }
      function setMediaControls(value) { return root.setMediaControls(value) }
      function setFollowTheme(value) { return root.setFollowTheme(value) }
      function setRotateDesigns(value) { return root.setRotateDesigns(value) }
      function setOwnerMessage(value) { return root.setOwnerMessage(value) }
      function setAwayReport(value) { return root.setAwayReport(value) }
      function setOpenAs(value) { return root.setOpenAs(value) }
      function setBarIcon(value) { return root.setBarIcon(value) }
      function setTourSeen(value) { return root.setTourSeen(value) }
      function setLockOnKeyRemoval(value) { return root.setLockOnKeyRemoval(value) }
      function setWakeOnKeyInsert(value) { return root.setWakeOnKeyInsert(value) }
      function toggleFavorite(id) { return root.toggleFavorite(id) }
      function setFieldItem(name, show) { return root.setFieldItem(name, show) }
      function installPackages(names) { return root.installPackages(names) }
      function runDoctor() { return root.runDoctor() }
      function moveCopies() { return root.moveCopies() }
      readonly property bool movingCopies: root.movingCopies
      function setWallpaperBlur(value) { return root.setWallpaperBlur(value) }
      function setWallpaperDim(value) { return root.setWallpaperDim(value) }
      function setReduceMotion(value) { return root.setReduceMotion(value) }
      function setUiScale(value) { return root.setUiScale(value) }
      function setLanguage(value) { return root.setLanguage(value) }
      function runPowerAction(action) { return root.runPowerAction(action) }
      function setKeepDisplayOn(on) { return root.setKeepDisplayOn(on) }
      function refreshBackground() { return root.refreshBackground() }
      function refreshFingerprintStatus() { return root.refreshFingerprintStatus() }
      function refreshFaceStatus() { return root.refreshFaceStatus() }
      function refreshFido2Status() { return root.refreshFido2Status() }
      function setFido2Enabled(v) { return root.setFido2Enabled(v) }
      function refreshMenuEntry() { return root.refreshMenuEntry() }
      function setMenuEntry(v) { return root.setMenuEntry(v) }
      function logEvent(event) { return root.logEvent(event) }
      function setBoot(value) { return root.setBoot(value) }
      function applyBoot(force, explicitTarget) { return root.applyBoot(force, explicitTarget) }
      function applyBootSnapshot(id, persist, entryRect) { return root.applyBootSnapshot(id, persist, entryRect) }
      function setBootResync(on) { return root.setBootResync(on) }
      function refreshBootPreviews() { return root.refreshBootPreviews() }
      function setBootClipSeconds(n) { return root.setBootClipSeconds(n) }
      function loadBootDesign(name) { return root.loadBootDesign(name) }
      function saveBootDesign(name, content) { return root.saveBootDesign(name, content) }
      function createBootDesign() { return root.createBootDesign() }
      function deleteBootItem(id) { return root.deleteBootItem(id) }
      function toggleBootRotation(id) { return root.toggleBootRotation(id) }
      function enableBootRotation() { return root.enableBootRotation() }
      function removeBootRotationHelper() { return root.removeBootRotationHelper() }
    }
  }

  function publishExplorerApi() {
    if (root.explorerApi) return
    var api = explorerApiComponent.createObject(null)
    if (!api) return
    root.designCustomized.connect(api.designCustomized)
    root.designerDesignCreated.connect(api.designerDesignCreated)
    root.imagePicked.connect(api.imagePicked)
    root.clipDesignAdded.connect(api.clipDesignAdded)
    root.bootResnapshotRequested.connect(api.bootResnapshotRequested)
    root.exploreTabRequested.connect(api.exploreTabRequested)
    root.exploreViewRequested.connect(api.exploreViewRequested)
    root.bootDesignLoaded.connect(api.bootDesignLoaded)
    root.explorerApi = api
    Bridge.publish(api)
  }

  function retireExplorerApi() {
    if (!root.explorerApi) return
    var api = root.explorerApi
    root.explorerApi = null
    Bridge.unpublish(api)
    api.destroy()
  }

  // Opened from the app launcher, the shell's app library shows a
  // "Launching …" OSD 2s after the launch unless a new toplevel window appears
  // by then. The explorer is layer-shell, so none does, and the OSD would
  // otherwise stay up until the launcher's 15s timeout. The explorer's own
  // close on open runs before the OSD exists, so watch for it for a few
  // seconds after `explore` and close it 2s after it shows, long enough to
  // read.
  function watchLaunchOsd() {
    launchOsdWatch.ticks = 0
    launchOsdWatch.restart()
  }

  Timer {
    id: launchOsdWatch
    property int ticks: 0
    interval: 150
    repeat: true
    onTriggered: {
      // About 3.5s: the app library's 2s delay plus a slow summon.
      if (++ticks > 24) { stop(); return }
      if (!launchOsdStateProc.running) launchOsdStateProc.running = true
    }
  }

  Process {
    id: launchOsdStateProc
    command: ["omarchy-shell", "osd", "state"]
    stdout: StdioCollector { id: launchOsdStateOut; waitForEnd: true }
    onExited: function(code) {
      if (String(launchOsdStateOut.text || "").trim() !== "open") return
      launchOsdWatch.stop()
      launchOsdClose.restart()
    }
  }

  Timer {
    id: launchOsdClose
    interval: 2000
    onTriggered: Quickshell.execDetached(["omarchy-shell", "osd", "close"])
  }

  function summonExplorer(view) {
    root.rescanUserDesigns()
    root.watchLaunchOsd()
    root.exploreViewRequested(view)
    if (root.shell && typeof root.shell.summon === "function")
      return root.shell.summon(root.pluginId, "{}") ? "ok" : "failed"
    return "no-shell"
  }
}
