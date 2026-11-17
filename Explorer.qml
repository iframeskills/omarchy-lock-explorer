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
  readonly property alias bootFormSaveTimer: bootFormSaveTimer
  readonly property alias revealTimer: revealTimer
  readonly property alias snapshotHost: snapshotHost
  readonly property alias snapshotMkdirProc: snapshotMkdirProc
  readonly property alias snapshotWindow: snapshotWindow
  ExplorerNavigation { id: navigation; root: root }
  ExplorerPreferences { id: preferences; root: root }
  ExplorerBootController { id: bootController; root: root }
  property alias showingKeys: navigation.showingKeys
  property alias keyCapsWidth: navigation.keyCapsWidth
  readonly property alias keySections: navigation.keySections
  readonly property alias multimediaMissing: preferences.multimediaMissing
  readonly property alias healthIssues: preferences.healthIssues
  readonly property alias movingCopies: preferences.movingCopies
  readonly property alias unlockOptions: preferences.unlockOptions
  readonly property alias unlockDurations: preferences.unlockDurations
  readonly property alias unlockAnimation: preferences.unlockAnimation
  readonly property alias unlockDuration: preferences.unlockDuration
  readonly property alias keepDisplayOn: preferences.keepDisplayOn
  readonly property alias blankDelay: preferences.blankDelay
  readonly property alias blankPresets: preferences.blankPresets
  readonly property alias wakeGrace: preferences.wakeGrace
  readonly property alias powerActions: preferences.powerActions
  readonly property alias awayReport: preferences.awayReport
  readonly property alias lockOnKeyRemoval: preferences.lockOnKeyRemoval
  readonly property alias wakeOnKeyInsert: preferences.wakeOnKeyInsert
  readonly property alias wallpaperBlur: preferences.wallpaperBlur
  readonly property alias wallpaperDim: preferences.wallpaperDim
  readonly property alias wallpaperBlurValue: preferences.wallpaperBlurValue
  readonly property alias wallpaperDimShift: preferences.wallpaperDimShift
  readonly property alias reduceMotion: preferences.reduceMotion
  readonly property alias motionReduced: preferences.motionReduced
  readonly property alias uiScale: preferences.uiScale
  readonly property alias accountName: preferences.accountName
  readonly property alias lockLanguage: preferences.lockLanguage
  readonly property alias languageSetting: preferences.languageSetting
  readonly property alias languageChoices: preferences.languageChoices
  readonly property alias reduceMotionChoices: preferences.reduceMotionChoices
  readonly property alias uiScaleChoices: preferences.uiScaleChoices
  readonly property alias wallpaperBlurChoices: preferences.wallpaperBlurChoices
  readonly property alias wallpaperDimChoices: preferences.wallpaperDimChoices
  readonly property alias faceConfigured: preferences.faceConfigured
  readonly property alias faceStart: preferences.faceStart
  readonly property alias onOffOptions: preferences.onOffOptions
  readonly property alias shownHiddenOptions: preferences.shownHiddenOptions
  readonly property alias showLayoutBadge: preferences.showLayoutBadge
  readonly property alias showCapsBadge: preferences.showCapsBadge
  readonly property alias allowPasswordToggle: preferences.allowPasswordToggle
  readonly property alias showAuthIcons: preferences.showAuthIcons
  property alias customDelayEditing: preferences.customDelayEditing
  property alias customDelayText: preferences.customDelayText
  readonly property alias blankDelayIsCustom: preferences.blankDelayIsCustom
  readonly property alias unlockLabel: preferences.unlockLabel
  readonly property alias followHint: bootController.followHint
  readonly property alias bootOptionNames: bootController.bootOptionNames
  readonly property alias bootTwins: bootController.bootTwins
  readonly property alias bootApplied: bootController.bootApplied
  readonly property alias bootAppliedTheme: bootController.bootAppliedTheme
  readonly property alias bootNowName: bootController.bootNowName
  readonly property alias bootVideos: bootController.bootVideos
  readonly property alias bootCustomDesigns: bootController.bootCustomDesigns
  readonly property alias bootClipSeconds: bootController.bootClipSeconds
  readonly property alias bootCards: bootController.bootCards
  readonly property alias bootFollowTarget: bootController.bootFollowTarget
  readonly property alias bootPreviewsVersion: bootController.bootPreviewsVersion
  readonly property alias bootCurrentTheme: bootController.bootCurrentTheme
  property alias bootEditing: bootController.bootEditing
  property alias bootEditorText: bootController.bootEditorText
  property alias bootFormMap: bootController.bootFormMap
  property alias bootFormRev: bootController.bootFormRev
  property alias bootEditBusy: bootController.bootEditBusy
  readonly property alias bootRotation: bootController.bootRotation
  readonly property alias bootRotating: bootController.bootRotating
  property alias snapshotPersist: bootController.snapshotPersist
  property alias snapshotBusy: bootController.snapshotBusy
  property alias snapshotRect: bootController.snapshotRect
  readonly property alias snapshotScreen: bootController.snapshotScreen
  readonly property alias snapshotWidth: bootController.snapshotWidth
  readonly property alias snapshotHeight: bootController.snapshotHeight
  readonly property alias snapshotScale: bootController.snapshotScale
  readonly property alias snapshotPixelWidth: bootController.snapshotPixelWidth
  readonly property alias snapshotPixelHeight: bootController.snapshotPixelHeight
  readonly property alias bootSetting: bootController.bootSetting
  readonly property alias bootApplying: bootController.bootApplying
  readonly property alias bootLabel: bootController.bootLabel
  readonly property alias bootResync: bootController.bootResync
  readonly property alias clipWallpaper: preferences.clipWallpaper
  readonly property alias clipSpeed: preferences.clipSpeed
  readonly property alias clipSpeeds: preferences.clipSpeeds
  readonly property alias twelveHour: preferences.twelveHour
  readonly property alias clockFormats: preferences.clockFormats
  readonly property alias menuEntryInstalled: preferences.menuEntryInstalled
  readonly property alias menuEntryOptions: preferences.menuEntryOptions
  readonly property alias fido2Installed: preferences.fido2Installed
  readonly property alias fido2Enabled: preferences.fido2Enabled
  readonly property alias fido2Options: preferences.fido2Options
  readonly property alias bootAppliedId: bootController.bootAppliedId
  readonly property alias bootWouldApply: bootController.bootWouldApply
  readonly property alias bootDirty: bootController.bootDirty
  readonly property alias bootDesiredName: bootController.bootDesiredName
  readonly property alias currentThemeName: bootController.currentThemeName
  readonly property alias mediaControls: preferences.mediaControls
  function nextTourStep() { return navigation.nextTourStep() }
  function endTour() { return navigation.endTour() }
  function replayTour() { return navigation.replayTour() }
  function setBarIcon(on) { return navigation.setBarIcon(on) }
  function setOpenAs(id) { return navigation.setOpenAs(id) }
  function openFull(tab) { return navigation.openFull(tab) }
  function showPanel() { return navigation.showPanel() }
  function lockNow() { return navigation.lockNow() }
  function useSelected(everywhere) { return navigation.useSelected(everywhere) }
  function sideKey(event) { return navigation.sideKey(event) }
  function installPackages(names) { return preferences.installPackages(names) }
  function moveCopies() { return preferences.moveCopies() }
  function runDoctor() { return preferences.runDoctor() }
  function tr(text) { return preferences.tr(text) }
  function setFieldItem(name, show) { return preferences.setFieldItem(name, show) }
  function refocus() { return navigation.refocus() }
  function focusSearch() { return navigation.focusSearch() }
  function leaveSearch() { return navigation.leaveSearch() }
  function bootKindLabel(d) { return bootController.bootKindLabel(d) }
  function bootCardPreview(id) { return bootController.bootCardPreview(id) }
  function openBootEditor(name) { return bootController.openBootEditor(name) }
  function bootFormGet(k, def) { return bootController.bootFormGet(k, def) }
  function bootFormSet(k, v) { return bootController.bootFormSet(k, v) }
  function bootFormParse(content) { return bootController.bootFormParse(content) }
  function bootFormSerialize() { return bootController.bootFormSerialize() }
  function saveBootForm() { return bootController.saveBootForm() }
  function closeBootEditor() { return bootController.closeBootEditor() }
  function saveBootDesignEdits() { return bootController.saveBootDesignEdits() }
  function newBootDesign() { return bootController.newBootDesign() }
  function toggleRotationMode() { return bootController.toggleRotationMode() }
  function toggleInRotation(id) { return bootController.toggleInRotation(id) }
  function inRotation(id) { return bootController.inRotation(id) }
  function snapshotActiveDesign() { return bootController.snapshotActiveDesign() }
  function snapshotAndApply(id, persist) { return bootController.snapshotAndApply(id, persist) }
  function snapshotFinish() { return bootController.snapshotFinish() }
  function bootUseStyling(id, persist) { return bootController.bootUseStyling(id, persist) }
  function toggleFollow() { return bootController.toggleFollow() }
  function setBoot(id) { return bootController.setBoot(id) }
  function toggleBootResync() { return bootController.toggleBootResync() }
  function toggleClipWallpaper() { return preferences.toggleClipWallpaper() }
  function setClipSpeed(v) { return preferences.setClipSpeed(v) }
  function setTwelveHour(on) { return preferences.setTwelveHour(on) }
  function setMenuEntry(on) { return preferences.setMenuEntry(on) }
  function setFido2Enabled(on) { return preferences.setFido2Enabled(on) }
  function applyPendingBoot() { return bootController.applyPendingBoot() }
  function positionAtSelected(mode) { return navigation.positionAtSelected(mode) }
  function reveal(mode) { return navigation.reveal(mode) }
  function setCategory(id) { return navigation.setCategory(id) }
  function move(delta) { return navigation.move(delta) }
  function moveRow(delta) { return navigation.moveRow(delta) }
  function selectById(id) { return navigation.selectById(id) }
  function pickAvatar() { return preferences.pickAvatar() }
  function clearAvatar() { return preferences.clearAvatar() }
  function pickVideo(target) { return preferences.pickVideo(target) }
  function newClipDesign() { return preferences.newClipDesign() }
  function clearVideo() { return preferences.clearVideo() }
  function clearSting() { return preferences.clearSting() }
  function previewSting() { return preferences.previewSting() }
  function setUnlock(id) { return preferences.setUnlock(id) }
  function setUnlockDuration(ms) { return preferences.setUnlockDuration(ms) }
  function setBlankAfter(ms) { return preferences.setBlankAfter(ms) }
  function setMediaControls(on) { return preferences.setMediaControls(on) }
  function setPowerActions(on) { return preferences.setPowerActions(on) }
  function setWallpaperBlur(id) { return preferences.setWallpaperBlur(id) }
  function setReduceMotion(id) { return preferences.setReduceMotion(id) }
  function setLanguage(id) { return preferences.setLanguage(id) }
  function setUiScale(id) { return preferences.setUiScale(id) }
  function setWallpaperDim(id) { return preferences.setWallpaperDim(id) }
  function setAwayReport(on) { return preferences.setAwayReport(on) }
  function setFollowTheme(on) { return preferences.setFollowTheme(on) }
  function setRotateDesigns(id) { return preferences.setRotateDesigns(id) }
  function setOwnerMessage(text) { return preferences.setOwnerMessage(text) }
  function setLockOnKeyRemoval(on) { return preferences.setLockOnKeyRemoval(on) }
  function setWakeOnKeyInsert(on) { return preferences.setWakeOnKeyInsert(on) }
  function setWakeGrace(ms) { return preferences.setWakeGrace(ms) }
  function setFaceStart(value) { return preferences.setFaceStart(value) }
  function beginCustomDelay() { return preferences.beginCustomDelay() }
  function commitCustomDelay() { return preferences.commitCustomDelay() }
  readonly property alias sidePanel: panel.sidePanel
  readonly property alias designerView: panel.designerView
  readonly property alias editorView: panel.editorView
  readonly property alias footer: panel.footer
  readonly property alias grid: panel.grid
  readonly property alias customDelayInput: panel.customDelayInput
  readonly property alias settingsColumn: panel.settingsColumn
  readonly property alias settingsFlick: panel.settingsFlick
  readonly property alias settingsPane: panel.settingsPane
  readonly property alias searchInput: panel.searchInput
  readonly property alias header: panel.header
  readonly property alias card: panel.card
  readonly property alias keyCatcher: panel.keyCatcher
  readonly property alias panel: panel
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  property var service: null
  readonly property var userDesigns: service && service.userDesigns ? service.userDesigns : []

  // Omarchy 4.0.3 hands this overlay `service = null`: the service is an
  // authentication service (a clone of omarchy.lock) and the host keeps those
  // private (issue #16). The service publishes a facade of itself through
  // Bridge.js instead; adopt it whenever the injected one is missing, and
  // again whenever the service is reloaded. Older hosts still inject the
  // service directly and nothing here gets in their way.
  function adoptService() {
    if (root.service) return
    var api = Bridge.current()
    if (api) root.service = api
  }
  onServiceChanged: if (!service) Qt.callLater(root.adoptService)
  property var bridgeUnsubscribe: null
  Component.onCompleted: {
    root.bridgeUnsubscribe = Bridge.subscribe(function() { Qt.callLater(root.adoptService) })
    root.adoptService()
  }
  Component.onDestruction: if (root.bridgeUnsubscribe) root.bridgeUnsubscribe()

  LocalSettings { id: localSettings; pluginId: root.pluginId }
  property string selectionError: ""

  property bool opened: false
  // A resync that arrived while this window was never yet shown cannot grab a
  // frame (no scene graph); it parks here and runs on the next open.
  property var pendingResnapshot: null

  // Stock Omarchy ships Qt without a WebP decoder (issue #6): designs then
  // render the theme color instead of the wallpaper. Probe the current
  // wallpaper so the header can say so instead of leaving users guessing.
  readonly property string wallpaperProbePath: root.service ? String(root.service.backgroundPath || "") : ""
  readonly property bool wallpaperIsWebp: wallpaperProbePath.toLowerCase().indexOf(".webp") !== -1
  readonly property bool wallpaperBroken: wallpaperProbe.status === Image.Error
  Image {
    id: wallpaperProbe
    visible: false
    width: 1; height: 1
    sourceSize.width: 8; sourceSize.height: 8
    asynchronous: true
    source: root.opened && root.wallpaperProbePath.length > 0
      ? "file://" + root.wallpaperProbePath.split("/").map(encodeURIComponent).join("/") : ""
  }
  // The shell's app library shows a "Launching …" OSD until a new toplevel
  // window appears. This overlay is layer-shell, so no toplevel ever comes —
  // dismiss the OSD ourselves the moment the explorer is up (15s timeout
  // otherwise).
  onOpenedChanged: {
    if (!opened) return
    thumbSlots = 0
    Quickshell.execDetached(["omarchy-shell", "osd", "close"])
    // The entries can be added or removed outside the explorer too.
    if (root.service && typeof root.service.refreshMenuEntry === "function") root.service.refreshMenuEntry()
    if (pendingResnapshot) {
      var p = pendingResnapshot
      pendingResnapshot = null
      Qt.callLater(function() { root.snapshotAndApply(p.id, p.persist) })
    }
  }
  property int selectedIndex: 0
  property bool fullPreview: false
  // Which of the two this overlay is showing: the side panel (SidePanel.qml)
  // or the full explorer. `omarchy-shell lock explore` asks for the one picked
  // in Settings; a reopen nobody asked a view for, after a file dialog say,
  // comes back to the one that was up.
  property string view: "full"
  readonly property bool sideView: view === "panel"
  property string requestedView: ""
  property bool everOpened: false
  readonly property string openAs: {
    if (service && service.openAs !== undefined) return String(service.openAs)
    var saved = String(localSettings.entry.openAs || "")
    return saved === "panel" || saved === "full" ? saved : "full"
  }
  readonly property var openAsOptions: [{ id: "panel", name: root.tr("Side panel") }, { id: "full", name: root.tr("Full explorer") }]
  readonly property bool barIconShown: !!service && service.barIconShown === true
  readonly property bool followTheme: !!service && service.followTheme === true
  readonly property string rotateDesigns: service && service.rotateDesigns !== undefined ? String(service.rotateDesigns) : "off"
  readonly property var rotateDesignsOptions: [{ id: "off", name: root.tr("Off") }, { id: "lock", name: root.tr("Each lock") }, { id: "day", name: root.tr("Each day") }]
  readonly property string ownerMessage: service && service.ownerMessage !== undefined ? String(service.ownerMessage) : ""
  readonly property int ownerMessageMaxLength: service && service.ownerMessageMaxLength ? service.ownerMessageMaxLength : 120
  // The owner message box has the keyboard; the key catcher leaves it alone.
  property bool ownerEditing: false

  // The side panel's first-open tour (drawn in SidePanel.qml): -1 is off.
  // It runs once, the first time the panel opens, and again from Settings.
  property int tourStep: -1
  readonly property int tourSteps: 3
  // Kept here as well, for a session where nothing can be saved.
  property bool tourDone: false
  readonly property bool tourSeen: service && service.tourSeen !== undefined ? service.tourSeen === true : tourDone
  property bool editing: false
  property var editingDesign: null
  // The visual designer, which takes over the card the same way the code
  // editor does. `designerPaused` holds the session open across the file
  // dialog, which needs the explorer to step aside.
  property bool designing: false
  property var designingDesign: null
  property bool designerPaused: false
  property string category: "all"
  // Type-to-filter over every design, from the field in the header (/ or
  // Ctrl+F). While it is non-empty the grid shows matches from all of them,
  // whichever sidebar entry is picked.
  property string searchText: ""
  property bool searching: false
  onSearchTextChanged: { selectedIndex = 0; reveal(GridView.Beginning) }
  readonly property var favoriteIds: service && service.favorites ? service.favorites : []
  function isFavorite(id) { return root.favoriteIds.indexOf(id) !== -1 }
  function favoriteDesigns() {
    return Designs.all(root.userDesigns).filter(function(d) { return root.favoriteIds.indexOf(d.id) !== -1 })
  }
  function matchesSearch(d, words) {
    var hay = [d.name, d.id, d.description || ""].concat(d.tags || []).join(" ").toLowerCase()
    for (var i = 0; i < words.length; i++) if (hay.indexOf(words[i]) === -1) return false
    return true
  }

  readonly property bool gridTab: mainTab === "styling" || mainTab === "animation" || mainTab === "seasonal" || mainTab === "favorites"

  readonly property var categories: Designs.categories()

  // A picture of each grid preview, taken once it has settled. A card that
  // comes back -- a search, another tab -- shows it at once while its live
  // design builds again on top, instead of an empty frame. Everything a
  // preview draws from is in the key, and a change to any of it starts over.
  property var thumbCache: ({})
  readonly property string thumbStateKey: [
    service ? service.designsRevision : 0,
    service ? service.backgroundPath : "", service ? service.backgroundVersion : 0,
    service ? service.avatarPath : "", service ? service.avatarVersion : 0,
    lockLanguage, accountName, twelveHour, wallpaperBlurValue, wallpaperDimShift, uiScale, motionReduced,
    showLayoutBadge, showCapsBadge, allowPasswordToggle, showAuthIcons,
    String(Commons.Color.lock.text), String(Commons.Color.lock.background), String(Commons.Color.background), thumbWidth
  ].join("|")
  onThumbStateKeyChanged: thumbCache = ({})
  function thumbFor(id) {
    var entry = thumbCache[id]
    return entry ? String(entry.url) : ""
  }
  function keepThumb(id, key, result) {
    if (key !== thumbStateKey) return
    var next = {}
    for (var k in thumbCache) next[k] = thumbCache[k]
    next[id] = result
    thumbCache = next
  }

  // Live previews start one after another, from the top-left of what is on
  // screen, rather than all at once and finishing in whatever order.
  property int thumbSlots: 0
  readonly property int gridTopRow: root.grid.cellHeight > 0 ? Math.floor(root.grid.contentY / root.grid.cellHeight) : 0
  onGridTopRowChanged: thumbSlots = 0
  Timer {
    interval: 40
    repeat: true
    running: root.opened && !root.sideView && root.gridTab && root.thumbSlots < root.columns * 5
    onTriggered: root.thumbSlots += 1
  }
  readonly property var designs: {
    var r = service ? service.designsRevision : 0
    var words = searchText.trim().toLowerCase().split(/\s+/).filter(function(w) { return w.length > 0 })
    if (words.length > 0) return Designs.all(root.userDesigns).filter(function(d) { return root.matchesSearch(d, words) })
    if (mainTab === "animation") return Designs.animations(root.userDesigns)
    if (mainTab === "seasonal") return Designs.seasonal(root.userDesigns)
    if (mainTab === "favorites") return favoriteDesigns()
    return Designs.stylings(root.userDesigns)
  }
  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "io.github.sirjul1337.lock-explorer"
  readonly property string activeDesignId: service ? service.designId
    : String(localSettings.entry.design || Designs.DEFAULT_ID)
  readonly property var selectedDesign: designs.length > 0 ? designs[Math.max(0, Math.min(selectedIndex, designs.length - 1))] : null
  readonly property string avatarUrl: service ? service.avatarUrl : ""
  // Top level view: the design grid, or one of the settings pages.
  property string mainTab: "styling"
  onMainTabChanged: {
    if ((mainTab === "boot" || mainTab === "editor") && service && typeof service.refreshBootPreviews === "function") service.refreshBootPreviews()
    if (mainTab !== "editor") bootEditing = ""
    refocus()
  }

  function toggleSettings(tab) {
    mainTab = mainTab === tab ? "styling" : tab
  }

  function handleEscape() {
    if (showingKeys) { showingKeys = false; return }
    if (searchText.length > 0 && gridTab) { searchText = ""; return }
    if (confirmingDelete.length > 0) { confirmingDelete = ""; return }
    if (designing) { root.designerView.requestClose(); return }
    if (editing) { closeEditor(); return }
    if (bootEditing.length > 0) { closeBootEditor(); return }
    if (fullPreview) { fullPreview = false; return }
    if (sideView && tourStep >= 0) { endTour(); return }
    if (sideView) { dismiss(); return }
    if (mainTab !== "styling") { mainTab = "styling"; refocus(); return }
    dismiss()
  }

  // Deleting a user design is a two-step: first X arms the button, second
  // confirms. Esc or moving the selection disarms.
  property string confirmingDelete: ""
  onSelectedIndexChanged: confirmingDelete = ""
  onDesignsChanged: {
    if (selectedIndex >= designs.length) selectedIndex = Math.max(0, designs.length - 1)
    thumbSlots = 0
  }

  function deleteSelected() {
    var d = root.selectedDesign
    if (!d || !d.path || !root.service) return
    if (root.confirmingDelete !== d.id) { root.confirmingDelete = d.id; return }
    root.confirmingDelete = ""
    root.service.deleteDesign(d.id)
  }

  // Boot cards use the same two-step confirm; only your own videos and
  // layouts get the button.
  function deleteBootCard(id) {
    if (root.confirmingDelete !== id) { root.confirmingDelete = id; return }
    root.confirmingDelete = ""
    if (root.service && typeof root.service.deleteBootItem === "function") root.service.deleteBootItem(id)
  }

  Timer {
    id: bootFormSaveTimer
    interval: 400
    onTriggered: root.saveBootForm()
  }

  Process {
    id: snapshotMkdirProc
    // The folder through safe-paths, and no link left where a grab is saved
    // (saveToFile writes through one).
    onExited: function(code) {
      if (code !== 0) { root.snapshotBusy = false; return }
      snapshotRenderTimer.restart()
    }
  }

  // Give the design a beat to load its wallpaper and lay out before grabbing.
  Timer {
    id: snapshotRenderTimer
    interval: 1100
    onTriggered: {
      var id = snapshotHost.designId
      var path = Quickshell.env("HOME") + "/.local/state/omarchy/lock-explorer-snapshots/" + id + ".png"
      // The design keeps its input box but empties it (see snapshotMode); the
      // boot theme puts its bullets inside that box, so the boot screen uses
      // the design's own field instead of a generic pill.
      var it = snapshotHost.item
      if (it && it.snapshotMode !== undefined) it.snapshotMode = true
      var rect = ""
      var n = it && it.inputItem ? it.inputItem : null
      while (n && n !== it && n.placeholder === undefined) n = n.parent
      if (n && n !== it && n.placeholder !== undefined && n.visible) {
        // Measure the input text area (inputItem sits between the lock glyph
        // and the eye), and carry the field's alignment so the bullets start
        // where the lock screen's dots would.
        var ia = it.inputItem
        var p = ia.mapToItem(snapshotSource, 0, 0)
        var align = n.textAlignment === TextInput.AlignLeft ? "left"
                  : n.textAlignment === TextInput.AlignRight ? "right" : "center"
        var sw = root.snapshotWidth, sh = root.snapshotHeight
        rect = (100 * (p.x + ia.width / 2) / sw).toFixed(2) + "," + (100 * (p.y + ia.height / 2) / sh).toFixed(2)
             + "," + (100 * ia.width / sw).toFixed(2) + "," + (100 * ia.height / sh).toFixed(2)
             + "," + align
      }
      var grabOk = snapshotSource.grabToImage(function(result) {
        var saved = result && result.saveToFile(path)
        if (root.service) root.service.logEvent("snapshot-grab " + id + (saved ? " ok rect=" + rect : " save-failed"))
        if (!saved) { root.snapshotBusy = false; return }
        root.snapshotRect = rect
        // Second, box-free grab: apply.sh picks it up as the background for
        // reboot/shutdown and promptless stretches of boot, so the splash
        // never shows a dead entry box (see snapshotBare in DesignBase).
        if (it && it.snapshotBare !== undefined) {
          it.snapshotBare = true
          snapshotBareTimer.restart()
        } else {
          root.snapshotFinish()
        }
      }, Qt.size(root.snapshotPixelWidth, root.snapshotPixelHeight))
      if (!grabOk) {
        root.snapshotBusy = false
        if (root.service) root.service.logEvent("snapshot-grab-deferred " + id)
        // Never-shown window: park the request for the next open and say so.
        if (!root.pendingResnapshot) {
          root.pendingResnapshot = { id: id, persist: root.snapshotPersist }
          Quickshell.execDetached(["notify-send", "-a", "Lock Screen Explorer",
            root.tr("Boot screen is out of date"),
            root.tr("The background changed. Open the lock screen explorer once and it refreshes itself.")])
        }
      }
    }
  }

  // One frame is not reliably enough for the opacity change to land in the
  // next grab; a short settle keeps the box-free capture honest. If this grab
  // fails, snapshotFinish still applies: apply.sh only trusts a plain capture
  // newer than the snapshot, so a stale or missing file falls back cleanly.
  Timer {
    id: snapshotBareTimer
    interval: 150
    onTriggered: {
      var id = snapshotHost.designId
      var ppath = Quickshell.env("HOME") + "/.local/state/omarchy/lock-explorer-snapshots/" + id + "-plain.png"
      var ok = snapshotSource.grabToImage(function(result) {
        var saved = result && result.saveToFile(ppath)
        if (root.service) root.service.logEvent("snapshot-grab-plain " + id + (saved ? " ok" : " save-failed"))
        root.snapshotFinish()
      }, Qt.size(root.snapshotPixelWidth, root.snapshotPixelHeight))
      if (!ok) root.snapshotFinish()
    }
  }

  readonly property bool hasAvatar: avatarUrl.length > 0
  readonly property string userInitial: {
    var name = Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
    return name.length > 0 ? name.charAt(0).toUpperCase() : "?"
  }

  readonly property color background: Commons.Color.menu.background
  readonly property color foreground: Commons.Color.menu.text
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.6)
  readonly property color accent: Commons.Color.accent
  readonly property color scrim: Commons.Color.menu.scrim
  // Errors and the delete confirm take the theme's urgent color. Badges and
  // dimmers over thumbnails are the theme background at an alpha, so their
  // foreground text stays readable on light themes too.
  readonly property color danger: Commons.Color.urgent
  function shade(alpha) { return Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, alpha) }
  readonly property var borderSpec: Border.surfaceSpec("menu", "border", Commons.Color.menu.border, Math.max(1, Style.space(2)))
  // Redesign visual language: sharp corners, everforest-style typography.
  // Colors still follow the Omarchy theme.
  readonly property int cornerRadius: 0
  readonly property string fontFamily: Style.font.menuFamily
  readonly property int sidebarW: Style.space(172)
  readonly property int rightPanelW: Style.space(348)

  readonly property int columns: 3
  readonly property int contentMargin: Style.spacing.panelPadding + Style.space(8)
  readonly property int gap: Style.space(20)
  readonly property int captionHeight: Style.space(58)
  readonly property int headerHeight: Style.space(96)
  readonly property int footerHeight: Style.space(40)
  readonly property int borderWidth: Math.max(1, Style.space(2))
  readonly property int cardWidth: Math.min(Style.space(1560), panel.width - Style.gapsOut * 4)
  readonly property int cardHeight: panel.height - Style.gapsOut * 2
  readonly property int cellWidth: Math.floor(root.grid.width / columns)
  readonly property int thumbWidth: cellWidth - gap
  readonly property int thumbHeight: Math.round(thumbWidth * 9 / 16)

  // Tab asked for via `omarchy-shell lock exploreTab <tab>`; open() resets to
  // styling otherwise, so the request has to survive the summon.
  property string requestedTab: ""

  function open(payloadJson) {
    root.opened = true
    root.fullPreview = false
    // Back from the file dialog: drop straight into the design that was open.
    if (root.designerPaused) {
      root.designerPaused = false
      root.requestedTab = ""
      if (root.service && typeof root.service.rescanUserDesigns === "function") root.service.rescanUserDesigns()
      Qt.callLater(function() { root.designerView.focusCanvas() })
      return
    }
    var asked = root.requestedView === "panel" || root.requestedView === "full" ? root.requestedView
      : (root.everOpened ? root.view : root.openAs)
    // A tab asked for by name is a page of the full explorer.
    if (root.requestedTab.length > 0) asked = "full"
    root.requestedView = ""
    root.everOpened = true
    root.view = asked
    root.category = "all"
    if (root.sideView) {
      // On the design in use, under Favorites when it is starred: those are
      // the ones switched between.
      var active = Designs.byId(root.activeDesignId, root.userDesigns)
      root.mainTab = root.isFavorite(root.activeDesignId) ? "favorites"
        : (active && Designs.isAnimated(active) ? "animation" : "styling")
      if (!root.selectById(root.activeDesignId)) root.selectedIndex = 0
      root.tourStep = root.tourSeen ? -1 : 0
    } else {
      root.tourStep = -1
      root.mainTab = root.requestedTab.length > 0 ? root.requestedTab : "styling"
      var idx = Designs.indexOf(root.activeDesignId, root.userDesigns)
      root.selectedIndex = idx >= 0 ? idx : 0
    }
    root.requestedTab = ""
    if (root.service) {
      if (typeof root.service.rescanUserDesigns === "function") root.service.rescanUserDesigns()
      if (typeof root.service.refreshBackground === "function") root.service.refreshBackground()
      if (typeof root.service.refreshFingerprintStatus === "function") root.service.refreshFingerprintStatus()
      if (typeof root.service.refreshFido2Status === "function") root.service.refreshFido2Status()
    }
    Qt.callLater(function() { root.keyCatcher.forceActiveFocus() })
    revealTimer.restart()
  }

  Timer {
    id: revealTimer
    interval: 80
    onTriggered: {
      root.reveal(GridView.Center)
      root.keyCatcher.forceActiveFocus()
    }
  }

  function close() { root.opened = false }

  function dismiss() {
    root.opened = false
    root.fullPreview = false
    root.showingKeys = false
    root.searchText = ""
    root.searching = false
    if (root.designerPaused) {
      if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
      return
    }
    root.mainTab = "styling"
    root.editing = false
    root.editingDesign = null
    root.designing = false
    root.designingDesign = null
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function customizeSelected() {
    if (!root.selectedDesign || !root.service) return
    if (root.selectedDesign.path) { editSelected(); return }
    root.service.customizeDesign(root.selectedDesign.id)
  }

  // A design of your own opens where it was made: the designer for a layout,
  // the code editor for hand-written QML.
  function editSelected() {
    var d = root.selectedDesign
    if (!d || !d.path) return
    if (d.designer) root.openDesigner(d)
    else root.openEditor(d)
  }

  function newDesign() {
    if (root.service) root.service.customizeDesign("new")
  }

  // A new visual design: the service writes the starter layout, and the
  // designerDesignCreated signal below opens it.
  function newDesignerDesign() {
    if (!root.service) return
    root.service.createDesignerDesign(Layout.generate(Layout.starterDoc("My Layout"), root.pluginId))
  }

  function openDesigner(design) {
    if (!design || !design.path) return
    root.designingDesign = design
    root.designing = true
    root.editing = false
    root.fullPreview = false
    // Re-read it: the same design may have been edited as code in between.
    Qt.callLater(function() { root.designerView.load() })
    // And hand it the keyboard once the card is really up. Asking on the same
    // tick does not stick — the shortcuts then stay dead until the first click
    // lands inside the designer.
    designerFocusTimer.restart()
  }

  Timer {
    id: designerFocusTimer
    interval: 150
    repeat: false
    onTriggered: if (root.designing) root.designerView.focusCanvas()
  }

  function closeDesigner() {
    root.designing = false
    root.designingDesign = null
    if (root.service && typeof root.service.rescanUserDesigns === "function") root.service.rescanUserDesigns()
    Qt.callLater(function() { root.keyCatcher.forceActiveFocus() })
  }

  // The Image piece needs the file dialog, which needs the keyboard. Save
  // first, step aside, and come back into the same design.
  function pickDesignerImage() {
    if (!root.service) return
    root.designerView.save()
    root.designerPaused = true
    root.dismiss()
    root.service.pickImage(true)
  }

  function openEditor(design) {
    if (!design || !design.path) return
    root.editingDesign = design
    root.editing = true
    root.fullPreview = false
    Qt.callLater(function() { root.editorView.focusCode() })
  }

  function closeEditor() {
    root.editing = false
    root.editingDesign = null
    Qt.callLater(function() { root.keyCatcher.forceActiveFocus() })
  }

  function openExternal(path) {
    Quickshell.execDetached(["omarchy-launch-editor", path])
    root.dismiss()
  }

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    function onBootDesignLoaded(name, content) {
      root.bootFormParse(content)
      root.bootEditing = name
      root.mainTab = "editor"
    }
    function onDesignCustomized(id, path) {
      if (!root.opened) return
      root.setCategory("custom")
      Qt.callLater(function() {
        root.selectById(id)
        var d = Designs.byId(id, root.userDesigns)
        if (d) root.openEditor(d)
      })
    }
    function onDesignerDesignCreated(id, path) {
      if (!root.opened) return
      Qt.callLater(function() {
        root.selectById(id)
        var d = Designs.byId(id, root.userDesigns)
        if (d) root.openDesigner(d)
      })
    }
    function onImagePicked(path) {
      root.designerView.fileFieldPicked(path)
    }
    function onClipDesignAdded(id) {
      root.mainTab = "animation"
      Qt.callLater(function() { root.selectById(id) })
    }
    function onBootPreviewsVersionChanged() {
      if (root.service && !root.service.bootPreviewsRunning && !root.service.bootPreviewsPending)
        root.bootEditBusy = false
    }
    function onExploreTabRequested(tab) {
      if (tab !== "styling" && tab !== "animation" && tab !== "seasonal" && tab !== "favorites" && tab !== "boot" && tab !== "settings") return
      // summon() re-runs open() even when already open, and open() resets the
      // tab — stash the request so it survives either path.
      root.requestedTab = tab
      if (root.opened) root.mainTab = tab
    }
    // Which of the two `omarchy-shell lock explore` wants; open() runs next.
    function onExploreViewRequested(view) {
      root.requestedView = view
    }
    // Theme changed under an applied snapshot: retake it under the new theme.
    function onBootResnapshotRequested(designId, persist) {
      if (root.service) root.service.logEvent("resnapshot-request " + designId)
      root.snapshotAndApply(designId, persist)
    }
  }

  function useDesign(id, dismissAfter, everywhere) {
    if (!Designs.byId(String(id), root.userDesigns) || selectDesignProc.running) return
    root.selectionError = ""
    var how = everywhere && root.followTheme ? "all" : undefined
    if (root.service && typeof root.service.setDesign === "function") {
      if (root.service.setDesign(id, how)) {
        if (dismissAfter) root.dismiss()
      } else root.selectionError = "Could not select this lock design"
      return
    }
    // The authentication service is intentionally private in Omarchy 4.0.3.
    // Use its existing settings command, never expose the PAM service to UI.
    selectDesignProc.dismissAfter = dismissAfter
    selectDesignProc.command = ["omarchy-shell", "lock", how === "all" ? "setDesignForAll" : "setDesign", String(id)]
    selectDesignProc.running = true
  }

  Process {
    id: selectDesignProc
    property bool dismissAfter: false
    stdout: StdioCollector { id: selectDesignOut; waitForEnd: true }
    onExited: function(code) {
      if (code === 0 && String(selectDesignOut.text || "").trim() === "ok") {
        localSettings.reload()
        if (dismissAfter) root.dismiss()
      } else root.selectionError = "Could not select this lock design; please try again"
    }
  }

  function apply(everywhere) {
    if (selectedDesign) root.useDesign(selectedDesign.id, true, everywhere)
  }

  // Dedicated render surface for background snapshots. grabToImage needs a
  // rendered frame, which the explorer panel only has while open — so a
  // theme/wallpaper change with a closed explorer always hit the deferred
  // path and the boot image went stale. This window exists only for the
  // duration of a snapshot flow and shows nothing: its content is parked
  // off-screen, it takes no focus, and it reserves no screen space.
  PanelWindow {
    id: snapshotWindow
    visible: root.snapshotBusy
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-lock-explorer-snapshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Click-through: it is mapped full-screen on the overlay layer for a second
    // or two per snapshot, and must not swallow clicks meant for the explorer.
    mask: Region {}

    // Off-screen full-resolution render used to snapshot a lock design into a
    // boot background. Parked far outside the window so it never shows.
    Item {
      id: snapshotSource
      // Parked relative to its own width: the item is as wide as the display
      // now, so a fixed offset would let a very wide one back onto the screen.
      x: -width - 200; y: -height - 200
      width: root.snapshotWidth; height: root.snapshotHeight
      LockHost {
        id: snapshotHost
        anchors.fill: parent
        designId: root.activeDesignId
        revision: root.service ? root.service.designsRevision : 0
        userDesigns: root.userDesigns
        twelveHour: root.twelveHour
        wallpaperBlur: root.wallpaperBlurValue
        wallpaperDim: root.wallpaperDimShift
        uiScale: root.uiScale
        holdStill: root.motionReduced
        language: root.lockLanguage
        fullName: root.accountName
        showLayoutBadge: root.showLayoutBadge
        showCapsBadge: root.showCapsBadge
        allowPasswordToggle: root.allowPasswordToggle
        showAuthIcons: root.showAuthIcons
        backgroundPath: root.service ? root.service.backgroundPath : ""
        backgroundVersion: root.service ? root.service.backgroundVersion : 0
        avatarPath: root.service ? root.service.avatarPath : ""
        avatarVersion: root.service ? root.service.avatarVersion : 0
        inputEnabled: false
        loadBackground: root.opened || root.snapshotBusy
        passwordText: ""
        videoPath: root.service ? root.service.videoPath : ""
        videoPlaying: false
      }
    }
  }

  ExplorerWindow { id: panel; root: root }
}
