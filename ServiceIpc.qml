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


  IpcHandler {
    target: "lock"

    function lock(): string {
      if (!root.passwordPamConfigured) return "missing-pam"
      // lockRequested, not locked: during the unlock animation the session is
      // still locked but on its way out, and a lock asked for then (before
      // sleep, say) has to cancel that instead of being answered "ok".
      if (!root.lockRequested && !root.beginLock()) return "failed"
      return "ok"
    }

    function isLocked(): string {
      return root.locked ? "true" : "false"
    }

    function status(): string {
      return JSON.stringify({
        locked: root.locked,
        requested: root.lockRequested,
        pending: root.pendingSessionLock,
        sessionLocked: root.sessionLock.locked,
        secure: root.sessionLock.secure,
        realScreens: root.realScreenCount(),
        passwordPam: root.passwordPamConfigured,
        multimedia: root.multimediaAvailable,
        fingerprint: root.fingerprintConfigured,
        fingerprintConfigured: root.fingerprintConfigured,
        faceConfigured: root.faceConfigured,
        faceAuthenticating: root.faceAuthenticating,
        fido2Configured: root.fido2Configured,
        fido2Installed: root.fido2Installed,
        fido2Enabled: root.fido2Enabled,
        fido2Token: root.fido2TokenPresent,
        fido2Authenticating: root.fido2Authenticating,
        fido2PinAttempts: root.fido2PinAttempts,
        authMode: root.authMode,
        authenticating: root.authenticating,
        lastEvent: root.lastEvent,
        lastEventAt: root.lastEventAt,
        design: root.designId,
        boot: root.bootSetting,
        bootApplied: root.bootApplied,
        bootApplying: root.bootApplying,
        unlock: root.unlockAnimation,
        unlockMs: root.unlockDuration,
        unlockAnimated: root.unlockAnimated,
        blankMs: root.blankDelay,
        inputBlocked: root.inputBlocked,
        keyboardLayout: root.keyboardLayout,
        capsLock: root.capsLock,
        fingerprintStatus: root.fingerprintStatus,
        shadowedBy: root.shadowingDirs,
        rivalLockPlugins: root.rivalLockPlugins,
        wakeGraceMs: root.wakeInputGrace,
        faceStart: root.faceStart,
        powerActions: root.powerActions,
        mediaControls: root.mediaControls,
        awayReport: root.awayReport,
        wallpaperBlur: root.wallpaperBlur,
        wallpaperDim: root.wallpaperDim,
        reduceMotion: root.reduceMotion,
        motionReduced: root.motionReduced,
        onBattery: root.onBattery,
        batteryPercent: root.batteryPercent,
        batteryLow: root.batteryLow,
        uiScale: root.uiScale,
        language: root.language,
        fieldItems: { layout: root.showLayoutBadge, caps: root.showCapsBadge, reveal: root.allowPasswordToggle, icons: root.showAuthIcons },
        languageSetting: root.languageSetting,
        keepDisplayOn: root.keepDisplayOn,
        displayBlankingSuppressed: root.displayBlankingSuppressed,
        unlocking: root.unlocking,
        clipDesign: root.designHasClip,
        clipUnlocking: root.clipUnlocking,
        video: root.videoPath,
        sting: root.stingPath,
        stingPlaying: root.stingPlaying,
        previewTyped: root.previewTyped.length
      })
    }

    function preview(): string {
      root.previewUnlocking = false
      root.previewClipPlaying = false
      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.previewVisible = true
      return "ok"
    }

    function hidePreview(): string {
      root.previewUnlockTimer.stop()
      root.previewUnlocking = false
      root.previewClipPlaying = false
      root.previewVisible = false
      root.previewDesignId = ""
      root.previewTyped = ""
      return "ok"
    }

    function design(): string {
      return root.designId
    }

    function designs(): string {
      return JSON.stringify(Designs.all(root.userDesigns).map(function(d) {
        return { id: d.id, name: d.name, description: d.description, active: d.id === root.designId }
      }))
    }

    function setDesign(id: string): string {
      return root.setDesign(id) ? "ok" : "unknown-design"
    }

    // The same, for every theme at once: the per-theme picks are forgotten.
    function setDesignForAll(id: string): string {
      return root.setDesign(id, "all") ? "ok" : "unknown-design"
    }

    function setKeepDisplayOn(value: string): string {
      return root.setKeepDisplayOn(value) ? "ok" : "invalid-value"
    }

    function setBlankDelay(value: string): string {
      return root.setBlankDelay(value) ? "ok" : "invalid-value"
    }

    function powerActions(): string {
      return root.powerActions ? "on" : "off"
    }

    function setPowerActions(value: string): string {
      return root.setPowerActions(value) ? "ok" : "invalid-value"
    }

    function mediaControls(): string {
      return root.mediaControls ? "on" : "off"
    }

    function setMediaControls(value: string): string {
      return root.setMediaControls(value) ? "ok" : "invalid-value"
    }

    function followTheme(): string {
      return root.followTheme ? "on" : "off"
    }

    // on or off: remember a design per Omarchy theme and switch with the theme.
    function setFollowTheme(value: string): string {
      return root.setFollowTheme(value) ? "ok" : "invalid-value"
    }

    function rotateDesigns(): string {
      return root.rotateDesigns
    }

    // off, lock or day: the favorites take turns on each lock, or daily.
    function setRotateDesigns(value: string): string {
      return root.setRotateDesigns(value) ? "ok" : "invalid-value"
    }

    function ownerMessage(): string {
      return root.ownerMessage
    }

    // A line in the bottom left corner of every design; empty clears it.
    function setOwnerMessage(value: string): string {
      return root.setOwnerMessage(value) ? "ok" : "too-long"
    }

    function awayReport(): string {
      return root.awayReport ? "on" : "off"
    }

    function setAwayReport(value: string): string {
      return root.setAwayReport(value) ? "ok" : "invalid-value"
    }

    function openAs(): string {
      return root.openAs
    }

    // panel or full: what `explore` opens.
    function setOpenAs(value: string): string {
      return root.setOpenAs(value) ? "ok" : "invalid-value"
    }

    // The side panel with its first-open tour, again.
    function tour(): string {
      root.setTourSeen(false)
      return root.summonExplorer("panel")
    }

    function barIcon(): string {
      return root.barIconShown ? "on" : "off"
    }

    function setBarIcon(value: string): string {
      return root.setBarIcon(value) ? "ok" : "invalid-value"
    }

    function lockOnKeyRemoval(): string {
      return root.lockOnKeyRemoval ? "on" : "off"
    }

    function setLockOnKeyRemoval(value: string): string {
      return root.setLockOnKeyRemoval(value) ? "ok" : "invalid-value"
    }

    function wakeOnKeyInsert(): string {
      return root.wakeOnKeyInsert ? "on" : "off"
    }

    function setWakeOnKeyInsert(value: string): string {
      return root.setWakeOnKeyInsert(value) ? "ok" : "invalid-value"
    }

    function favorites(): string {
      return root.favorites.join("\n")
    }

    function toggleFavorite(id: string): string {
      return root.toggleFavorite(id) ? (root.favorites.indexOf(id) !== -1 ? "on" : "off") : "unknown-design"
    }

    function wallpaperBlur(): string {
      return root.wallpaperBlur
    }

    function setWallpaperBlur(value: string): string {
      return root.setWallpaperBlur(value) ? "ok" : "invalid-value"
    }

    function reduceMotion(): string {
      return root.reduceMotion
    }

    function setReduceMotion(value: string): string {
      return root.setReduceMotion(value) ? "ok" : "invalid-value"
    }

    function fieldItems(): string {
      return "layout=" + (root.showLayoutBadge ? "show" : "hide") + " caps=" + (root.showCapsBadge ? "show" : "hide")
        + " reveal=" + (root.allowPasswordToggle ? "show" : "hide") + " icons=" + (root.showAuthIcons ? "show" : "hide")
    }

    function setFieldItem(name: string, value: string): string {
      if (["show", "hide", "on", "off"].indexOf(value) === -1) return "invalid-value"
      return root.setFieldItem(name, value === "show" || value === "on") ? "ok" : "invalid-item"
    }

    function language(): string {
      return root.languageSetting === "auto" ? "auto (" + root.language + ")" : root.language
    }

    function setLanguage(value: string): string {
      return root.setLanguage(value) ? "ok" : "invalid-value"
    }

    function size(): string {
      return Math.round(root.uiScale * 100) + "%"
    }

    function setSize(value: string): string {
      return root.setUiScale(value) ? "ok" : "invalid-value"
    }

    function wallpaperDim(): string {
      return root.wallpaperDim
    }

    function setWallpaperDim(value: string): string {
      return root.setWallpaperDim(value) ? "ok" : "invalid-value"
    }

    function wakeGrace(): string {
      return String(root.wakeInputGrace)
    }

    function setWakeGrace(value: string): string {
      return root.setWakeGrace(value) ? "ok" : "invalid-value"
    }

    function faceStart(): string {
      return root.faceStart
    }

    function setFaceStart(value: string): string {
      return root.setFaceStart(value) ? "ok" : "invalid-value (always, wake or off)"
    }

    function boot(): string {
      var applied = root.bootApplied.length > 0 ? root.bootApplied : "stock"
      return root.bootSetting + " (applied: " + applied + (root.bootApplying ? ", rebuilding" : "") + ")"
    }

    function setBoot(value: string): string {
      if (root.bootApplying) return "busy"
      return root.setBoot(value) ? "ok" : "unknown-boot"
    }

    function setBootResync(value: string): string {
      return root.setBootResync(value === "on" || value === "true") ? "ok" : "failed"
    }

    function bootRotation(): string {
      return (root.bootRotation || []).join(",")
    }

    function toggleBootRotation(id: string): string {
      return root.toggleBootRotation(id) ? "ok" : "failed"
    }

    function enableBootRotation(): string {
      root.enableBootRotation()
      return "ok"
    }

    // Takes out the passwordless rotation helper earlier versions installed
    // (one polkit prompt); "absent" when there is none.
    function removeBootRotationHelper(): string {
      if (!root.bootRotateHelperInstalled) return "absent"
      return root.removeBootRotationHelper() ? "ok" : "busy"
    }

    function setBootClipSeconds(value: string): string {
      return root.setBootClipSeconds(value) ? "ok" : "failed"
    }

    function previewDesign(id: string): string {
      root.rescanUserDesigns()
      if (!Designs.byId(String(id || ""), root.userDesigns)) return "unknown-design"
      root.previewDesignId = String(id)
      root.previewUnlocking = false
      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.previewVisible = true
      return "ok"
    }

    function monitors(): string {
      var screens = Quickshell.screens || []
      return JSON.stringify(screens.map(function(s) { return { name: s.name, width: s.width, height: s.height, input: root.showsInput(s) } }))
    }

    function inputMonitor(): string {
      return root.inputMonitor
    }

    function setInputMonitor(name: string): string {
      return root.setInputMonitor(name) ? "ok" : "failed"
    }

    function unlockAnimation(): string {
      return root.unlockAnimated ? root.unlockAnimation + " " + root.unlockDuration + "ms" : "none"
    }

    function setUnlockAnimation(name: string): string {
      return root.setUnlockAnimation(name) ? "ok" : "unknown-animation"
    }

    function setUnlockDuration(ms: string): string {
      return root.setUnlockDuration(ms) ? "ok" : "out-of-range"
    }

    function previewUnlock(): string {
      if (!root.previewVisible) return "no-preview"
      var pd = Designs.byId(root.previewDesignId.length > 0 ? root.previewDesignId : root.designId, root.userDesigns)
      if (pd && pd.clip) {
        root.previewClipPlaying = true
        return "ok"
      }
      if (!root.unlockAnimated) {
        root.previewVisible = false
        root.previewDesignId = ""
        root.previewTyped = ""
        return "ok"
      }
      root.previewUnlocking = true
      root.previewUnlockTimer.restart()
      return "ok"
    }

    // Feeds the preview's password field, so a demo can type without hands.
    function previewType(text: string): string {
      if (!root.previewVisible) return "no-preview"
      root.previewTyped = String(text || "")
      return "ok"
    }

    function previewFail(): string {
      root.previewFailure = ""
      root.previewFailure = "Authentication failed (1)"
      root.previewFailureTimer.restart()
      return "ok"
    }

    function customize(id: string): string {
      return root.customizeDesign(id) ? "ok" : "unknown-design"
    }

    function editDesign(id: string): string {
      var d = Designs.byId(String(id || ""), root.userDesigns)
      if (!d || !d.path) return "not-a-custom-design"
      Quickshell.execDetached(["omarchy-launch-editor", decodeURIComponent(d.path.replace(/^file:\/\//, ""))])
      return "ok"
    }

    function reloadDesigns(): string {
      root.reloadDesigns()
      return "ok"
    }

    function rescanDesigns(): string {
      root.rescanUserDesigns()
      return "ok"
    }

    function rescanComponents(): string {
      root.rescanComponents()
      return "ok"
    }

    function components(): string {
      var names = []
      for (var i = 0; i < root.components.length; i++) names.push(root.components[i].comp.name)
      return names.length > 0 ? names.join("\n") : "none"
    }

    function avatar(): string {
      return root.avatarPath
    }

    function setAvatar(path: string): string {
      return root.setAvatar(path) ? "ok" : "failed"
    }

    function clearAvatar(): string {
      return root.clearAvatar() ? "ok" : "failed"
    }

    function resetAvatar(): string {
      return root.resetAvatar() ? "ok" : "failed"
    }

    function pickAvatar(): string {
      return root.pickAvatar(false) ? "ok" : "busy"
    }

    function video(): string {
      return root.videoPath.length > 0 ? root.videoPath : "none"
    }

    function setVideo(path: string): string {
      return root.setVideo(path) ? "ok" : "failed"
    }

    function clearVideo(): string {
      return root.clearVideo() ? "ok" : "failed"
    }

    function pickVideo(): string {
      return root.pickVideo(false, "video") ? "ok" : "busy"
    }

    function sting(): string {
      return root.stingPath.length > 0 ? root.stingPath : "none"
    }

    function setSting(path: string): string {
      return root.setSting(path) ? "ok" : "failed"
    }

    function clearSting(): string {
      return root.clearSting() ? "ok" : "failed"
    }

    function pickSting(): string {
      return root.pickVideo(false, "sting") ? "ok" : "busy"
    }

    function newClipDesign(): string {
      return root.pickVideo(false, "clip") ? "ok" : "busy"
    }

    function clipWallpaper(): string {
      return root.clipWallpaper ? "on" : "off"
    }

    function setClipWallpaper(on: string): string {
      return root.setClipWallpaper(on) ? "ok" : "failed"
    }

    function clipSpeed(): string {
      return String(root.clipSpeed)
    }

    function setClipSpeed(v: string): string {
      return root.setClipSpeed(v) ? "ok" : "failed"
    }

    function menuEntry(): string {
      return root.menuEntryInstalled ? "on" : "off"
    }

    function setMenuEntry(v: string): string {
      return root.setMenuEntry(v === "on" || v === "true" || v === "1") ? "ok" : "failed"
    }

    function clockFormat(): string {
      return root.twelveHour ? "12" : "24"
    }

    function setClockFormat(v: string): string {
      return root.setTwelveHour(v === "12" || v === "12h" || v === "true" || v === "on") ? "ok" : "failed"
    }

    function createClipDesign(path: string): string {
      return root.createClipDesign(path) ? "ok" : "failed"
    }

    function deleteDesign(id: string): string {
      return root.deleteDesign(id) ? "ok" : "failed"
    }

    function deleteBootItem(id: string): string {
      return root.deleteBootItem(id) ? "ok" : "failed"
    }

    function stingVolume(): string {
      return String(root.stingVolume)
    }

    function setStingVolume(value: string): string {
      return root.setStingVolume(value) ? "ok" : "failed"
    }

    function previewSting(): string {
      if (root.stingPath.length === 0) return "no-clip"
      return root.playSting() ? "ok" : "busy"
    }

    // The side panel or the full explorer, whichever Settings > System >
    // Opens as says.
    function explore(): string {
      return root.summonExplorer(root.openAs)
    }

    // The same, whatever the setting says.
    function explorePanel(): string {
      return root.summonExplorer("panel")
    }

    function exploreFull(): string {
      return root.summonExplorer("full")
    }

    // Open the built-in editor on a custom boot layout.
    function editBootLayout(name: string): string {
      if (!root.loadBootDesign(String(name || ""))) return "invalid-name"
      root.exploreViewRequested("full")
      if (root.shell && typeof root.shell.summon === "function")
        return root.shell.summon(root.pluginId, "{}") ? "ok" : "failed"
      return "no-shell"
    }

    // Open the explorer on a specific tab: styling, animation, boot or
    // settings. Also handy for scripting and screenshots.
    function exploreTab(tab: string): string {
      root.rescanUserDesigns()
      root.exploreTabRequested(String(tab || "styling"))
      root.exploreViewRequested("full")
      if (root.shell && typeof root.shell.summon === "function")
        return root.shell.summon(root.pluginId, "{}") ? "ok" : "failed"
      return "no-shell"
    }
  }
}
