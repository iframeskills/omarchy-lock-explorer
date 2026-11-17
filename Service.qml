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
  id: root

  ServiceSettingsStore { id: settingsStore; root: root }
  ServiceAppearance { id: appearance; root: root }
  ServiceLockPolicy { id: lockPolicy; root: root }
  ServiceMedia { id: media; root: root }
  ServicePreferences { id: preferences; root: root }
  ServicePreview { id: preview; root: root }
  ServiceDesignFiles { id: designFiles; root: root }
  ServiceDesktop { id: desktop; root: root }
  ServiceBoot { id: boot; root: root }
  ServiceSessionLock { id: sessionLock; root: root }
  ServiceAuthentication { id: authentication; root: root }
  ServiceSecurityKey { id: securityKey; root: root }
  ServiceExplorerBridge { id: explorerBridge; root: root }
  ServiceIpc { id: ipc; root: root }

  property alias shell: settingsStore.shell
  property alias manifest: settingsStore.manifest
  property alias omarchyPath: settingsStore.omarchyPath
  readonly property alias settingsConfig: settingsStore.settingsConfig
  readonly property alias pluginId: settingsStore.pluginId
  property alias designOverride: appearance.designOverride
  readonly property alias configuredDesignId: appearance.configuredDesignId
  readonly property alias designId: appearance.designId
  readonly property alias designHasClip: appearance.designHasClip
  readonly property alias designClipPath: appearance.designClipPath
  property alias inputMonitorOverride: lockPolicy.inputMonitorOverride
  readonly property alias configuredInputMonitor: lockPolicy.configuredInputMonitor
  readonly property alias inputMonitor: lockPolicy.inputMonitor
  readonly property alias unlockAnimations: lockPolicy.unlockAnimations
  readonly property alias defaultUnlockDuration: lockPolicy.defaultUnlockDuration
  property alias unlockOverride: lockPolicy.unlockOverride
  property alias unlockDurationOverride: lockPolicy.unlockDurationOverride
  readonly property alias configuredUnlock: lockPolicy.configuredUnlock
  readonly property alias configuredUnlockDuration: lockPolicy.configuredUnlockDuration
  readonly property alias unlockAnimation: lockPolicy.unlockAnimation
  readonly property alias unlockDuration: lockPolicy.unlockDuration
  readonly property alias unlockAnimated: lockPolicy.unlockAnimated
  readonly property alias defaultBlankDelay: lockPolicy.defaultBlankDelay
  property alias blankDelayOverride: lockPolicy.blankDelayOverride
  readonly property alias configuredBlankDelay: lockPolicy.configuredBlankDelay
  readonly property alias blankDelay: lockPolicy.blankDelay
  readonly property alias defaultWakeGrace: lockPolicy.defaultWakeGrace
  readonly property alias maxWakeGrace: lockPolicy.maxWakeGrace
  property alias wakeGraceOverride: lockPolicy.wakeGraceOverride
  readonly property alias configuredWakeGrace: lockPolicy.configuredWakeGrace
  readonly property alias wakeInputGrace: lockPolicy.wakeInputGrace
  readonly property alias defaultFaceStart: lockPolicy.defaultFaceStart
  readonly property alias faceStartOptions: lockPolicy.faceStartOptions
  property alias faceStartOverride: lockPolicy.faceStartOverride
  readonly property alias configuredFaceStart: lockPolicy.configuredFaceStart
  readonly property alias faceStart: lockPolicy.faceStart
  readonly property alias faceWakeQuiet: lockPolicy.faceWakeQuiet
  readonly property alias faceRoundGap: lockPolicy.faceRoundGap
  property alias lockedAt: lockPolicy.lockedAt
  property alias lastFaceRound: lockPolicy.lastFaceRound
  property alias powerActionsOverride: lockPolicy.powerActionsOverride
  readonly property alias configuredPowerActions: lockPolicy.configuredPowerActions
  readonly property alias powerActions: lockPolicy.powerActions
  property alias keepDisplayOnOverride: lockPolicy.keepDisplayOnOverride
  readonly property alias configuredKeepDisplayOn: lockPolicy.configuredKeepDisplayOn
  readonly property alias keepDisplayOn: lockPolicy.keepDisplayOn
  readonly property alias blankMarkerDir: lockPolicy.blankMarkerDir
  property alias blankCrashed: lockPolicy.blankCrashed
  readonly property alias displayBlankingSuppressed: lockPolicy.displayBlankingSuppressed
  property alias avatarOverride: media.avatarOverride
  readonly property alias configuredAvatar: media.configuredAvatar
  property alias detectedAvatar: media.detectedAvatar
  property alias avatarVersion: media.avatarVersion
  readonly property alias avatarSetting: media.avatarSetting
  readonly property alias avatarPath: media.avatarPath
  readonly property alias avatarUrl: media.avatarUrl
  property alias videoOverride: media.videoOverride
  readonly property alias configuredVideo: media.configuredVideo
  readonly property alias videoSetting: media.videoSetting
  readonly property alias videoPath: media.videoPath
  property alias stingOverride: media.stingOverride
  readonly property alias configuredSting: media.configuredSting
  readonly property alias stingSetting: media.stingSetting
  readonly property alias stingPath: media.stingPath
  readonly property alias stingUrl: media.stingUrl
  property alias stingVolumeOverride: media.stingVolumeOverride
  readonly property alias configuredStingVolume: media.configuredStingVolume
  readonly property alias stingVolume: media.stingVolume
  property alias clipSpeedOverride: media.clipSpeedOverride
  readonly property alias configuredClipSpeed: media.configuredClipSpeed
  readonly property alias clipSpeed: media.clipSpeed
  property alias twelveHourOverride: appearance.twelveHourOverride
  readonly property alias configuredTwelveHour: appearance.configuredTwelveHour
  readonly property alias twelveHour: appearance.twelveHour
  property alias openAsOverride: preferences.openAsOverride
  readonly property alias configuredOpenAs: preferences.configuredOpenAs
  readonly property alias openAs: preferences.openAs
  property alias tourSeenOverride: preferences.tourSeenOverride
  readonly property alias configuredTourSeen: preferences.configuredTourSeen
  readonly property alias tourSeen: preferences.tourSeen
  property alias awayReportOverride: preferences.awayReportOverride
  readonly property alias configuredAwayReport: preferences.configuredAwayReport
  readonly property alias awayReport: preferences.awayReport
  property alias lockOnKeyRemovalOverride: lockPolicy.lockOnKeyRemovalOverride
  readonly property alias configuredLockOnKeyRemoval: lockPolicy.configuredLockOnKeyRemoval
  readonly property alias lockOnKeyRemoval: lockPolicy.lockOnKeyRemoval
  property alias wakeOnKeyInsertOverride: lockPolicy.wakeOnKeyInsertOverride
  readonly property alias configuredWakeOnKeyInsert: lockPolicy.configuredWakeOnKeyInsert
  readonly property alias wakeOnKeyInsert: lockPolicy.wakeOnKeyInsert
  readonly property alias awayGapMs: preferences.awayGapMs
  property alias failureTimes: preferences.failureTimes
  property alias pendingAwayReport: preferences.pendingAwayReport
  property alias favoritesOverride: appearance.favoritesOverride
  readonly property alias configuredFavorites: appearance.configuredFavorites
  readonly property alias favorites: appearance.favorites
  readonly property alias fieldItems: appearance.fieldItems
  property alias fieldItemOverrides: appearance.fieldItemOverrides
  readonly property alias showLayoutBadge: appearance.showLayoutBadge
  readonly property alias showCapsBadge: appearance.showCapsBadge
  readonly property alias allowPasswordToggle: appearance.allowPasswordToggle
  readonly property alias showAuthIcons: appearance.showAuthIcons
  readonly property alias languages: appearance.languages
  readonly property alias systemLanguage: appearance.systemLanguage
  property alias languageOverride: appearance.languageOverride
  readonly property alias configuredLanguage: appearance.configuredLanguage
  readonly property alias languageSetting: appearance.languageSetting
  readonly property alias language: appearance.language
  readonly property alias reduceMotionOptions: appearance.reduceMotionOptions
  readonly property alias uiScaleOptions: appearance.uiScaleOptions
  property alias reduceMotionOverride: appearance.reduceMotionOverride
  property alias uiScaleOverride: appearance.uiScaleOverride
  readonly property alias configuredReduceMotion: appearance.configuredReduceMotion
  readonly property alias configuredUiScale: appearance.configuredUiScale
  readonly property alias reduceMotion: appearance.reduceMotion
  readonly property alias uiScale: appearance.uiScale
  readonly property alias onBattery: appearance.onBattery
  readonly property alias batteryLowAt: appearance.batteryLowAt
  readonly property alias batteryPercent: appearance.batteryPercent
  readonly property alias batteryLow: appearance.batteryLow
  readonly property alias motionReduced: appearance.motionReduced
  readonly property alias wallpaperBlurOptions: appearance.wallpaperBlurOptions
  readonly property alias wallpaperDimOptions: appearance.wallpaperDimOptions
  property alias wallpaperBlurOverride: appearance.wallpaperBlurOverride
  property alias wallpaperDimOverride: appearance.wallpaperDimOverride
  readonly property alias wallpaperBlur: appearance.wallpaperBlur
  readonly property alias wallpaperDim: appearance.wallpaperDim
  readonly property alias wallpaperBlurValue: appearance.wallpaperBlurValue
  readonly property alias wallpaperDimShift: appearance.wallpaperDimShift
  property alias fido2EnabledOverride: lockPolicy.fido2EnabledOverride
  readonly property alias configuredFido2Enabled: lockPolicy.configuredFido2Enabled
  readonly property alias fido2Enabled: lockPolicy.fido2Enabled
  readonly property alias backgroundUrl: lockPolicy.backgroundUrl
  readonly property alias settingsBackupPath: settingsStore.settingsBackupPath
  readonly property alias hostEntryKeys: settingsStore.hostEntryKeys
  property alias settingsRestoreChecked: settingsStore.settingsRestoreChecked
  readonly property alias settingsCopyMaxBytes: settingsStore.settingsCopyMaxBytes
  property alias mediaControlsOverride: appearance.mediaControlsOverride
  readonly property alias configuredMediaControls: appearance.configuredMediaControls
  readonly property alias mediaControls: appearance.mediaControls
  property alias followThemeOverride: appearance.followThemeOverride
  readonly property alias configuredFollowTheme: appearance.configuredFollowTheme
  readonly property alias followTheme: appearance.followTheme
  property alias themeDesignsOverride: appearance.themeDesignsOverride
  readonly property alias configuredThemeDesigns: appearance.configuredThemeDesigns
  readonly property alias themeDesigns: appearance.themeDesigns
  property alias ownerMessageOverride: appearance.ownerMessageOverride
  readonly property alias configuredOwnerMessage: appearance.configuredOwnerMessage
  readonly property alias ownerMessage: appearance.ownerMessage
  readonly property alias ownerMessageMaxLength: appearance.ownerMessageMaxLength
  readonly property alias rotateDesignsOptions: appearance.rotateDesignsOptions
  property alias rotateDesignsOverride: appearance.rotateDesignsOverride
  readonly property alias configuredRotateDesigns: appearance.configuredRotateDesigns
  readonly property alias rotateDesigns: appearance.rotateDesigns
  property alias rotatedOnOverride: appearance.rotatedOnOverride
  readonly property alias configuredRotatedOn: appearance.configuredRotatedOn
  readonly property alias rotatedOn: appearance.rotatedOn
  property alias previewDesignId: preview.previewDesignId
  property alias previewTyped: preview.previewTyped
  property alias previewFailure: preview.previewFailure
  property alias previewUnlocking: preview.previewUnlocking
  readonly property alias userDesignsDir: designFiles.userDesignsDir
  property alias designsRevision: designFiles.designsRevision
  property alias userDesigns: designFiles.userDesigns
  readonly property alias pluginDir: desktop.pluginDir
  property alias shadowingDirs: desktop.shadowingDirs
  property alias rivalLockPlugins: desktop.rivalLockPlugins
  property alias rivalLockNotified: desktop.rivalLockNotified
  readonly property alias installablePackages: desktop.installablePackages
  readonly property alias doctorPath: desktop.doctorPath
  property alias terminalFallback: desktop.terminalFallback
  property alias movingCopies: desktop.movingCopies
  readonly property alias checkFaceAuthPath: desktop.checkFaceAuthPath
  readonly property alias checkFido2AuthPath: desktop.checkFido2AuthPath
  readonly property alias menuInstallPath: desktop.menuInstallPath
  readonly property alias barIconPath: desktop.barIconPath
  readonly property alias barIconShown: desktop.barIconShown
  readonly property alias safePathsLib: desktop.safePathsLib
  property alias menuEntryInstalled: desktop.menuEntryInstalled
  readonly property alias customizeScript: designFiles.customizeScript
  readonly property alias designerCreateScript: designFiles.designerCreateScript
  readonly property alias componentsDir: designFiles.componentsDir
  property alias components: designFiles.components
  property alias imagePickReopens: media.imagePickReopens
  property alias avatarPickReopens: media.avatarPickReopens
  readonly property alias detectAvatarScript: media.detectAvatarScript
  property alias videoPickReopens: media.videoPickReopens
  property alias videoPickTarget: media.videoPickTarget
  readonly property alias clipDesignScript: media.clipDesignScript
  readonly property alias deleteDesignScript: designFiles.deleteDesignScript
  readonly property alias deleteBootItemScript: boot.deleteBootItemScript
  property alias stingPlaying: media.stingPlaying
  property alias clipWallpaperOverride: media.clipWallpaperOverride
  readonly property alias configuredClipWallpaper: media.configuredClipWallpaper
  readonly property alias clipWallpaper: media.clipWallpaper
  property alias preparedClipWallpaper: media.preparedClipWallpaper
  readonly property alias clipWallScript: media.clipWallScript
  property alias bootOverride: boot.bootOverride
  readonly property alias configuredBoot: boot.configuredBoot
  readonly property alias bootSetting: boot.bootSetting
  property alias bootApplying: boot.bootApplying
  property alias bootApplyTarget: boot.bootApplyTarget
  property alias bootApplied: boot.bootApplied
  property alias bootAppliedVersion: boot.bootAppliedVersion
  readonly property alias bootTarget: boot.bootTarget
  property alias bootAppliedTheme: boot.bootAppliedTheme
  property alias bootCurrentTheme: boot.bootCurrentTheme
  property alias bootResyncOverride: boot.bootResyncOverride
  readonly property alias configuredBootResync: boot.configuredBootResync
  readonly property alias bootResync: boot.bootResync
  property alias bootLastBackground: boot.bootLastBackground
  property alias bootPreviewsVersion: boot.bootPreviewsVersion
  property alias bootPreviewsRunning: boot.bootPreviewsRunning
  property alias bootPreviewsPending: boot.bootPreviewsPending
  property alias bootVideos: boot.bootVideos
  property alias bootCustomDesigns: boot.bootCustomDesigns
  property alias bootClipSecondsOverride: boot.bootClipSecondsOverride
  readonly property alias configuredBootClipSeconds: boot.configuredBootClipSeconds
  readonly property alias bootClipSeconds: boot.bootClipSeconds
  property alias bootDesignPendingLoad: boot.bootDesignPendingLoad
  property alias bootSaveName: boot.bootSaveName
  property alias bootRotationOverride: boot.bootRotationOverride
  readonly property alias configuredBootRotation: boot.configuredBootRotation
  readonly property alias bootRotation: boot.bootRotation
  property alias bootRotateHelperInstalled: boot.bootRotateHelperInstalled
  property alias bootRotateRemovalAsked: boot.bootRotateRemovalAsked
  property alias bootRotateNext: boot.bootRotateNext
  property alias bootResyncArmed: boot.bootResyncArmed
  readonly property alias home: settingsStore.home
  readonly property alias stateHome: settingsStore.stateHome
  readonly property alias userName: settingsStore.userName
  readonly property alias currentBackgroundLink: settingsStore.currentBackgroundLink
  property alias lockRequested: sessionLock.lockRequested
  property alias pendingSessionLock: sessionLock.pendingSessionLock
  property alias authenticatingPassword: authentication.authenticatingPassword
  property alias fingerprintAuthenticating: authentication.fingerprintAuthenticating
  property alias faceAuthenticating: authentication.faceAuthenticating
  readonly property alias faceRetryLimit: authentication.faceRetryLimit
  property alias faceMisses: authentication.faceMisses
  property alias passwordPamConfigured: authentication.passwordPamConfigured
  property alias fingerprintConfigured: authentication.fingerprintConfigured
  property alias faceConfigured: authentication.faceConfigured
  property alias authMode: securityKey.authMode
  property alias authModeSettled: securityKey.authModeSettled
  property alias fido2Installed: securityKey.fido2Installed
  readonly property alias fido2Configured: securityKey.fido2Configured
  property alias fido2TokenPresent: securityKey.fido2TokenPresent
  property alias fido2Authenticating: securityKey.fido2Authenticating
  property alias fido2NeedsPin: securityKey.fido2NeedsPin
  property alias fido2Status: securityKey.fido2Status
  property alias fingerprintStatus: authentication.fingerprintStatus
  property alias fingerprintStatusIsError: authentication.fingerprintStatusIsError
  property alias fingerprintPendingStatus: authentication.fingerprintPendingStatus
  readonly property alias pamMessageMax: authentication.pamMessageMax
  property alias fido2Cue: securityKey.fido2Cue
  property alias fido2PinAttempts: securityKey.fido2PinAttempts
  property alias fido2PinSubmitted: securityKey.fido2PinSubmitted
  readonly property alias fido2PinAttemptLimit: securityKey.fido2PinAttemptLimit
  readonly property alias fido2NoTouchMs: securityKey.fido2NoTouchMs
  property alias fido2RoundStarted: securityKey.fido2RoundStarted
  readonly property alias fido2TouchRetryLimit: securityKey.fido2TouchRetryLimit
  property alias fido2TouchMisses: securityKey.fido2TouchMisses
  property alias fido2FailurePending: securityKey.fido2FailurePending
  readonly property alias fido2Exhausted: securityKey.fido2Exhausted
  readonly property alias fido2Active: securityKey.fido2Active
  property alias previewVisible: preview.previewVisible
  property alias enteredPassword: authentication.enteredPassword
  property alias pendingPassword: authentication.pendingPassword
  property alias failureMessage: authentication.failureMessage
  property alias failedAttempts: authentication.failedAttempts
  property alias backgroundPath: sessionLock.backgroundPath
  property alias backgroundVersion: sessionLock.backgroundVersion
  property alias lastEvent: sessionLock.lastEvent
  property alias lastEventAt: sessionLock.lastEventAt
  property alias strandedLock: sessionLock.strandedLock
  property alias strandedLockResolved: sessionLock.strandedLockResolved
  property alias unlocking: sessionLock.unlocking
  property alias clipUnlocking: sessionLock.clipUnlocking
  property alias unlockPlayback: sessionLock.unlockPlayback
  property alias unlockAuthorized: sessionLock.unlockAuthorized
  property alias previewClipPlaying: preview.previewClipPlaying
  property alias screenBlanked: sessionLock.screenBlanked
  property alias keyboardLayout: desktop.keyboardLayout
  property alias capsLock: desktop.capsLock
  readonly property alias capsProbeInterval: desktop.capsProbeInterval
  property alias lastCapsProbe: desktop.lastCapsProbe
  readonly property alias foreignLayout: desktop.foreignLayout
  property alias keyboardLayoutCount: desktop.keyboardLayoutCount
  property alias keyboardDevice: desktop.keyboardDevice
  property alias inputBlocked: sessionLock.inputBlocked
  property alias sessionLockXray: sessionLock.sessionLockXray
  property alias lockStateRevision: sessionLock.lockStateRevision
  readonly property alias locked: sessionLock.locked
  readonly property alias authenticating: authentication.authenticating
  property alias accountName: sessionLock.accountName
  readonly property alias lockClaimPath: sessionLock.lockClaimPath
  readonly property alias instanceToken: sessionLock.instanceToken
  readonly property alias holdsLock: sessionLock.holdsLock
  property alias fido2ProbeQueued: securityKey.fido2ProbeQueued
  property alias fido2ProbeReruns: securityKey.fido2ProbeReruns
  readonly property alias fido2ProbeRerunLimit: securityKey.fido2ProbeRerunLimit
  readonly property alias multimediaAvailable: media.multimediaAvailable
  property alias keyEventProbe: securityKey.keyEventProbe
  property alias keyInsertProbe: securityKey.keyInsertProbe
  readonly property alias themeColorProbe: desktop.themeColorProbe
  property alias explorerApi: explorerBridge.explorerApi
  function runPowerAction(action) { return lockPolicy.runPowerAction(action) }
  function setClipSpeed(v) { return media.setClipSpeed(v) }
  function setTwelveHour(v) { return appearance.setTwelveHour(v) }
  function setOpenAs(value) { return preferences.setOpenAs(value) }
  function setTourSeen(value) { return preferences.setTourSeen(value) }
  function pluginFlag(name) { return lockPolicy.pluginFlag(name) }
  function setPluginFlag(name, value) { return lockPolicy.setPluginFlag(name, value) }
  function setLockOnKeyRemoval(value) { return lockPolicy.setLockOnKeyRemoval(value) }
  function setWakeOnKeyInsert(value) { return lockPolicy.setWakeOnKeyInsert(value) }
  function setAwayReport(value) { return preferences.setAwayReport(value) }
  function awayFailures(unlockAt) { return preferences.awayFailures(unlockAt) }
  function sendAwayReport(times) { return preferences.sendAwayReport(times) }
  function setFavorite(id, on) { return appearance.setFavorite(id, on) }
  function toggleFavorite(id) { return appearance.toggleFavorite(id) }
  function fieldItemHidden(key) { return appearance.fieldItemHidden(key) }
  function setFieldItem(name, show) { return appearance.setFieldItem(name, show) }
  function t(text) { return appearance.t(text) }
  function setLanguage(value) { return appearance.setLanguage(value) }
  function setReduceMotion(value) { return appearance.setReduceMotion(value) }
  function setUiScale(value) { return appearance.setUiScale(value) }
  function configuredWallpaperOption(key, options) { return appearance.configuredWallpaperOption(key, options) }
  function setWallpaperOption(key, value, options) { return appearance.setWallpaperOption(key, value, options) }
  function setWallpaperBlur(value) { return appearance.setWallpaperBlur(value) }
  function setWallpaperDim(value) { return appearance.setWallpaperDim(value) }
  function setFido2Enabled(v) { return lockPolicy.setFido2Enabled(v) }
  function showsInput(screen) { return lockPolicy.showsInput(screen) }
  function pluginEntry() { return settingsStore.pluginEntry() }
  function writeEntry(entry) { return settingsStore.writeEntry(entry) }
  function settingKeys(entry) { return settingsStore.settingKeys(entry) }
  function saveSettingsBackup(entry) { return settingsStore.saveSettingsBackup(entry) }
  function restoreSettings() { return settingsStore.restoreSettings() }
  function applySettingsCopy(exitCode, text) { return settingsStore.applySettingsCopy(exitCode, text) }
  function addBarIconOnceOnFirstStart() { return settingsStore.addBarIconOnceOnFirstStart() }
  function setInputMonitor(name) { return lockPolicy.setInputMonitor(name) }
  function setUnlockAnimation(name) { return lockPolicy.setUnlockAnimation(name) }
  function setUnlockDuration(ms) { return lockPolicy.setUnlockDuration(ms) }
  function setMediaControls(value) { return appearance.setMediaControls(value) }
  function rememberThemeDesign(id) { return appearance.rememberThemeDesign(id) }
  function setFollowTheme(value) { return appearance.setFollowTheme(value) }
  function followThemeDesign() { return appearance.followThemeDesign() }
  function setOwnerMessage(value) { return appearance.setOwnerMessage(value) }
  function setRotateDesigns(value) { return appearance.setRotateDesigns(value) }
  function localDay() { return appearance.localDay() }
  function rotateDesign() { return appearance.rotateDesign() }
  function setPowerActions(value) { return lockPolicy.setPowerActions(value) }
  function setFaceStart(value) { return lockPolicy.setFaceStart(value) }
  function setWakeGrace(ms) { return lockPolicy.setWakeGrace(ms) }
  function setBlankDelay(ms) { return lockPolicy.setBlankDelay(ms) }
  function setKeepDisplayOn(on) { return lockPolicy.setKeepDisplayOn(on) }
  function rescanUserDesigns() { return designFiles.rescanUserDesigns() }
  function reloadDesigns() { return designFiles.reloadDesigns() }
  function shellQuote(text) { return desktop.shellQuote(text) }
  function openInTerminal(command, fallback) { return desktop.openInTerminal(command, fallback) }
  function installPackages(names) { return desktop.installPackages(names) }
  function moveCopies() { return desktop.moveCopies() }
  function runDoctor() { return desktop.runDoctor() }
  function setBarIcon(v) { return desktop.setBarIcon(v) }
  function refreshMenuEntry() { return desktop.refreshMenuEntry() }
  function setMenuEntry(v) { return desktop.setMenuEntry(v) }
  function customizeDesign(id) { return designFiles.customizeDesign(id) }
  function createDesignerDesign(content) { return designFiles.createDesignerDesign(content) }
  function rescanComponents() { return designFiles.rescanComponents() }
  function saveComponent(slug, json) { return designFiles.saveComponent(slug, json) }
  function deleteComponent(slug) { return designFiles.deleteComponent(slug) }
  function pickImage(reopenExplorer) { return media.pickImage(reopenExplorer) }
  function setAvatar(path) { return media.setAvatar(path) }
  function clearAvatar() { return media.clearAvatar() }
  function resetAvatar() { return media.resetAvatar() }
  function detectAvatar() { return media.detectAvatar() }
  function pickAvatar(reopenExplorer) { return media.pickAvatar(reopenExplorer) }
  function setVideo(path) { return media.setVideo(path) }
  function clearVideo() { return media.clearVideo() }
  function setSting(path) { return media.setSting(path) }
  function clearSting() { return media.clearSting() }
  function setStingVolume(value) { return media.setStingVolume(value) }
  function pickVideo(reopenExplorer, target) { return media.pickVideo(reopenExplorer, target) }
  function createClipDesign(path) { return media.createClipDesign(path) }
  function fileItemNameValid(n) { return designFiles.fileItemNameValid(n) }
  function layoutNameValid(n) { return designFiles.layoutNameValid(n) }
  function bootItemValid(v) { return designFiles.bootItemValid(v) }
  function deleteDesign(id) { return designFiles.deleteDesign(id) }
  function deleteBootItem(id) { return boot.deleteBootItem(id) }
  function playSting() { return media.playSting() }
  function endSting() { return media.endSting() }
  function setClipWallpaper(on) { return media.setClipWallpaper(on) }
  function prepareClipWallpaper(path) { return media.prepareClipWallpaper(path) }
  function commitClipWallpaper() { return media.commitClipWallpaper() }
  function setBoot(value) { return boot.setBoot(value) }
  function applyBoot(force, explicitTarget) { return boot.applyBoot(force, explicitTarget) }
  function setBootResync(on) { return boot.setBootResync(on) }
  function maybeResyncBoot() { return boot.maybeResyncBoot() }
  function refreshBootPreviews() { return boot.refreshBootPreviews() }
  function refreshBootLists() { return boot.refreshBootLists() }
  function setBootClipSeconds(n) { return boot.setBootClipSeconds(n) }
  function loadBootDesign(name) { return boot.loadBootDesign(name) }
  function saveBootDesign(name, content) { return boot.saveBootDesign(name, content) }
  function createBootDesign() { return boot.createBootDesign() }
  function toggleBootRotation(id) { return boot.toggleBootRotation(id) }
  function applyBootSnapshot(id, persist, entryRect) { return boot.applyBootSnapshot(id, persist, entryRect) }
  function enableBootRotation() { return boot.enableBootRotation() }
  function askBootRotationHelperRemoval() { return boot.askBootRotationHelperRemoval() }
  function removeBootRotationHelper() { return boot.removeBootRotationHelper() }
  function maybeRotateBoot() { return boot.maybeRotateBoot() }
  function setDesign(id, how) { return appearance.setDesign(id, how) }
  function pamMessageText(raw) { return authentication.pamMessageText(raw) }
  function handleFingerprintMessage() { return authentication.handleFingerprintMessage() }
  function clearFingerprintStatus() { return authentication.clearFingerprintStatus() }
  function probeCapsLock() { return desktop.probeCapsLock() }
  function switchKeyboardLayout() { return desktop.switchKeyboardLayout() }
  function refreshKeyboardLayout() { return desktop.refreshKeyboardLayout() }
  function refreshLockState() { return sessionLock.refreshLockState() }
  function realScreenCount() { return sessionLock.realScreenCount() }
  function hasRealScreen() { return sessionLock.hasRealScreen() }
  function queueSessionLock() { return sessionLock.queueSessionLock() }
  function requestSessionLock() { return sessionLock.requestSessionLock() }
  function checkStrandedLock() { return sessionLock.checkStrandedLock() }
  function recoverStrandedLock() { return sessionLock.recoverStrandedLock() }
  function refreshBackground() { return desktop.refreshBackground() }
  function refreshFingerprintStatus() { return authentication.refreshFingerprintStatus() }
  function refreshFaceStatus() { return authentication.refreshFaceStatus() }
  function refreshFido2Status() { return sessionLock.refreshFido2Status() }
  function refreshSessionLockXray() { return sessionLock.refreshSessionLockXray() }
  function logEvent(event) { return sessionLock.logEvent(event) }
  function resetAuthenticationState() { return sessionLock.resetAuthenticationState() }
  function beginLock() { return sessionLock.beginLock() }
  function finishUnlock() { return sessionLock.finishUnlock() }
  function releaseLock() { return sessionLock.releaseLock() }
  function cancelUnlockAnimation() { return sessionLock.cancelUnlockAnimation() }
  function armBlankTimer() { return sessionLock.armBlankTimer() }
  function runWake() { return sessionLock.runWake() }
  function runBlank() { return sessionLock.runBlank() }
  function submitPassword(value) { return authentication.submitPassword(value) }
  function respondToPasswordPrompt() { return authentication.respondToPasswordPrompt() }
  function handlePasswordFailure() { return authentication.handlePasswordFailure() }
  function startFingerprint() { return authentication.startFingerprint() }
  function handleFingerprintFinished(result) { return authentication.handleFingerprintFinished(result) }
  function startFace() { return authentication.startFace() }
  function retryFido2() { return securityKey.retryFido2() }
  function retryFace() { return authentication.retryFace() }
  function stopFace() { return authentication.stopFace() }
  function handleFaceFinished(result) { return authentication.handleFaceFinished(result) }
  function faceMissed() { return authentication.faceMissed() }
  function settleAuthMode() { return securityKey.settleAuthMode() }
  function setAuthMode(mode) { return securityKey.setAuthMode(mode) }
  function requestFido2() { return securityKey.requestFido2() }
  function startFido2() { return securityKey.startFido2() }
  function abortFido2() { return securityKey.abortFido2() }
  function handleFido2Message() { return securityKey.handleFido2Message() }
  function submitFido2Pin(pin) { return securityKey.submitFido2Pin(pin) }
  function handleFido2Finished(result) { return securityKey.handleFido2Finished(result) }
  function fido2FailureChecked() { return securityKey.fido2FailureChecked() }
  function countFido2Failure() { return securityKey.countFido2Failure() }
  function publishExplorerApi() { return explorerBridge.publishExplorerApi() }
  function retireExplorerApi() { return explorerBridge.retireExplorerApi() }
  function watchLaunchOsd() { return explorerBridge.watchLaunchOsd() }
  function summonExplorer(view) { return explorerBridge.summonExplorer(view) }
  readonly property alias barIconApplyProc: desktop.barIconApplyProc
  readonly property alias barIconFirstStartRetryTimer: settingsStore.barIconFirstStartRetryTimer
  readonly property alias blankCrashCheckProc: sessionLock.blankCrashCheckProc
  readonly property alias bootBgResyncTimer: boot.bootBgResyncTimer
  readonly property alias duplicatePluginProc: desktop.duplicatePluginProc
  readonly property alias facePam: authentication.facePam
  readonly property alias faceRetryTimer: authentication.faceRetryTimer
  readonly property alias fido2CheckProc: securityKey.fido2CheckProc
  readonly property alias fingerprintPam: authentication.fingerprintPam
  readonly property alias fingerprintRetryTimer: authentication.fingerprintRetryTimer
  readonly property alias idleBlankTimer: sessionLock.idleBlankTimer
  readonly property alias localSettings: settingsStore.localSettings
  readonly property alias lockClaim: sessionLock.lockClaim
  readonly property alias passwordPam: authentication.passwordPam
  readonly property alias previewFailureTimer: preview.previewFailureTimer
  readonly property alias previewUnlockTimer: preview.previewUnlockTimer
  readonly property alias rivalLockCheckTimer: desktop.rivalLockCheckTimer
  readonly property alias sessionLock: sessionLock.sessionLock
  readonly property alias settingsRestoreTimer: settingsStore.settingsRestoreTimer
  readonly property alias strandedLockRetryTimer: sessionLock.strandedLockRetryTimer
  readonly property alias themeBackgroundTimer: desktop.themeBackgroundTimer

  onDisplayBlankingSuppressedChanged: {
    // The one-shot blank timer may already have fired while HDMI was present.
    // Start a fresh delay on disconnect (or when the option is turned off).
    if (lockRequested && !displayBlankingSuppressed) armBlankTimer()
  }
  // The entry may load after the theme name did; the check runs again then.
  onConfiguredFollowThemeChanged: followThemeDesign()

  signal designCustomized(string id, string path)

  // ---------------------------------------------------------------- designer
  //
  // The visual designer writes ordinary designs into the same folder; a
  // layout comment at the top is what tells it apart, and is what lets the
  // designer open one again. Explorer.qml owns the editing, the service owns
  // the files.

  signal designerDesignCreated(string id, string path)

  // The file dialog again, for the designer's Image piece. Same dance as the
  // avatar: the explorer steps aside while it is up.
  signal imagePicked(string path)

  // A picked video becomes a one-line ClipDesign in ~/.config/omarchy/lock-designs,
  // with the file itself copied to ~/.config/omarchy/lock-videos where ClipDesign
  // resolves clips from. Same freeze-then-play-on-unlock behavior as Storm.
  signal clipDesignAdded(string id)

  // Snapshot boot screens can't be re-baked from the old picture: the theme
  // change moved the wallpaper and colors, so the explorer has to take a
  // fresh snapshot (which also carries the entry geometry).
  signal bootResnapshotRequested(string designId, bool persist)
  signal exploreTabRequested(string tab)
  signal exploreViewRequested(string view)

  onBackgroundPathChanged: {
    if (backgroundPath.length === 0) return
    if (bootLastBackground.length === 0) { bootLastBackground = backgroundPath; return }
    if (bootLastBackground === backgroundPath) return
    bootLastBackground = backgroundPath
    if (!bootResync || !bootResyncArmed) return
    if (bootApplied.indexOf("snapshot:") !== 0) return
    root.bootBgResyncTimer.restart()
  }

  // Plumbing for the boot layout editor in the explorer.
  signal bootDesignLoaded(string name, string content)

  onHoldsLockChanged: if (!holdsLock) root.lockClaim.setText("")
  onThemeColorProbeChanged: root.themeBackgroundTimer.restart()

  onAuthenticatingPasswordChanged: {
    if (!lockRequested) return
    if (authenticatingPassword) root.idleBlankTimer.stop()
    else armBlankTimer()
  }

  // No lock before PAM is known good. An answer from before then may be stale --
  // the failsafe can be cleared from a TTY -- so re-ask rather than act on it.
  onPasswordPamConfiguredChanged: {
    if (!passwordPamConfigured) return

    strandedLock = false
    strandedLockResolved = false
    root.strandedLockRetryTimer.rearm()
    checkStrandedLock()
  }

  Component.onCompleted: {
    publishExplorerApi()
    refreshMenuEntry()
    refreshBackground()
    refreshFingerprintStatus()
    refreshFaceStatus()
    refreshFido2Status()
    refreshSessionLockXray()
    rescanUserDesigns()
    detectAvatar()
    root.blankCrashCheckProc.running = true
    root.duplicatePluginProc.running = true
    root.rivalLockCheckTimer.start()
    checkStrandedLock()
    root.settingsRestoreTimer.start()
    root.barIconFirstStartRetryTimer.start()
  }

  Component.onDestruction: retireExplorerApi()
}
