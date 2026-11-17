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
  readonly property alias facePam: facePam
  readonly property alias faceRetryTimer: faceRetryTimer
  readonly property alias fingerprintPam: fingerprintPam
  readonly property alias fingerprintRetryTimer: fingerprintRetryTimer
  readonly property alias passwordPam: passwordPam

  property bool authenticatingPassword: false
  property bool fingerprintAuthenticating: false
  property bool faceAuthenticating: false
  // Face retries on its own after a miss, but not forever: a camera that
  // errors out at once would otherwise spin the PAM stack four times a
  // second for as long as the screen stays locked. Enter on an empty field
  // or the face button starts a fresh round.
  readonly property int faceRetryLimit: 5
  property int faceMisses: 0
  property bool passwordPamConfigured: false
  property bool fingerprintConfigured: false
  property bool faceConfigured: false
  // What the fingerprint reader is saying, in pam_fprintd's own words: "Place
  // your finger on the fingerprint reader", "Failed to match fingerprint".
  // Empty while no scan is running. The fido2Status of the fingerprint path.
  property string fingerprintStatus: ""
  property bool fingerprintStatusIsError: false
  property string fingerprintPendingStatus: ""

  // A failed match is followed within a moment by the next attempt's prompt,
  // which would wipe it before anyone could read it. It is held on screen for
  // a beat, with the prompt that arrives meanwhile queued behind it. None of
  // it wakes the display: the prompt repeats after every attempt, and
  // pam_fprintd reports its own periodic timeout as an error too, so waking
  // on either would keep a blanked screen lit for as long as it is locked.
  // What a PAM module says is shown on the lock screen, so it is treated as
  // foreign text: the first line only, capped, and every design renders it as
  // PlainText. A module that sends markup, a novel or a screenful of newlines
  // cannot reshape the lock screen with it.
  readonly property int pamMessageMax: 120

  function pamMessageText(raw) {
    var text = String(raw || "").replace(/\s+/g, " ").trim()
    return text.length > root.pamMessageMax ? text.substring(0, root.pamMessageMax - 1) + "…" : text
  }

  function handleFingerprintMessage() {
    if (!root.lockRequested) return
    var text = root.pamMessageText(fingerprintPam.message)
    if (text.length === 0) return
    if (fingerprintPam.messageIsError) {
      root.fingerprintPendingStatus = ""
      root.fingerprintStatus = text
      root.fingerprintStatusIsError = true
      fingerprintErrorHold.restart()
      return
    }
    if (fingerprintErrorHold.running) {
      root.fingerprintPendingStatus = text
      return
    }
    root.fingerprintStatus = text
    root.fingerprintStatusIsError = false
  }

  function clearFingerprintStatus() {
    fingerprintErrorHold.stop()
    root.fingerprintPendingStatus = ""
    root.fingerprintStatus = ""
    root.fingerprintStatusIsError = false
  }
  property string enteredPassword: ""
  property string pendingPassword: ""
  property string failureMessage: ""
  property int failedAttempts: 0
  readonly property bool authenticating: root.authenticatingPassword || root.fingerprintAuthenticating || root.faceAuthenticating || root.fido2Authenticating

  function refreshFingerprintStatus() {
    if (!fingerprintCheckProc.running) fingerprintCheckProc.running = true
  }

  function refreshFaceStatus() {
    if (!faceCheckProc.running) faceCheckProc.running = true
  }

  function submitPassword(value) {
    var password = String(value || "")
    // A password submitted while on the key (emergency field, custom design)
    // is a password: leave key mode first so it never meets fido2Pam.
    if (password.length > 0 && root.fido2Active) root.setAuthMode("password")
    if (!root.lockRequested || root.authenticatingPassword || password.length === 0) {
      if (password.length === 0 && root.faceConfigured) root.retryFace()
      return
    }

    root.runWake()
    root.pendingPassword = password
    root.failureMessage = ""
    root.authenticatingPassword = true

    if (!passwordPam.start()) {
      root.handlePasswordFailure()
      return
    }

    Qt.callLater(root.respondToPasswordPrompt)
  }

  function respondToPasswordPrompt() {
    if (!root.authenticatingPassword || !passwordPam.active || !passwordPam.responseRequired) return
    passwordPam.respond(root.pendingPassword)
  }

  function handlePasswordFailure() {
    if (!root.lockRequested) return

    root.authenticatingPassword = false
    root.enteredPassword = ""
    root.pendingPassword = ""
    root.failedAttempts += 1
    root.failureTimes = root.failureTimes.concat([Date.now()])
    root.failureMessage = root.t("Authentication failed (%1)").arg(root.failedAttempts)
    root.runWake()
  }

  function startFingerprint() {
    if (!root.lockRequested || !root.sessionLock.secure || !root.fingerprintConfigured) return
    if (fingerprintPam.active || root.fingerprintAuthenticating) return

    root.fingerprintAuthenticating = true
    if (!fingerprintPam.start()) {
      root.fingerprintAuthenticating = false
    }
  }

  function handleFingerprintFinished(result) {
    root.fingerprintAuthenticating = false

    if (!root.lockRequested) return
    if (result === PamResult.Success) {
      root.finishUnlock()
    } else if (root.fingerprintConfigured) {
      fingerprintRetryTimer.restart()
    }
  }

  // The camera runs only behind a lock screen someone can actually see: a
  // dark panel means nobody is in front of it, and a scan there is a camera
  // on for no one. Blanking stops the round; the wake starts a fresh one.
  function startFace() {
    if (!root.lockRequested || !root.sessionLock.secure || !root.faceConfigured) return
    // "off" stops the automatic rounds, not the face button or Enter on an
    // empty field, which come through retryFace.
    if (root.screenBlanked) return
    if (facePam.active || root.faceAuthenticating) return

    root.faceAuthenticating = true
    root.lastFaceRound = Date.now()
    if (!facePam.start()) root.faceAuthenticating = false
  }

  function retryFace() {
    root.faceMisses = 0
    root.startFace()
  }

  function stopFace() {
    faceRetryTimer.stop()
    root.faceMisses = 0
    if (facePam.active) facePam.abort()
    root.faceAuthenticating = false
  }

  function handleFaceFinished(result) {
    root.faceAuthenticating = false

    if (!root.lockRequested) return
    // A result from a round the blanking cut short says nothing about who is
    // in front of the screen now.
    if (root.screenBlanked) return
    if (result === PamResult.Success) {
      root.finishUnlock()
    } else {
      root.faceMissed()
    }
  }

  function faceMissed() {
    if (!root.lockRequested || !root.faceConfigured || root.screenBlanked) return
    root.faceMisses += 1
    if (root.faceMisses < root.faceRetryLimit) faceRetryTimer.restart()
    else root.logEvent("face-paused after " + root.faceMisses + " misses")
  }

  PamContext {
    id: passwordPam
    config: "omarchy-lock-password"
    user: root.userName

    onResponseRequiredChanged: root.respondToPasswordPrompt()
    onPamMessage: root.respondToPasswordPrompt()

    onCompleted: function(result) {
      root.authenticatingPassword = false
      root.pendingPassword = ""

      if (!root.lockRequested) return
      if (result === PamResult.Success) root.finishUnlock()
      else root.handlePasswordFailure()
    }

    onError: function(error) {
      root.handlePasswordFailure()
    }
  }

  PamContext {
    id: fingerprintPam
    config: "omarchy-lock-fingerprint"
    user: root.userName

    onPamMessage: root.handleFingerprintMessage()

    onCompleted: function(result) {
      root.handleFingerprintFinished(result)
    }

    onError: function(error) {
      root.fingerprintAuthenticating = false
      if (root.lockRequested && root.fingerprintConfigured) fingerprintRetryTimer.restart()
    }
  }

  PamContext {
    id: facePam
    config: "omarchy-lock-face"
    user: root.userName

    onCompleted: function(result) {
      root.handleFaceFinished(result)
    }

    onError: function(error) {
      root.faceAuthenticating = false
      root.faceMissed()
    }
  }

  Timer {
    id: fingerprintRetryTimer
    interval: 250
    repeat: false
    onTriggered: root.startFingerprint()
  }

  Timer {
    id: fingerprintErrorHold
    interval: 2500
    onTriggered: {
      if (root.fingerprintPendingStatus.length > 0) {
        root.fingerprintStatus = root.fingerprintPendingStatus
        root.fingerprintStatusIsError = false
        root.fingerprintPendingStatus = ""
      } else if (root.fingerprintStatusIsError) {
        root.fingerprintStatus = ""
        root.fingerprintStatusIsError = false
      }
    }
  }

  Timer {
    id: faceRetryTimer
    interval: 250
    repeat: false
    onTriggered: root.startFace()
  }

  Process {
    id: fingerprintCheckProc
    command: ["bash", "-c", "if [[ -f /etc/pam.d/omarchy-lock-fingerprint ]] && command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$USER\" 2>/dev/null | grep -qi finger; then echo yes; else echo no; fi"]
    stdout: StdioCollector { id: fingerprintCheckStdout; waitForEnd: true }
    onExited: {
      root.fingerprintConfigured = String(fingerprintCheckStdout.text || "").trim() === "yes"
      if (root.lockRequested && root.fingerprintConfigured) root.startFingerprint()
      else if (!root.fingerprintConfigured && fingerprintPam.active) fingerprintPam.abort()
    }
  }

  Process {
    id: faceCheckProc
    command: [root.checkFaceAuthPath, "--yes"]
    stdout: StdioCollector { id: faceCheckStdout; waitForEnd: true }
    onExited: {
      root.faceConfigured = String(faceCheckStdout.text || "").trim() === "yes"
      if (root.lockRequested && root.faceConfigured && root.faceStart === "always") root.startFace()
      else if (!root.faceConfigured && facePam.active) facePam.abort()
    }
  }

  FileView {
    path: "/etc/pam.d/omarchy-lock-password"
    watchChanges: true
    printErrors: false
    onLoaded: root.passwordPamConfigured = true
    onLoadFailed: root.passwordPamConfigured = false
    onFileChanged: reload()
  }
}
