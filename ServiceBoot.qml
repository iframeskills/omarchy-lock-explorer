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
  readonly property alias bootBgResyncTimer: bootBgResyncTimer


  // Delete a boot card of the user's own: a video from
  // ~/.config/omarchy/lock-videos (video:<file>) or a custom boot layout
  // (custom:<name>, taking its generated lock design along). Videos still
  // used as the Motion video or the unlock clip are left alone.
  function deleteBootItem(id) {
    var v = String(id || "")
    if (v.indexOf("video:") !== 0 && v.indexOf("custom:") !== 0) return false
    if (!root.bootItemValid(v)) return false
    if (v.indexOf("video:") === 0) {
      var tail = "/" + v.substring(6)
      if ((root.videoPath.length >= tail.length && root.videoPath.lastIndexOf(tail) === root.videoPath.length - tail.length)
        || (root.stingPath.length >= tail.length && root.stingPath.lastIndexOf(tail) === root.stingPath.length - tail.length)) return false
    }
    if (root.bootSetting === v) root.setBoot("stock")
    deleteBootItemProc.command = ["bash", "-c", root.deleteBootItemScript, "delboot",
      v, root.home + "/.config/omarchy/lock-videos", root.home + "/.config/omarchy/boot-designs",
      root.home + "/.config/omarchy/lock-designs",
      root.home + "/.local/state/omarchy/lock-explorer-boot-previews"]
    deleteBootItemProc.running = true
    root.logEvent("delete-boot=" + v)
    return true
  }

  readonly property string deleteBootItemScript: '
set -e
id="$1"; videos="$2"; bootdir="$3"; lockdir="$4"; previews="$5"
# The caller checks the name too; a separator or a dot-dot never gets here.
case "${id#*:}" in */* | .* | *..* | "") exit 1 ;; esac
case "$id" in
  video:*)
    f="${id#video:}"
    rm -f -- "$videos/$f"
    rm -f -- "$previews/video-$f-"*.png
    ;;
  custom:*)
    n="${id#custom:}"
    rm -f -- "$bootdir/$n.conf"
    rm -f -- "$lockdir/$n.qml"
    rm -f -- "$previews/custom-$n-"*.png
    ;;
esac
'

  Process {
    id: deleteBootItemProc
    onExited: function(exitCode) {
      root.refreshBootLists()
      root.rescanUserDesigns()
      root.refreshBootPreviews()
    }
  }

  // The boot (LUKS decrypt) screen, styled with Plymouth. Saved on the plugin
  // entry as `boot`: "follow" keeps it matched to the lock design whenever the
  // design has a twin under plymouth/, a design id pins it to that design, and
  // absent means the stock Omarchy boot theme is left alone. Applying bakes the
  // current theme colors into a generated theme and rebuilds the initramfs
  // through a single polkit prompt (see plymouth/apply.sh).
  property string bootOverride: ""
  readonly property string configuredBoot: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.boot) return String(entry.boot)
    }
    return "stock"
  }
  readonly property string bootSetting: {
    var value = root.bootOverride.length > 0 ? bootOverride : root.configuredBoot
    if (value === "follow" || value === "stock" || value === "theme" || value === "rotate") return value
    if (value.indexOf("snapshot:") === 0 || value.indexOf("video:") === 0 || value.indexOf("custom:") === 0)
      return root.bootItemValid(value) ? value : "stock"
    var d = Designs.byId(value, root.userDesigns)
    return d && d.boot === true ? value : "stock"
  }
  property bool bootApplying: false
  property string bootApplyTarget: ""
  property string bootApplied: ""  // last installed twin, "" = stock/untouched
  property int bootAppliedVersion: 0
  readonly property string bootTarget: {
    if (root.bootSetting === "stock") return "stock"
    if (root.bootSetting === "theme") return "theme"
    if (root.bootSetting === "rotate") return ""
    if (root.bootSetting.indexOf("snapshot:") === 0) return root.bootSetting
    if (root.bootSetting === "follow") {
      var d = Designs.byId(root.designId, root.userDesigns)
      return d && d.boot === true ? d.id : ""
    }
    return root.bootSetting
  }

  function setBoot(value) {
    var v = String(value || "").trim().toLowerCase()
    if (v !== "follow" && v !== "stock" && v !== "theme" && v !== "rotate" && v.indexOf("video:") !== 0 && v.indexOf("custom:") !== 0 && v.indexOf("snapshot:") !== 0) {
      var d = Designs.byId(v, root.userDesigns)
      if (!d || d.boot !== true) return false
    } else if (v.indexOf(":") > 0 && !root.bootItemValid(v)) {
      return false
    }
    if (root.bootApplying) return false
    root.bootOverride = v
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (v === "stock") delete current.boot
      else current.boot = v
      root.writeEntry(current)
    }
    root.logEvent("boot=" + v)
    // Redesign: picking a boot option only sets the desired choice; the
    // rebuild happens when the Apply button is pressed.
    return true
  }

  // force reapplies even when the target already matches, so a changed Omarchy
  // theme gets its colors baked in again.
  function applyBoot(force, explicitTarget) {
    if (root.bootApplying) return
    var target = explicitTarget !== undefined && String(explicitTarget).length > 0 ? String(explicitTarget) : root.bootTarget
    if (target.length === 0) return  // follow, but this design has no twin
    if (target === "stock" && root.bootApplied.length === 0) return  // nothing to restore
    if (!force && target === root.bootApplied) return
    root.bootApplying = true
    root.bootApplyTarget = target
    bootApplyProc.command = ["env", "BOOT_CLIP_SECONDS=" + root.bootClipSeconds, "bash", root.pluginDir + "/plymouth/apply.sh", target]
    bootApplyProc.running = true
  }

  Process {
    id: bootApplyProc
    stdout: StdioCollector { }
    stderr: StdioCollector {
      id: bootApplyErr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.bootApplying = false
      if (exitCode === 0) {
        root.bootApplied = root.bootApplyTarget === "stock" ? "" : root.bootApplyTarget
        root.logEvent("boot-applied=" + (root.bootApplied.length > 0 ? root.bootApplied : "stock"))
      } else {
        root.logEvent("boot-apply-failed=" + exitCode)
        console.warn("lock-explorer: plymouth apply failed:", String(bootApplyErr.text || "").trim())
      }
    }
  }

  // apply.sh records what it installed and which Omarchy theme the colors
  // came from; picking it up here keeps the state right across shell restarts
  // and command line applies.
  // Watched by a FileView that never reads; the read is a CappedFile.
  FileView {
    path: root.stateHome + "/omarchy/lock-explorer-boot"
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: bootStateFile.reload()
  }
  Parts.CappedFile {
    id: bootStateFile
    path: root.stateHome + "/omarchy/lock-explorer-boot"
    maxBytes: 4096
    onLoaded: {
      var parts = String(text()).trim().split(/\s+/)
      var value = parts[0] || ""
      root.bootApplied = value === "stock" ? "" : value
      root.bootAppliedTheme = parts.length > 1 ? parts[1] : ""
      // Cache-buster for the applied-boot preview image, which is rewritten
      // on every apply (same-id re-applies included).
      root.bootAppliedVersion += 1
    }
    onLoadFailed: { root.bootApplied = ""; root.bootAppliedTheme = "" }
  }

  // The boot screen colors are baked in at apply time, so a theme switch
  // would leave it in the old palette right until the retained last frame
  // hands over to the new wallpaper. Regenerate when the theme changes,
  // unless the user opted out (`bootResync: false` on the plugin entry).
  property string bootAppliedTheme: ""
  property string bootCurrentTheme: ""
  property int bootResyncOverride: -1
  readonly property bool configuredBootResync: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.bootResync === false) return false
    }
    return true
  }
  readonly property bool bootResync: root.bootResyncOverride === -1 ? configuredBootResync : root.bootResyncOverride === 1

  function setBootResync(on) {
    var enabled = on === true || on === "on" || on === "true"
    root.bootResyncOverride = enabled ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (enabled) delete current.bootResync
      else current.bootResync = false
      root.writeEntry(current)
    }
    root.logEvent("boot-resync=" + (enabled ? "on" : "off"))
    if (enabled) root.maybeResyncBoot()
    return true
  }

  function maybeResyncBoot() {
    if (!root.bootResync || root.bootApplying || !root.bootResyncArmed) return
    if (root.bootApplied.length === 0 || root.bootAppliedTheme.length === 0 || root.bootCurrentTheme.length === 0) return
    if (root.bootAppliedTheme === root.bootCurrentTheme) return
    root.logEvent("boot-resync " + root.bootAppliedTheme + " -> " + root.bootCurrentTheme)
    if (root.bootApplied.indexOf("snapshot:") === 0) {
      // The fresh snapshot carries the new background too.
      bootBgResyncTimer.stop()
      root.bootResnapshotRequested(root.bootApplied.substring(9), root.bootSetting !== "follow")
      return
    }
    // Re-bake what is actually installed: with follow and a twin-less lock
    // design the setting resolves to nothing, but the installed twin still
    // needs the new colors.
    root.applyBoot(true, root.bootApplied)
  }

  // Cycling the background inside a theme leaves an applied snapshot showing
  // the old wallpaper. Retake it once the cycling settles; same opt-out as
  // the theme resync.
  property string bootLastBackground: ""

  Timer {
    id: bootBgResyncTimer
    interval: 8000
    onTriggered: {
      if (!root.bootResync || root.bootApplying) return
      if (root.bootApplied.indexOf("snapshot:") !== 0) return
      root.logEvent("boot-resync background")
      root.bootResnapshotRequested(root.bootApplied.substring(9), root.bootSetting !== "follow")
    }
  }


  // Thumbnails for the explorer's boot cards, one per option and theme,
  // rendered in the background by plymouth/previews.sh.
  property int bootPreviewsVersion: 0
  property bool bootPreviewsRunning: false

  property bool bootPreviewsPending: false

  function refreshBootPreviews() {
    root.refreshBootLists()
    // A request landing mid-run must queue a follow-up: the running pass
    // rendered the state before this change and would leave stale previews.
    if (root.bootPreviewsRunning) { root.bootPreviewsPending = true; return }
    root.bootPreviewsRunning = true
    bootPreviewsProc.command = ["bash", root.pluginDir + "/plymouth/previews.sh"]
    bootPreviewsProc.running = true
  }

  Process {
    id: bootPreviewsProc
    stdout: StdioCollector { }
    stderr: StdioCollector { }
    onExited: function(exitCode) {
      root.bootPreviewsRunning = false
      root.bootPreviewsVersion++
      if (root.bootPreviewsPending) {
        root.bootPreviewsPending = false
        root.refreshBootPreviews()
      }
    }
  }


  // The user's own clips and boot layouts, listed as cards on the boot tab.
  property var bootVideos: []
  property var bootCustomDesigns: []

  function refreshBootLists() { bootListsProc.running = true }

  Process {
    id: bootListsProc
    command: ["bash", "-c", "ls -1 \"$HOME/.config/omarchy/lock-videos\" 2>/dev/null; echo ::; for f in \"$HOME\"/.config/omarchy/boot-designs/*.conf; do [ -f \"$f\" ] && basename \"$f\" .conf; done"]
    stdout: StdioCollector {
      id: bootListsOut
      waitForEnd: true
      onStreamFinished: {
        var parts = String(bootListsOut.text || "").split("::")
        root.bootVideos = (parts[0] || "").split("\n")
          .map(function(l) { return l.trim() })
          .filter(function(l) { return /\.(mp4|mkv|webm|mov|m4v)$/i.test(l) })
        root.bootCustomDesigns = (parts.length > 1 ? parts[1] : "").split("\n")
          .map(function(l) { return l.trim() })
          .filter(function(l) { return l.length > 0 })
      }
    }
  }

  // How much of a clip boot screen plays, in seconds; 0 plays it all. Saved
  // on the plugin entry as bootClipSeconds.
  property int bootClipSecondsOverride: -1
  readonly property int configuredBootClipSeconds: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.bootClipSeconds !== undefined)
        return Math.max(0, Math.min(30, Number(entry.bootClipSeconds) || 0))
    }
    return 0
  }
  readonly property int bootClipSeconds: root.bootClipSecondsOverride >= 0 ? bootClipSecondsOverride : root.configuredBootClipSeconds

  function setBootClipSeconds(n) {
    var v = Math.max(0, Math.min(30, Math.round(Number(n) || 0)))
    root.bootClipSecondsOverride = v
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (v === 0) delete current.bootClipSeconds
      else current.bootClipSeconds = v
      root.writeEntry(current)
    }
    root.logEvent("boot-clip=" + v)
    var appliedIsClip = root.bootApplied.indexOf("video:") === 0
    if (!appliedIsClip) {
      var d = Designs.byId(root.bootApplied, root.userDesigns)
      appliedIsClip = !!(d && d.bootKind === "clip")
    }
    if (appliedIsClip) root.applyBoot(true, root.bootApplied)
    return true
  }
  property string bootDesignPendingLoad: ""

  // Layouts are read as a plain file of at most 64 KiB, never through a link
  // or anything that could block (a FIFO), and only by a checked name.
  function loadBootDesign(name) {
    if (!root.layoutNameValid(name)) return false
    root.bootDesignPendingLoad = String(name)
    bootLoadProc.command = ["bash", "-c",
      'f="$1"; [ -f "$f" ] && [ ! -L "$f" ] && [ "$(stat -c %s -- "$f")" -le 65536 ] && head -c 65536 -- "$f"',
      "--", root.home + "/.config/omarchy/boot-designs/" + root.bootDesignPendingLoad + ".conf"]
    bootLoadProc.running = true
    return true
  }

  Process {
    id: bootLoadProc
    stdout: StdioCollector {
      id: bootLoadOut
      waitForEnd: true
      onStreamFinished: root.bootDesignLoaded(root.bootDesignPendingLoad, String(bootLoadOut.text || ""))
    }
  }

  property string bootSaveName: ""
  function saveBootDesign(name, content) {
    if (!root.layoutNameValid(name)) return false
    var text = String(content || "")
    if (text.length > 65536) return false
    root.bootSaveName = String(name)
    bootSaveProc.command = ["bash", "-c",
      'source "$1" && d="$HOME/.config/omarchy/boot-designs" && safe_dir "$d" && printf %s "$2" | put_file "$d" "$3.conf"',
      "--", root.safePathsLib, text, root.bootSaveName]
    bootSaveProc.running = true
    return true
  }

  Process {
    id: bootSaveProc
    onExited: function(exitCode) {
      // Generate the matching lock screen QML + its preview from the same
      // layout, so the pair stays in sync.
      var previews = root.stateHome + "/omarchy/lock-explorer-boot-previews"
      lockGenProc.command = ["bash", "-c",
        'mkdir -p "$3" && bash "$1" "$HOME/.config/omarchy/boot-designs/$2.conf" "$2" "$3/custom-$2-lock-$4.png"',
        "--", root.pluginDir + "/plymouth/custom/genlock.sh", root.bootSaveName, previews, root.bootCurrentTheme]
      lockGenProc.running = true
    }
  }

  Process {
    id: lockGenProc
    onExited: function(exitCode) {
      root.refreshBootPreviews()
      root.rescanUserDesigns()
      root.logEvent("boot-design-saved")
    }
  }

  function createBootDesign() {
    bootCreateProc.command = ["bash", "-c",
      'source "$2" || exit 1; dir="$HOME/.config/omarchy/boot-designs"; safe_dir "$dir"; n="my-boot"; i=2; while [ -e "$dir/$n.conf" ] || [ -L "$dir/$n.conf" ]; do n="my-boot-$i"; i=$((i+1)); done; put_file "$dir" "$n.conf" < "$1" && echo "$n"',
      "--", root.pluginDir + "/plymouth/custom/template.conf", root.safePathsLib]
    bootCreateProc.running = true
  }

  Process {
    id: bootCreateProc
    stdout: StdioCollector {
      id: bootCreateOut
      waitForEnd: true
      onStreamFinished: {
        var n = String(bootCreateOut.text || "").trim()
        if (n.length > 0) {
          root.refreshBootLists()
          root.loadBootDesign(n)
        }
      }
    }
  }


  // Boot screen rotation: a set of options that advances one step after
  // every boot. The screen is baked into the boot image, so the swap happens
  // right after login, through the same polkit prompt as any boot screen
  // change. Saved on the plugin entry as bootRotation.
  property var bootRotationOverride: null
  readonly property var configuredBootRotation: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && Array.isArray(entry.bootRotation))
        return entry.bootRotation.filter(function(x) { return root.bootItemValid(x) })
    }
    return []
  }
  readonly property var bootRotation: root.bootRotationOverride !== null ? bootRotationOverride : root.configuredBootRotation
  // Earlier versions could install a root path unit that applied the next
  // theme without asking; a theme picks the plugin Plymouth loads as root,
  // so that is passwordless root for anything running as the account. An
  // update cannot take root files away by itself, so the first start that
  // finds one asks to remove it (one polkit prompt, explained in a
  // notification first) -- never while the screen is locked, where the
  // dialog cannot show, and again at every start until it is gone.
  property bool bootRotateHelperInstalled: false
  property bool bootRotateRemovalAsked: false
  property string bootRotateNext: ""

  function toggleBootRotation(id) {
    var v = String(id || "")
    if (v.length === 0 || v === "stock" || !root.bootItemValid(v)) return false
    var list = root.bootRotation.slice()
    var idx = list.indexOf(v)
    if (idx === -1) list.push(v)
    else list.splice(idx, 1)
    root.bootRotationOverride = list
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (list.length === 0) delete current.bootRotation
      else current.bootRotation = list
      root.writeEntry(current)
    }
    root.logEvent("boot-rotation=" + list.join(","))
    return true
  }

  // persist=false applies the snapshot as the on-disk artifact but leaves the
  // saved boot setting alone (used by follow mode, which stays "follow").
  // entryRect ("cx,cy,w,h" in percent) is where the design's own input box
  // sits in the snapshot; the boot theme puts its bullets there.
  function applyBootSnapshot(id, persist, entryRect) {
    if (root.bootApplying) return
    if (persist === undefined) persist = true
    if (persist) {
      root.bootOverride = "snapshot:" + id
      if (root.shell && typeof root.shell.updateEntryInline === "function") {
        var current = root.pluginEntry()
        current.boot = "snapshot:" + id
        root.writeEntry(current)
      }
    }
    root.bootApplying = true
    root.bootApplyTarget = "snapshot:" + id
    bootApplyProc.command = ["env", "BOOT_CLIP_SECONDS=0",
      "SNAPSHOT_ENTRY=" + String(entryRect || ""),
      "bash", root.pluginDir + "/plymouth/apply.sh", "snapshot:" + id]
    bootApplyProc.running = true
    root.logEvent("boot-snapshot=" + id + (persist ? "" : " (follow)"))
  }

  function enableBootRotation() {
    root.setBoot("rotate")
  }

  function askBootRotationHelperRemoval() {
    if (!root.bootRotateHelperInstalled || root.bootRotateRemovalAsked || root.locked || root.lockRequested) return
    root.bootRotateRemovalAsked = true
    root.logEvent("boot-rotate-helper-removal: asking")
    Quickshell.execDetached(["notify-send", "-a", "Lock Screen Explorer", "Removing an old boot screen helper",
      "An earlier version installed a background service that could change the boot screen as root without asking. "
      + "Enter your password to remove it."])
    root.removeBootRotationHelper()
  }

  function removeBootRotationHelper() {
    if (bootRotateRemoveProc.running) return false
    bootRotateRemoveProc.command = ["pkexec", "bash", root.pluginDir + "/plymouth/rotate-setup.sh", "remove"]
    bootRotateRemoveProc.running = true
    return true
  }

  Process {
    id: bootRotateRemoveProc
    stdout: StdioCollector { }
    stderr: StdioCollector { }
    onExited: function(exitCode) {
      root.logEvent(exitCode === 0 ? "boot-rotate-helper-removed" : "boot-rotate-helper-remove-failed=" + exitCode)
      if (exitCode !== 0)
        Quickshell.execDetached(["notify-send", "-a", "Lock Screen Explorer", "The old boot screen helper is still installed",
          "It will be asked for again at the next start, or run: omarchy-shell lock removeBootRotationHelper"])
      bootRotateCheckProc.running = true
    }
  }

  Process {
    id: bootRotateCheckProc
    // Any piece of it: the path unit, its service or the helper script.
    command: ["bash", "-c", "for f in /etc/systemd/system/omarchy-lock-explorer-boot.path /etc/systemd/system/omarchy-lock-explorer-boot.service /usr/local/lib/omarchy-lock-explorer-rotate.sh; do [ -e \"$f\" ] && { echo yes; exit; }; done; echo no"]
    stdout: StdioCollector {
      id: bootRotateCheckOut
      waitForEnd: true
      onStreamFinished: {
        root.bootRotateHelperInstalled = String(bootRotateCheckOut.text || "").trim() === "yes"
        if (root.bootRotateHelperInstalled) {
          root.logEvent("boot-rotate-helper-present")
          root.askBootRotationHelperRemoval()
        }
      }
    }
  }

  // Advance at most once per boot: the stamp file keeps the boot id, so
  // shell restarts inside the same boot leave the rotation alone.
  function maybeRotateBoot() {
    if (root.bootSetting !== "rotate") return
    var list = root.bootRotation
    if (!list || list.length === 0) return
    var idx = list.indexOf(root.bootApplied)
    var next = list[(idx + 1) % list.length]
    if (next === root.bootApplied) return
    root.bootRotateNext = next
    bootRotateStampProc.running = true
  }

  Process {
    id: bootRotateStampProc
    command: ["bash", "-c", "bid=$(cat /proc/sys/kernel/random/boot_id); f=\"$HOME/.local/state/omarchy/lock-explorer-boot-rotated\"; [ -f \"$f\" ] && [ ! -L \"$f\" ] && [ \"$(head -c 64 -- \"$f\")\" = \"$bid\" ] && echo skip || { [ ! -L \"$f\" ] || rm -f -- \"$f\"; echo \"$bid\" > \"$f\"; echo go; }"]
    stdout: StdioCollector {
      id: bootRotateStampOut
      waitForEnd: true
      onStreamFinished: {
        if (String(bootRotateStampOut.text || "").trim() !== "go") return
        if (root.bootRotateNext.length === 0 || root.bootApplying) return
        root.logEvent("boot-rotate -> " + root.bootRotateNext)
        root.applyBoot(true, root.bootRotateNext)
      }
    }
  }

  // Armed a little after startup so a stale palette right after login gets
  // one polkit prompt once the desktop has settled, not mid-splash.
  property bool bootResyncArmed: false

  Timer {
    interval: 12000
    running: true
    onTriggered: {
      root.bootResyncArmed = true
      root.refreshBootLists()
      bootRotateCheckProc.running = true
      // The resync runs after the rotation so one that just advanced
      // satisfies it.
      root.maybeRotateBoot()
      root.maybeResyncBoot()
    }
  }

  // The Omarchy theme that is on: the boot screen resyncs its palette to it,
  // and the design follows it when asked to (followThemeDesign).
  // Watched by a FileView that never reads; the read is a CappedFile.
  FileView {
    path: root.stateHome + "/omarchy/current/theme.name"
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: themeNameFile.reload()
  }
  Parts.CappedFile {
    id: themeNameFile
    path: root.stateHome + "/omarchy/current/theme.name"
    maxBytes: 256
    onLoaded: {
      // Joined into preview file names; anything off a plain name is ignored.
      var t = String(text()).trim()
      root.bootCurrentTheme = /^[A-Za-z0-9._-]{1,64}$/.test(t) && t.indexOf("..") === -1 ? t : ""
      root.maybeResyncBoot()
      root.followThemeDesign()
    }
    onLoadFailed: root.bootCurrentTheme = ""
  }
}
