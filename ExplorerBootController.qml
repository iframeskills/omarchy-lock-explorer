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

  // Quick setting for the boot (LUKS decrypt) screen, applied through
  // `omarchy-shell lock setBoot`. Only designs with a Plymouth twin under
  // plymouth/ can style it; "follow" tracks the lock design when it has one.
  readonly property string followHint: {
    var d = Designs.byId(root.activeDesignId, root.userDesigns)
    var name = d ? d.name : root.tr("your lock screen")
    if (d && d.boot === true) return root.tr("Boot matches %1 with its animated twin").arg(name)
    return root.tr("Boot matches %1 as a still — same styling for both").arg(name)
  }
  // What the boot layout form's dropdowns show for each value.
  readonly property var bootOptionNames: ({
    theme: root.tr("Theme"), wallpaper: root.tr("Wallpaper"), none: root.tr("None"),
    pill: root.tr("Pill"), line: root.tr("Line")
  })
  function bootKindLabel(d) {
    if (!d || !d.bootKind) return root.tr("theme styling")
    if (d.bootKind === "clip") return root.tr("clip") + " \u00b7 " + root.tr("plays on unlock")
    if (d.bootKind === "reactive") return root.tr("reacts to typing")
    if (d.bootKind === "animated") return root.tr("animated")
    return root.tr("theme styling")
  }
  readonly property var bootTwins: {
    var twins = Designs.bootCapable()
    var rows = []
    for (var i = 0; i < twins.length; i++)
      rows.push({ id: twins[i].id, name: twins[i].name, hint: twins[i].description, kind: root.bootKindLabel(twins[i]) })
    return rows
  }
  readonly property string bootApplied: root.service ? root.service.bootApplied : ""
  readonly property string bootAppliedTheme: root.service ? root.service.bootAppliedTheme : ""
  readonly property string bootNowName: {
    if (root.bootApplied.length === 0) return root.tr("Stock Omarchy")
    if (root.bootApplied === "theme") return root.tr("Theme colors")
    if (root.bootApplied.indexOf("snapshot:") === 0) {
      var sd = Designs.byId(root.bootApplied.substring(9), root.userDesigns)
      return root.tr("%1 (snapshot)").arg(sd ? sd.name : root.bootApplied.substring(9))
    }
    if (root.bootApplied.indexOf("custom:") === 0) return root.bootApplied.substring(7)
    if (root.bootApplied.indexOf("video:") === 0) return root.bootApplied.substring(6).replace(/\.[^.]+$/, "")
    var d = Designs.byId(root.bootApplied, root.userDesigns)
    return d ? d.name : root.bootApplied
  }
  readonly property var bootVideos: root.service && root.service.bootVideos !== undefined ? root.service.bootVideos : []
  readonly property var bootCustomDesigns: root.service && root.service.bootCustomDesigns !== undefined ? root.service.bootCustomDesigns : []
  readonly property int bootClipSeconds: root.service && root.service.bootClipSeconds !== undefined ? root.service.bootClipSeconds : 0
  readonly property var bootCards: {
    var cards = [
      { id: "stock", name: root.tr("Untouched"), kind: root.tr("stock Omarchy splash") },
      { id: "theme", name: root.tr("Theme colors"), kind: root.tr("stock layout, your theme") }
    ]
    var claimed = {}
    var twins = Designs.bootCapable()
    for (var i = 0; i < twins.length; i++) {
      cards.push({ id: twins[i].id, name: twins[i].name, kind: root.bootKindLabel(twins[i]) + (twins[i].credit ? " \u00b7 " + root.tr("by %1").arg(twins[i].credit) : "") })
      if (twins[i].clipFile) claimed[twins[i].clipFile] = true
    }
    for (var v = 0; v < root.bootVideos.length; v++) {
      if (claimed[root.bootVideos[v]]) continue
      cards.push({ id: "video:" + root.bootVideos[v], name: root.bootVideos[v].replace(/\.[^.]+$/, ""), kind: root.tr("your clip") + " \u00b7 " + root.tr("plays on unlock") })
    }
    for (var c = 0; c < root.bootCustomDesigns.length; c++)
      cards.push({ id: "custom:" + root.bootCustomDesigns[c], name: root.bootCustomDesigns[c], kind: root.tr("your layout") })
    return cards
  }
  readonly property string bootFollowTarget: {
    if (root.bootSetting !== "follow") return ""
    var d = Designs.byId(root.activeDesignId, root.userDesigns)
    return d && d.boot === true ? d.id : ""
  }
  readonly property int bootPreviewsVersion: root.service && root.service.bootPreviewsVersion !== undefined ? root.service.bootPreviewsVersion : 0
  readonly property string bootCurrentTheme: root.service && root.service.bootCurrentTheme !== undefined ? root.service.bootCurrentTheme : ""

  function bootCardPreview(id) {
    var fileId = String(id).split(":").join("-")
    return "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/lock-explorer-boot-previews/" + fileId + "-" + root.bootCurrentTheme + ".png?v=" + root.bootPreviewsVersion
  }

  property string bootEditing: ""
  property string bootEditorText: ""

  function openBootEditor(name) {
    root.mainTab = "editor"
    if (root.service && typeof root.service.loadBootDesign === "function") root.service.loadBootDesign(name)
  }

  // The unified layout editor works on a parsed key=value map; the form
  // controls edit known keys and serialize the whole map back, so keys the
  // form does not surface survive.
  property var bootFormMap: ({})
  property int bootFormRev: 0

  function bootFormGet(k, def) {
    var v = root.bootFormMap[k]
    return v === undefined ? def : v
  }
  // True from an edit until the previews caught up; drives the re-render
  // badge on the editor previews.
  property bool bootEditBusy: false

  function bootFormSet(k, v) {
    // A fresh object, or the var property emits no change signal and every
    // control bound through bootFormGet stays visually frozen.
    var m = Object.assign({}, root.bootFormMap)
    m[k] = String(v)
    root.bootFormMap = m
    root.bootFormRev++
    root.bootEditBusy = true
    root.bootFormSaveTimer.restart()
  }
  function bootFormParse(content) {
    var m = {}
    var lines = String(content).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      if (/^\s*#/.test(line)) continue
      var eq = line.indexOf("=")
      if (eq === -1) continue
      var key = line.substring(0, eq).trim()
      if (key.length === 0) continue
      m[key] = line.substring(eq + 1).trim()
    }
    root.bootFormMap = m
    root.bootFormRev++
  }
  function bootFormSerialize() {
    var order = ["background", "scanlines", "logo", "logo_y", "logo_height",
                 "title", "title_y", "title_size", "title_color",
                 "subtitle", "subtitle_y", "subtitle_size", "subtitle_color",
                 "clock", "entry", "entry_y", "entry_width", "hint"]
    var out = "# Layout for a matching lock screen and boot screen.\n"
    var seen = {}
    for (var i = 0; i < order.length; i++) {
      var k = order[i]
      if (root.bootFormMap[k] !== undefined) { out += k + " = " + root.bootFormMap[k] + "\n"; seen[k] = true }
    }
    for (var k2 in root.bootFormMap)
      if (!seen[k2]) out += k2 + " = " + root.bootFormMap[k2] + "\n"
    return out
  }
  function saveBootForm() {
    if (root.bootEditing.length === 0) return
    if (root.service && typeof root.service.saveBootDesign === "function")
      root.service.saveBootDesign(root.bootEditing, root.bootFormSerialize())
  }

  function closeBootEditor() {
    root.bootEditing = ""
    root.refocus()
  }

  // Escape is handled by the keyCatcher (the Omarchy layer-shell idiom); the
  // editor's text fields forward it via BootField.escaped().

  function saveBootDesignEdits() {
    if (root.bootEditing.length === 0) return
    if (root.service && typeof root.service.saveBootDesign === "function")
      root.service.saveBootDesign(root.bootEditing, bootEditorArea.text)
  }

  function newBootDesign() {
    root.mainTab = "editor"
    if (root.service && typeof root.service.createBootDesign === "function") root.service.createBootDesign()
  }

  readonly property var bootRotation: root.service && root.service.bootRotation !== undefined ? root.service.bootRotation : []
  readonly property bool bootRotating: root.bootSetting === "rotate"

  function toggleRotationMode() {
    if (root.bootApplying) return
    if (root.bootRotating) { root.setBoot(root.bootApplied.length > 0 ? root.bootApplied : "stock"); return }
    if (root.service && typeof root.service.enableBootRotation === "function") root.service.enableBootRotation()
  }

  function toggleInRotation(id) {
    if (root.service && typeof root.service.toggleBootRotation === "function") root.service.toggleBootRotation(id)
  }

  function inRotation(id) {
    return root.bootRotation.indexOf(id) !== -1
  }

  // Grab a full-resolution render of the active lock design and apply it as
  // a static boot background. The hidden host below does the rendering.
  // Whether the snapshot, once taken, is saved as the boot setting (a pinned
  // snapshot) or just applied as the artifact under a "follow" setting.
  property bool snapshotPersist: true

  function snapshotActiveDesign() { root.snapshotAndApply(root.activeDesignId, true) }

  // True while an off-screen snapshot is in flight; keeps the snapshot host's
  // wallpaper loaded even when the explorer is closed (theme-change resyncs
  // arrive with the panel down).
  property bool snapshotBusy: false
  property string snapshotRect: ""

  // Boot snapshots are captured at the display's own geometry, not at a fixed
  // 1920x1080. Plymouth scales the capture to the framebuffer, so a 16:9 grab
  // on an ultrawide came out stretched; and a responsive design laid out for
  // 1920 wide is the wrong composition at 3440 even before any stretch.
  // The window that renders the snapshot decides its geometry. A headless
  // snapshot can run before the explorer has ever been mapped, when
  // panel.screen may still be empty and the grab would fall to 1920x1080.
  readonly property var snapshotScreen: root.snapshotWindow.screen || root.panel.screen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
  readonly property int snapshotWidth: root.snapshotScreen && root.snapshotScreen.width > 0 ? root.snapshotScreen.width : 1920
  readonly property int snapshotHeight: root.snapshotScreen && root.snapshotScreen.height > 0 ? root.snapshotScreen.height : 1080
  // grabToImage wants device pixels; the item is sized in logical ones, so a
  // scaled display still writes a capture at its true framebuffer resolution.
  readonly property real snapshotScale: root.snapshotScreen && root.snapshotScreen.devicePixelRatio > 0 ? root.snapshotScreen.devicePixelRatio : 1
  readonly property int snapshotPixelWidth: Math.round(root.snapshotWidth * root.snapshotScale)
  readonly property int snapshotPixelHeight: Math.round(root.snapshotHeight * root.snapshotScale)

  function snapshotAndApply(id, persist) {
    if (root.bootApplying) return
    // The id names the snapshot files and comes back from the saved boot
    // setting: a plain design id only.
    var sid = String(id || "")
    if (!/^[A-Za-z0-9_-][A-Za-z0-9._-]{0,63}$/.test(sid) || sid.indexOf("..") !== -1) return
    if (!root.service) return
    root.snapshotBusy = true
    root.snapshotHost.designId = sid
    root.snapshotMkdirProc.command = ["bash", "-c",
      'source "$1" && safe_dir "$2" && for f in "$2/$3.png" "$2/$3-plain.png"; do [ ! -L "$f" ] || rm -f -- "$f"; done',
      "--", root.service.safePathsLib,
      Quickshell.env("HOME") + "/.local/state/omarchy/lock-explorer-snapshots", sid]
    // Flip snapshot mode before the render delay so any layout it causes has
    // settled long before the geometry is measured and the frame grabbed.
    if (root.snapshotHost.item && root.snapshotHost.item.snapshotMode !== undefined)
      root.snapshotHost.item.snapshotMode = true
    root.snapshotPersist = persist === undefined ? true : persist
    root.snapshotMkdirProc.running = true
  }

  // Wraps up a snapshot flow: resets the bare flag and hands the grabbed
  // frame(s) to the service. Split out because the box-free second grab
  // arrives asynchronously.
  function snapshotFinish() {
    root.snapshotBusy = false
    var it = root.snapshotHost.item
    if (it && it.snapshotBare !== undefined) it.snapshotBare = false
    if (root.service && typeof root.service.applyBootSnapshot === "function")
      root.service.applyBootSnapshot(root.snapshotHost.designId, root.snapshotPersist, root.snapshotRect)
  }

  // Apply a lock styling as the boot screen: its hand-written Plymouth twin if
  // it has one, otherwise a full-screen snapshot. This is what makes every
  // styling available for the boot screen too. persist=false keeps the boot
  // setting on "follow".
  function bootUseStyling(id, persist) {
    if (root.bootApplying) return
    var d = Designs.byId(id, root.userDesigns)
    if (d && d.boot === true) root.setBoot(id)
    else root.snapshotAndApply(id, persist === undefined ? true : persist)
  }

  function toggleFollow() {
    if (root.bootApplying) return
    // Just sets the desired choice; Apply builds it.
    if (root.bootSetting === "follow") root.setBoot("stock")
    else root.setBoot("follow")
  }

  // While following, re-match the boot screen when the lock styling changes.
  // Changing the lock styling under follow marks the boot screen dirty (via
  // bootWouldApply); it rebuilds only when Apply is pressed.

  readonly property string bootSetting: root.service ? root.service.bootSetting : "stock"
  readonly property bool bootApplying: root.service ? root.service.bootApplying : false
  readonly property string bootLabel: {
    if (root.bootApplying) return "applying..."
    if (root.bootSetting === "stock") return "Untouched"
    if (root.bootSetting === "theme") return "Theme colors"
    if (root.bootSetting === "follow") {
      var d = Designs.byId(root.activeDesignId, root.userDesigns)
      return d && d.boot === true ? "Match lock (" + d.name + ")" : "Match lock (no twin)"
    }
    var picked = Designs.byId(root.bootSetting, root.userDesigns)
    return picked ? picked.name : root.bootSetting
  }
  readonly property bool bootResync: root.service && root.service.bootResync !== undefined ? root.service.bootResync : true

  function setBoot(id) {
    if (root.bootApplying) return
    if (root.service && typeof root.service.setBoot === "function") root.service.setBoot(id)
  }

  function toggleBootResync() {
    if (root.service && typeof root.service.setBootResync === "function") root.service.setBootResync(!root.bootResync)
  }
  readonly property string bootAppliedId: root.bootApplied.length > 0 ? bootApplied : "stock"

  // What the current boot choice WOULD install, and whether that differs from
  // what is on disk — the Apply button and banner key off this. Nothing is
  // rebuilt until Apply is pressed.
  readonly property string bootWouldApply: {
    if (root.bootSetting === "stock") return "stock"
    if (root.bootSetting === "theme") return "theme"
    if (root.bootSetting.indexOf("snapshot:") === 0) return root.bootSetting
    if (root.bootSetting.indexOf("custom:") === 0 || root.bootSetting.indexOf("video:") === 0) return root.bootSetting
    if (root.bootSetting === "follow") {
      var d = Designs.byId(root.activeDesignId, root.userDesigns)
      return d && d.boot === true ? d.id : "snapshot:" + root.activeDesignId
    }
    return root.bootSetting
  }
  readonly property bool bootDirty: !root.bootApplying && root.bootWouldApply !== root.bootAppliedId
  readonly property string bootDesiredName: {
    var w = root.bootWouldApply
    if (w === "stock") return root.tr("Untouched")
    if (w === "theme") return root.tr("Theme colors")
    if (w.indexOf("snapshot:") === 0) {
      var sd = Designs.byId(w.substring(9), root.userDesigns)
      return root.tr("%1 (snapshot)").arg(sd ? sd.name : w.substring(9))
    }
    if (w.indexOf("custom:") === 0) return w.substring(7)
    if (w.indexOf("video:") === 0) return w.substring(6).replace(/\.[^.]+$/, "")
    var d = Designs.byId(w, root.userDesigns)
    return d ? d.name : w
  }

  function applyPendingBoot() {
    if (root.bootApplying) return
    var w = root.bootWouldApply
    if (w.indexOf("snapshot:") === 0) {
      // follow-without-twin keeps the "follow" setting; a pinned snapshot persists.
      root.snapshotAndApply(w.substring(9), root.bootSetting !== "follow")
      return
    }
    if (root.service && typeof root.service.applyBoot === "function") root.service.applyBoot(true, w)
  }
  readonly property string currentThemeName: root.service && root.service.bootCurrentTheme !== undefined && root.service.bootCurrentTheme.length > 0 ? root.service.bootCurrentTheme : "your theme"
}
