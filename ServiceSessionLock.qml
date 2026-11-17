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
  readonly property alias blankCrashCheckProc: blankCrashCheckProc
  readonly property alias idleBlankTimer: idleBlankTimer
  readonly property alias lockClaim: lockClaim
  readonly property alias sessionLock: sessionLock
  readonly property alias strandedLockRetryTimer: strandedLockRetryTimer


  property bool lockRequested: false
  property bool pendingSessionLock: false
  property string backgroundPath: ""
  property int backgroundVersion: 0
  property string lastEvent: "init"
  property string lastEventAt: ""
  property bool strandedLock: false
  property bool strandedLockResolved: false
  property bool unlocking: false
  // The clip designs (Storm, Eyes, ...) hold the lock surface while their
  // video plays through as the unlock. unlockPlayback reaches the design,
  // clipUnlocking is the hold, clipFailsafe the way out if the file misbehaves.
  property bool clipUnlocking: false
  property bool unlockPlayback: false
  // Set only by finishUnlock, which only a successful password, fingerprint,
  // face or security-key check reaches; releaseLock drops the session lock
  // for nothing else. A design says when its unlock clip is done, and a user
  // design is arbitrary QML: its word must never be enough on its own.
  property bool unlockAuthorized: false
  // Nothing should decode video into a screen that is switched off.
  property bool screenBlanked: false

  // Keys pressed into a dark panel only wake it: the field stays inert until
  // the wake has run and the panel has had wakeInputGrace to light up, so the
  // keystrokes that switched the screen on never land in the password.
  property bool inputBlocked: false

  // With `misc:session_lock_xray` the compositor keeps drawing the desktop
  // under the lock surface, so the unlock fades straight into it and the
  // wallpaper the animation otherwise lands on would only be in the way.
  property bool sessionLockXray: false

  // Quickshell 0.3.2 omits lockStateChanged on normal unlock. Re-read
  // the native properties after release rather than retaining a stale binding.
  property int lockStateRevision: 0
  readonly property bool locked: {
    root.lockStateRevision
    return root.lockRequested || sessionLock.locked || sessionLock.secure
  }

  function refreshLockState() {
    root.lockStateRevision += 1
  }

  function realScreenCount() {
    var screens = Quickshell.screens || []
    var count = 0

    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i]
      if (screen && screen.name && screen.width > 0 && screen.height > 0) count += 1
    }

    return count
  }

  function hasRealScreen() {
    return root.realScreenCount() > 0
  }

  function queueSessionLock() {
    root.pendingSessionLock = true
    if (!sessionLockStabilizeTimer.running) root.logEvent("lock-pending: screen-stabilizing")
    sessionLockStabilizeTimer.restart()
    if (!pendingSessionLockTimer.running) pendingSessionLockTimer.start()
  }

  function requestSessionLock() {
    // Only this copy's own request counts. `secure` can already be true with
    // no surface of ours -- a copy of this service that held the lock was
    // reloaded away, and Hyprland is showing its crashed-lock screen -- and
    // waiting on it then leaves that screen up for good.
    if (!root.lockRequested || sessionLock.locked) return
    if (sessionLockStabilizeTimer.running) return

    if (!root.hasRealScreen()) {
      if (!root.pendingSessionLock || root.lastEvent !== "lock-pending: no-real-screen") root.logEvent("lock-pending: no-real-screen")
      root.pendingSessionLock = true
      if (!pendingSessionLockTimer.running) pendingSessionLockTimer.start()
      return
    }

    root.pendingSessionLock = false
    pendingSessionLockTimer.stop()
    sessionLock.locked = true
  }

  // ext-session-lock outlives its client, and a restart carries no lock over, so
  // a session locked this early is an orphan behind Hyprland's failsafe. Outputs
  // are often still absent here, so ask until the answer means something.
  function checkStrandedLock() {
    if (root.strandedLockResolved || strandedLockCheckProc.running) return

    // A lock this shell took is nobody's orphan.
    if (root.locked || root.lockRequested) {
      root.strandedLockResolved = true
      return
    }

    strandedLockCheckProc.running = true
  }

  // Which copy of this service holds the lock. Omarchy hot-reloads a local
  // plugin when its files change and can run the new copy next to the old one
  // for a while; a lock the old copy holds is not an orphan, and locking again
  // from the new one leaves a second lock that never comes up. The holder says
  // so once a second in this file; a check that finds the session locked and
  // the claim fresh and someone else's waits, and takes over only once the
  // claim goes stale -- the holder gone with the session still locked.
  // The account's full name, for the designs' greetings (DesignBase.displayName).
  property string accountName: ""
  Process {
    id: accountNameProc
    running: true
    command: ["bash", "-c", "getent passwd -- \"$(id -un)\" | cut -d: -f5 | cut -d, -f1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.accountName = String(text || "").trim().substring(0, 80)
    }
  }

  readonly property string lockClaimPath: (Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("HOME") + "/.cache")) + "/omarchy-lock-explorer.lock-held"
  readonly property string instanceToken: String(Date.now()) + "-" + String(Math.floor(Math.random() * 1e9))
  readonly property bool holdsLock: {
    root.lockStateRevision
    return sessionLock.locked || sessionLock.secure
  }

  FileView {
    id: lockClaim
    path: root.lockClaimPath
    // Written, never read here.
    preload: false
    atomicWrites: true
    printErrors: false
  }

  Timer {
    id: lockClaimHeartbeat
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.holdsLock
    onTriggered: lockClaim.setText(root.instanceToken + "\n")
  }

  // A claim that was fresh: ask again until it is released or goes stale.
  Timer {
    id: strandedDeferTimer
    interval: 1500
    onTriggered: root.checkStrandedLock()
  }

  function recoverStrandedLock() {
    if (!root.strandedLock || root.locked || !root.passwordPamConfigured) return

    root.strandedLock = false
    root.logEvent("lock-stranded: recovering")
    root.beginLock()
  }
  function refreshFido2Status() {
    if (root.fido2CheckProc.running) root.fido2ProbeQueued = true
    else root.fido2CheckProc.running = true
  }

  function refreshSessionLockXray() {
    if (!sessionLockXrayProc.running) sessionLockXrayProc.running = true
  }

  function logEvent(event) {
    root.lastEvent = event
    root.lastEventAt = new Date().toISOString()
    console.log("omarchy lock " + root.lastEventAt + " " + event)
  }

  function resetAuthenticationState() {
    root.enteredPassword = ""
    root.pendingPassword = ""
    root.failureMessage = ""
    root.failedAttempts = 0
    root.failureTimes = []
    root.fido2FailurePending = false
    root.authenticatingPassword = false
    root.fingerprintAuthenticating = false
    root.fingerprintRetryTimer.stop()
    root.clearFingerprintStatus()
    root.faceMisses = 0
    root.faceRetryTimer.stop()
    if (root.passwordPam.active) root.passwordPam.abort()
    if (root.fingerprintPam.active) root.fingerprintPam.abort()
    if (root.facePam.active) root.facePam.abort()
    root.abortFido2()
    root.fido2PinAttempts = 0
    root.fido2PinSubmitted = false
    root.fido2TouchMisses = 0
    root.authMode = "password"
    root.authModeSettled = false
  }

  function beginLock() {
    if (!root.passwordPamConfigured) {
      root.logEvent("lock-denied: missing-pam")
      return false
    }

    root.rotateDesign()
    root.cancelUnlockAnimation()
    root.resetAuthenticationState()
    root.inputBlocked = false
    inputUnblockTimer.stop()
    root.lockRequested = true
    root.lockedAt = Date.now()
    root.lastFaceRound = 0
    root.armBlankTimer()
    root.logEvent("lock-requested")
    root.queueSessionLock()

    Qt.callLater(function() {
      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.refreshFaceStatus()
      root.refreshFido2Status()
      root.refreshKeyboardLayout()
      root.refreshSessionLockXray()
      root.rescanUserDesigns()
      // The frame is ready before the unlock needs it.
      if (root.designHasClip) root.prepareClipWallpaper(root.designClipPath)
      else if (root.stingPath.length > 0) root.prepareClipWallpaper(root.stingPath)
    })

    return true
  }

  function finishUnlock() {
    if (!root.locked && !root.lockRequested) return
    if (root.unlocking || root.clipUnlocking) return
    root.unlockAuthorized = true

    var away = root.awayReport ? root.awayFailures(Date.now()) : []
    root.pendingAwayReport = away.length > 0 ? away : null
    root.lockRequested = false
    root.pendingSessionLock = false
    sessionLockStabilizeTimer.stop()
    pendingSessionLockTimer.stop()
    root.resetAuthenticationState()
    idleBlankTimer.stop()
    root.runWake()

    // The surface has to stay up while it animates away -- dropping the lock
    // first takes the screen with it. The timer also releases the lock if the
    // animation never runs, so nothing can leave the session stuck behind it.
    // A clip design keeps the surface and plays its video as the unlock. The
    // design says when it is done; the failsafe does not care what it thinks.
    // Without qt6-multimedia a clip design has already fallen back to
    // Classic, so unlock instantly instead of waiting on the clip failsafe.
    // Reduce motion means no moving unlock either: no clip, no animation.
    if (root.designHasClip && root.multimediaAvailable && !root.motionReduced && (sessionLock.locked || sessionLock.secure)) {
      root.clipUnlocking = true
      root.unlockPlayback = true
      clipFailsafe.restart()
      // Second chance for designs picked while already locked.
      if (root.preparedClipWallpaper.length === 0) root.prepareClipWallpaper(root.designClipPath)
      root.logEvent("unlocking=clip")
      return
    }

    if (root.unlockAnimated && !root.motionReduced && (sessionLock.locked || sessionLock.secure)) {
      root.unlocking = true
      root.logEvent("unlocking=" + root.unlockAnimation)
      unlockTimer.restart()
      return
    }

    root.releaseLock()
  }

  function releaseLock() {
    if (!root.unlockAuthorized) {
      root.logEvent("unlock-refused (no authentication)")
      return
    }
    root.unlockAuthorized = false
    unlockTimer.stop()
    clipFailsafe.stop()
    var hadClip = root.clipUnlocking
    root.clipUnlocking = false
    root.unlockPlayback = false
    root.unlocking = false
    sessionLock.locked = false
    root.refreshLockState()
    root.logEvent("unlocked")
    if (root.pendingAwayReport) root.sendAwayReport(root.pendingAwayReport)
    root.pendingAwayReport = null
    // The clip was the whole show, no second video on top of it; and none at
    // all while motion is reduced.
    if (hadClip) root.commitClipWallpaper()
    else if (!root.motionReduced) root.playSting()
    // Asked for while the screen was locked: now the dialog can show.
    Qt.callLater(root.askBootRotationHelperRemoval)
  }

  function cancelUnlockAnimation() {
    if (!root.unlocking && !root.clipUnlocking) return
    root.unlockAuthorized = false
    unlockTimer.stop()
    clipFailsafe.stop()
    root.unlocking = false
    root.clipUnlocking = false
    root.unlockPlayback = false
    root.logEvent("unlock-cancelled")
  }

  function armBlankTimer() {
    idleBlankTimer.armedAt = Date.now()
    idleBlankTimer.restart()
  }

  function runWake() {
    var wasBlanked = root.screenBlanked
    root.screenBlanked = false
    // A panel coming back is the moment to look: the lid just opened, or
    // somebody touched the machine. Locking with the screen already on is
    // not, unless the setting says otherwise.
    if (root.lockRequested && sessionLock.secure && root.faceStart !== "off") {
      var now = Date.now()
      if (wasBlanked
          || (root.faceStart === "wake" && now - root.lockedAt > root.faceWakeQuiet && now - root.lastFaceRound > root.faceRoundGap))
        Qt.callLater(root.retryFace)
    }
    if (wasBlanked && root.lockRequested && sessionLock.secure) Qt.callLater(root.retryFido2)
    // Failsafe: a wake that never exits must not leave the field inert.
    if (root.inputBlocked && !inputUnblockTimer.running) {
      inputUnblockTimer.interval = 3000
      inputUnblockTimer.restart()
    }
    if (!wakeProcess.running) wakeProcess.running = true
    if (root.lockRequested) root.armBlankTimer()
  }

  function runBlank() {
    if (root.keepDisplayOn) return
    root.screenBlanked = !root.displayBlankingSuppressed
    root.inputBlocked = root.screenBlanked
    inputUnblockTimer.stop()
    // Nothing to authenticate to while the panel is dark: drop the scan and
    // let go of the camera until it comes back.
    if (root.screenBlanked) root.stopFace()
    if (!blankProcess.running) blankProcess.running = true
  }

  WlSessionLock {
    id: sessionLock

    locked: false

    onSecureStateChanged: {
      // The native manager finishes changing its state after this signal.
      Qt.callLater(root.refreshLockState)
      root.logEvent("secure=" + secure)
      if (secure) {
        root.pendingSessionLock = false
        sessionLockStabilizeTimer.stop()
        pendingSessionLockTimer.stop()
        root.startFingerprint()
        if (root.faceStart === "always") root.startFace()
        root.startFido2()
      }
    }

    onLockStateChanged: {
      root.refreshLockState()
      root.logEvent("session-locked=" + locked)

      if (locked) {
        root.pendingSessionLock = false
        sessionLockStabilizeTimer.stop()
        pendingSessionLockTimer.stop()
      }

      if (!locked && root.lockRequested) {
        root.lockRequested = false
        root.pendingSessionLock = false
        sessionLockStabilizeTimer.stop()
        pendingSessionLockTimer.stop()
        root.resetAuthenticationState()
        root.runWake()
      }
    }

    WlSessionLockSurface {
      id: lockSurface
      color: Commons.Color.background

      UnlockLayer {
        anchors.fill: parent
        animation: root.unlockAnimation
        duration: root.unlockDuration
        active: root.unlocking
        backgroundUrl: root.locked && !root.sessionLockXray ? root.backgroundUrl : ""

        LockHost {
          id: lockView
          anchors.fill: parent
          fadeIn: true
          designId: root.showsInput(lockSurface.screen) ? root.designId : "companion"
          revision: root.designsRevision
          userDesigns: root.userDesigns
          backgroundPath: root.backgroundPath
          backgroundVersion: root.backgroundVersion
          avatarPath: root.avatarPath
          avatarVersion: root.avatarVersion
          fingerprintConfigured: root.fingerprintConfigured
          keyboardLayout: root.keyboardLayout
          keyboardLayoutCount: root.keyboardLayoutCount
          batteryLow: root.batteryLow
          batteryPercent: root.batteryPercent
          ownerMessage: root.ownerMessage
          onLayoutSwitchRequested: root.switchKeyboardLayout()
          capsLock: root.capsLock
          onCapsProbeRequested: root.probeCapsLock()
          powerActions: root.powerActions
          mediaControls: root.mediaControls && root.showsInput(lockSurface.screen)
          onPowerActionRequested: function(action) { root.runPowerAction(action) }
          faceConfigured: root.faceConfigured
          fido2Configured: root.fido2Configured
          fido2Active: root.fido2Active
          fido2Authenticating: root.fido2Authenticating
          fido2NeedsPin: root.fido2NeedsPin
          fido2Status: root.fido2Status
          fingerprintStatus: root.fingerprintStatus
          fingerprintStatusIsError: root.fingerprintStatusIsError
          authenticatingPassword: root.authenticatingPassword
          failureMessage: root.failureMessage
          failedAttempts: root.failedAttempts
          inputEnabled: root.lockRequested
          inputBlocked: root.inputBlocked
          loadBackground: root.locked
          passwordText: root.enteredPassword
          videoPath: root.videoPath
          videoPlaying: root.locked && !root.screenBlanked
          screenAwake: !root.screenBlanked
          unlockPlayback: root.unlockPlayback && root.showsInput(lockSurface.screen)
          clipSpeed: root.clipSpeed
          twelveHour: root.twelveHour
          wallpaperBlur: root.wallpaperBlurValue
          wallpaperDim: root.wallpaperDimShift
          uiScale: root.uiScale
          holdStill: root.motionReduced
          language: root.language
          fullName: root.accountName
          showLayoutBadge: root.showLayoutBadge
          showCapsBadge: root.showCapsBadge
          allowPasswordToggle: root.allowPasswordToggle
          showAuthIcons: root.showAuthIcons
          // Only ends a clip unlock that authentication started.
          onUnlockFinished: if (root.clipUnlocking) root.releaseLock()
          onPasswordTextEdited: function(password) { root.enteredPassword = password }
          onSubmitPassword: function(password) { root.submitPassword(password) }
          onClearFailureRequested: root.failureMessage = ""
          onWakeRequested: root.runWake()
          onFaceRequested: root.retryFace()
          onFido2Requested: root.requestFido2()
          onPasswordRequested: root.setAuthMode("password")
          onSubmitFido2Pin: function(pin) { root.submitFido2Pin(pin) }
        }
      }
    }
  }

  Timer {
    id: unlockTimer
    interval: Math.max(1, root.unlockDuration + 80)
    repeat: false
    onTriggered: root.releaseLock()
  }

  // However long the clip claims to be, the screen comes back.
  Timer {
    id: clipFailsafe
    interval: 15000
    repeat: false
    onTriggered: root.releaseLock()
  }

  Process {
    id: sessionLockXrayProc
    command: ["hyprctl", "getoption", "misc:session_lock_xray", "-j"]
    stdout: StdioCollector {
      id: sessionLockXrayOut
      waitForEnd: true
      onStreamFinished: {
        try {
          root.sessionLockXray = JSON.parse(String(sessionLockXrayOut.text || "{}")).bool === true
        } catch (e) {
          root.sessionLockXray = false
        }
      }
    }
  }

  Process {
    id: strandedLockCheckProc
    // 0 locked and nobody holds it, 1 not locked, 2 no answer yet,
    // 3 locked and another copy of this service still holds it.
    command: ["bash", "-c",
      "omarchy-hyprland-session-locked || exit $?; " +
      "[[ -s $1 ]] || exit 0; " +
      "[[ $(head -n1 -- \"$1\") == \"$2\" ]] && exit 0; " +
      "age=$(( $(date +%s) - $(stat -c %Y -- \"$1\") )); " +
      "(( age <= 2 )) && exit 3; exit 0",
      "bash", root.lockClaimPath, root.instanceToken]
    onExited: function(exitCode) {
      // No output to read the lock off yet.
      if (exitCode === 2) return

      if (exitCode === 3) {
        if (root.lastEvent !== "lock-held-elsewhere: waiting") root.logEvent("lock-held-elsewhere: waiting")
        strandedDeferTimer.restart()
        return
      }

      root.strandedLockResolved = true

      // A lock taken while this was in flight is this shell's own.
      root.strandedLock = exitCode === 0 && !root.locked && !root.lockRequested
      root.recoverStrandedLock()
    }
  }

  Process {
    id: wakeProcess
    command: ["bash", "-c", "rm -f \"$1/display-off\"; omarchy-system-wake", "bash", root.blankMarkerDir]
    onExited: {
      if (!root.inputBlocked || root.screenBlanked) return
      inputUnblockTimer.interval = root.wakeInputGrace
      inputUnblockTimer.restart()
    }
  }

  Timer {
    id: inputUnblockTimer
    repeat: false
    onTriggered: if (!root.screenBlanked) root.inputBlocked = false
  }

  Process {
    id: blankProcess
    // The marker goes down before the display does: the shell can be gone
    // within two seconds of the output dropping.
    command: ["bash", "-c", root.displayBlankingSuppressed
      ? "omarchy-brightness-keyboard off"
      : "mkdir -p \"$1\" && : > \"$1/display-off\"; omarchy-brightness-keyboard off; omarchy-brightness-display off",
      "bash", root.blankMarkerDir]
  }

  // Runs once at startup. A display-off marker still there means the last
  // shell never reached a wake; it is kept as blank-crashed so every later
  // relaunch in this login sees it too (the runtime dir goes with the login).
  Process {
    id: blankCrashCheckProc
    command: ["bash", "-c",
      "[[ -e $1/display-off ]] && mv -f \"$1/display-off\" \"$1/blank-crashed\"; [[ -e $1/blank-crashed ]]",
      "bash", root.blankMarkerDir]
    onExited: function(exitCode) {
      if (exitCode !== 0) return
      root.blankCrashed = true
      root.logEvent("blank-crashed: keeping displays on for this login")
    }
  }

  Timer {
    id: idleBlankTimer
    interval: root.blankDelay
    repeat: false
    property double armedAt: 0
    onTriggered: {
      // A countdown frozen by suspend fires right after resume, which would
      // blank the freshly woken unlock screen under the user. Wall-clock time
      // exposes the gap: take a fresh run-up instead of blanking.
      if (Date.now() - armedAt > interval + 2000) {
        root.armBlankTimer()
        return
      }
      // Only a password check in flight should hold the display up. The
      // fingerprint PAM stays armed for the whole lock, so gating on
      // `authenticating` here would keep the panel lit until unlock.
      if (root.lockRequested && !root.authenticatingPassword) root.runBlank()
    }
  }

  Timer {
    id: sessionLockStabilizeTimer
    interval: 500
    repeat: false
    onTriggered: root.requestSessionLock()
  }

  Timer {
    id: pendingSessionLockTimer
    interval: 100
    repeat: true
    onTriggered: root.requestSessionLock()
  }

  Timer {
    id: strandedLockRetryTimer
    interval: 500
    repeat: true
    // Covers the compositor settling; screens coming back re-arm it.
    readonly property int budget: 20
    property int remaining: 20
    running: !root.strandedLockResolved && remaining > 0

    function rearm() {
      if (!root.strandedLockResolved) remaining = budget
    }

    onTriggered: {
      remaining -= 1
      root.checkStrandedLock()
    }
  }

  Connections {
    target: Quickshell
    function onScreensChanged() {
      root.requestSessionLock()

      // A monitor still coming up has no workspace, so cannot answer yet.
      strandedLockRetryTimer.rearm()
      root.checkStrandedLock()
    }
  }
}
