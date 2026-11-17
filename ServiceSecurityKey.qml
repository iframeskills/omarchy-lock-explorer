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
  readonly property alias fido2CheckProc: fido2CheckProc

  // Security-key unlock is a mode the user is in. It does not run alongside
  // the password: pam_u2f gets its own PAM service and its own context, since
  // sharing omarchy-lock-password would send every mistyped password to the
  // key as a PIN attempt, and a key locks itself out after eight.
  property string authMode: "password" // "password" | "fido2"
  // Picked once per lock by the probe; a later probe never overrides a choice.
  property bool authModeSettled: false
  // What the probe found, and what the lock screen does with it. Everything
  // downstream reads fido2Configured, so the Settings toggle only has to turn
  // this one property off.
  property bool fido2Installed: false
  readonly property bool fido2Configured: root.fido2Installed && root.fido2Enabled
  property bool fido2TokenPresent: false
  property bool fido2Authenticating: false
  property bool fido2NeedsPin: false
  property string fido2Status: ""
  // Last thing pam_u2f said that did not want an answer, i.e. the cue.
  property string fido2Cue: ""
  // PIN attempts in this lock. A wrong PIN costs one of the key's retries,
  // and the key itself refuses further PINs after three in a row until it is
  // replugged, so the screen stops offering it at the same point and asks for
  // the password. Attempts that never reached a PIN (no touch, no key) are
  // free and do not count.
  property int fido2PinAttempts: 0
  property bool fido2PinSubmitted: false
  readonly property int fido2PinAttemptLimit: 3
  // pam_u2f waits about 30s for a touch and then returns PamResult.Failed --
  // the same code a touch that did not verify gives. A round that ran the
  // whole wait with no PIN typed is the no-touch case, and it spends nothing:
  // no PIN retry, no on-key biometric retry. Anything shorter had a user in it.
  readonly property int fido2NoTouchMs: 20000
  property real fido2RoundStarted: 0
  // A touch that did not verify costs one of the key's own UV retries, not a
  // PIN retry, and the key caps those itself and resets them on a match. The
  // round is offered again rather than the user having to Tab back, and this
  // many in a row is the key at its own limit: hand over the password.
  readonly property int fido2TouchRetryLimit: 3
  property int fido2TouchMisses: 0
  // A failed round with no PIN in it waits here while the probe says whether
  // the key is still attached; see handleFido2Finished.
  property bool fido2FailurePending: false
  readonly property bool fido2Exhausted: root.fido2PinAttempts >= root.fido2PinAttemptLimit
  readonly property bool fido2Active: root.authMode === "fido2"

  // A probe already running is not an answer to a request made after it
  // started, so the request is queued and the probe runs once more.
  // Capped: a flapping hidraw device (a bad cable, a receiver reconnecting)
  // could otherwise keep every answer discarded and a pending failure or the
  // next round waiting on it for good.
  property bool fido2ProbeQueued: false
  property int fido2ProbeReruns: 0
  readonly property int fido2ProbeRerunLimit: 2

  // Wake and retry ask the probe rather than trusting the last answer: a key
  // that left while the session slept is otherwise still "present", and the
  // first round after wake is charged for it. The probe starts the round.
  function retryFido2() {
    root.fido2TouchMisses = 0
    root.refreshFido2Status()
  }

  // Key mode when a key is enrolled and plugged in at lock time, password
  // otherwise. Runs from the probe, not beginLock(): the answer is a
  // subprocess away when the lock is requested.
  function settleAuthMode() {
    if (root.authModeSettled || !root.lockRequested) return
    if (!root.fido2Configured || !root.fido2TokenPresent || root.fido2Exhausted) return
    if (root.authenticatingPassword || root.enteredPassword.length > 0) return
    root.setAuthMode("fido2")
  }

  function setAuthMode(mode) {
    if (mode !== "password" && mode !== "fido2") return
    // Never yank the field while a password check is in flight.
    if (root.authenticatingPassword) return
    var switching = root.authMode !== mode && !(mode === "fido2" && !root.fido2Configured)
    if (switching) {
      if (root.authMode === "fido2") root.abortFido2()
      root.authMode = mode
      root.failureMessage = ""
      root.enteredPassword = ""
      root.pendingPassword = ""
      root.logEvent("auth-mode=" + mode)
    }
    // A request for a mode that cannot be entered still settles, so a later
    // probe does not override what the user asked for. A key plugged in
    // afterwards is still offered to an empty field; see fido2CheckProc.
    root.authModeSettled = true
  }

  // Glyph click, Tab from the password, Enter on the inert field: switch to
  // the key if not there yet, then look for it again and start. The probe's
  // onExited does the starting.
  function requestFido2() {
    if (!root.lockRequested || !root.fido2Configured) return
    if (root.fido2Exhausted) {
      root.failureMessage = root.t("Use your password")
      return
    }
    if (!root.fido2Active) root.setAuthMode("fido2")
    if (!root.fido2Active || root.fido2Authenticating) return
    root.failureMessage = ""
    root.fido2Status = root.t("Looking for your key…")
    root.refreshFido2Status()
  }

  // Same reasoning as startFace: a dark panel means nobody is in front of it,
  // and a key blinking there is asking for a finger that is not coming.
  // Blanking ends the round; the wake starts a fresh one.
  function startFido2() {
    // Same gate as startFingerprint: a success before the surface is secure
    // would unlock a lock that never took.
    if (!root.lockRequested || !root.sessionLock.secure) return
    if (!root.fido2Active || !root.fido2Configured || root.fido2Exhausted) return
    if (fido2Pam.active || root.fido2Authenticating) return
    if (root.screenBlanked) return
    if (!root.fido2TokenPresent) {
      root.fido2Status = root.t("No security key found")
      return
    }

    // Anything typed before the key was found would be read-only in the field
    // from here on and end up in front of the PIN, costing a retry for nothing.
    root.enteredPassword = ""
    root.fido2NeedsPin = false
    root.fido2PinSubmitted = false
    root.fido2Cue = ""
    root.fido2Status = root.t("Waiting for your key…")
    root.fido2Authenticating = true
    root.fido2RoundStarted = Date.now()
    if (!fido2Pam.start()) {
      root.fido2Authenticating = false
      root.fido2Status = root.t("Could not start the key")
    }
  }

  function abortFido2() {
    // Cleared before abort(): whatever completed/error the abort emits is
    // then ignored by handleFido2Finished instead of counted as a failure.
    root.fido2Authenticating = false
    root.fido2NeedsPin = false
    root.fido2Status = ""
    root.fido2Cue = ""
    if (fido2Pam.active) fido2Pam.abort()
  }

  // pam_u2f asks for the PIN with a prompt that wants a response and announces
  // the touch with one that does not. The kind decides, never the wording.
  // It says nothing after a PIN is accepted, even though it then waits for a
  // touch, so the cue it did send is kept and put back at that point.
  function handleFido2Message() {
    if (!root.fido2Authenticating) return
    // Only the PIN prompt is asking the user for something. Waking on the
    // touch cue instead re-arms the blank timer once per round, so a lock with
    // a key plugged in would never go dark.
    if (fido2Pam.responseRequired) root.runWake()

    if (fido2Pam.responseRequired) {
      root.fido2NeedsPin = true
      root.fido2Status = root.t("Enter the PIN for your key")
      return
    }

    root.fido2NeedsPin = false
    var text = root.pamMessageText(fido2Pam.message)
    if (text.length > 0) {
      root.fido2Cue = text
      root.fido2Status = text
    }
  }

  function submitFido2Pin(pin) {
    var value = String(pin || "")
    if (!root.fido2Active || !root.fido2Authenticating || value.length === 0) return
    if (!fido2Pam.active || !fido2Pam.responseRequired) return

    fido2Pam.respond(value)
    root.fido2NeedsPin = false
    root.fido2PinSubmitted = true
    root.enteredPassword = ""
    // Not "Checking…": the key is lit and waiting for a finger, and the only
    // other sign of that is the light on the key itself.
    root.fido2Status = root.fido2Cue.length > 0 ? fido2Cue : "Touch your security key"
  }

  function handleFido2Finished(result) {
    if (!root.fido2Authenticating) return

    root.fido2Authenticating = false
    root.fido2NeedsPin = false
    root.enteredPassword = ""

    var elapsed = root.fido2RoundStarted ? Date.now() - fido2RoundStarted : 0
    root.fido2RoundStarted = 0

    if (!root.lockRequested) return
    // A touch is unambiguous even in the dark, so a success still unlocks.
    if (result === PamResult.Success) {
      root.finishUnlock()
      return
    }

    // A result from a round the blanking cut short says nothing about who is
    // in front of the screen now, and waking the panel to report it would
    // light the lock up for no one.
    if (root.screenBlanked) {
      root.fido2Status = ""
      root.logEvent("fido2-round dropped, screen dark")
      return
    }

    // Nobody touched the key: the module waited its whole time and gave up.
    // Nothing was spent and nobody tried, so it is not held against the user
    // and the round simply starts again -- otherwise a lock left alone for
    // longer than that wait looks like it is still on the key while nothing
    // is listening, and Tab is the only way back.
    if (!root.fido2PinSubmitted && elapsed >= root.fido2NoTouchMs) {
      root.fido2Status = ""
      root.logEvent("fido2-round again after " + elapsed + "ms")
      fido2RetryTimer.restart()
      return
    }

    // A key pulled out mid-round fails it at once, and so does every retry
    // after it: counted as misses, three of those arrive within a second and
    // a half, park the lock on the password, stop the hotplug watcher, and
    // report three failed attempts when nobody tried anything. A round with
    // no PIN in it asks the probe first; see fido2FailureChecked.
    // PAM can see the USB loss before udev removes the node, so a probe sent
    // at once can still find the key and charge a miss for an unplug. Give
    // it the same settle the hotplug path uses before asking.
    if (!root.fido2PinSubmitted) {
      root.fido2FailurePending = true
      fido2FailureSettle.restart()
      return
    }
    root.countFido2Failure()
  }

  // The probe answered for a round that failed without a PIN. Gone: say so,
  // stay on the key, and let the hotplug watcher (which runs while the key is
  // absent in key mode) start the next round when it is back. Still there:
  // it was a real miss.
  function fido2FailureChecked() {
    root.fido2FailurePending = false
    if (!root.lockRequested) return
    if (!root.fido2TokenPresent) {
      root.fido2Status = root.t("No security key found")
      root.failureMessage = ""
      root.logEvent("fido2-round ended, key removed")
      root.runWake()
      return
    }
    root.countFido2Failure()
  }

  function countFido2Failure() {
    // A PIN that went to the key is still the user's to spend again.
    var pinWasSubmitted = root.fido2PinSubmitted
    root.failedAttempts += 1
    root.failureTimes = root.failureTimes.concat([Date.now()])
    if (root.fido2PinSubmitted) root.fido2PinAttempts += 1
    root.fido2PinSubmitted = false
    root.fido2Status = ""
    if (root.fido2Exhausted) {
      // Three PINs went to the key in this lock. Whether they were wrong or a
      // bystander was guessing, the key is at its own limit and the rest of
      // its retries are not the lock screen's to spend. Back to the password;
      // setAuthMode clears failureMessage, so the message goes after it.
      root.setAuthMode("password")
      root.failureMessage = root.t("Use your password")
      root.logEvent("fido2-exhausted")
    } else {
      root.failureMessage = root.t("Security key failed (%1)").arg(root.failedAttempts)
      if (!pinWasSubmitted && root.fido2Active && root.fido2TokenPresent) {
        root.fido2TouchMisses += 1
        if (root.fido2TouchMisses < root.fido2TouchRetryLimit) fido2RetryTimer.restart()
        else {
          root.setAuthMode("password")
          // Short: the field elides, and the switch to the password is what
          // says where to go next.
          root.failureMessage = root.t("Too many tries")
          root.logEvent("fido2-paused after " + root.fido2TouchMisses + " misses")
        }
      }
    }
    root.runWake()
  }

  PamContext {
    id: fido2Pam
    config: "omarchy-lock-fido2"
    user: root.userName

    onResponseRequiredChanged: root.handleFido2Message()
    onPamMessage: root.handleFido2Message()

    onCompleted: function(result) {
      root.handleFido2Finished(result)
    }

    onError: function(error) {
      root.handleFido2Finished(PamResult.Error)
    }
  }

  // Longer than faceRetryTimer: a round that ends the instant it starts would
  // otherwise spin, and nothing here is racing a camera frame.
  Timer {
    id: fido2RetryTimer
    interval: 500
    repeat: false
    onTriggered: root.refreshFido2Status()
  }

  // See handleFido2Finished: the probe for a failed round without a PIN.
  Timer {
    id: fido2FailureSettle
    interval: 400
    repeat: false
    onTriggered: root.refreshFido2Status()
  }

  // A key plugged in or pulled out while locked has to be noticed, and polling
  // for it would mean spawning a probe every couple of seconds for as long as
  // the screen is locked. This sleeps on the udev netlink socket instead and
  // wakes only when a hidraw device comes or goes. It runs for the whole lock,
  // a round in flight included: watching only while no key was attached left
  // a key pulled mid-round or during sleep cached as present. The probe it
  // asks for never interrupts a running round or half-typed input; see
  // startFido2 and fido2CheckProc. With wakeOnKeyInsert on, an add while the
  // screen is dark goes through keyInsertSettle instead, which wakes the
  // display only when the probe finds the key.
  Process {
    id: fido2HotplugWatch
    running: root.lockRequested && root.fido2Configured
      && (!root.fido2Exhausted || root.wakeOnKeyInsert)
    command: ["udevadm", "monitor", "--udev", "--subsystem-match=hidraw"]
    stdout: SplitParser {
      // "UDEV  [123.4] add  /devices/.../hidraw/hidraw0 (hidraw)"
      onRead: function(line) {
        var text = String(line)
        var added = text.indexOf(" add ") >= 0
        if (!added && text.indexOf(" remove ") < 0) return
        if (added && root.wakeOnKeyInsert && root.screenBlanked) keyInsertSettle.restart()
        else fido2HotplugSettle.restart()
      }
    }
  }

  // udev announces the device before its permissions are in place, so give the
  // node a moment before asking whether libfido2 can open it. Also collapses
  // the burst of events one plug produces into a single probe.
  Timer {
    id: fido2HotplugSettle
    interval: 400
    repeat: false
    onTriggered: root.refreshFido2Status()
  }

  // Lock-on-removal, while unlocked. Wake-on-insert rides on
  // fido2HotplugWatch, which already runs for the whole lock, so the two never
  // run side by side. Any hidraw device comes and goes here -- a mouse
  // receiver, a game pad -- so a removal is only acted on once the probe says
  // the key itself is gone.
  property bool keyEventProbe: false
  property bool keyInsertProbe: false
  Process {
    id: keyEventWatch
    running: root.fido2Configured && root.lockOnKeyRemoval && !root.lockRequested
    command: ["udevadm", "monitor", "--udev", "--subsystem-match=hidraw"]
    // Lock-on-removal compares against the last answer, so that answer has
    // to be current from the moment the watch starts -- after an unlock the
    // key may have come or gone while the lock was up.
    onRunningChanged: if (running && !root.lockRequested) root.refreshFido2Status()
    stdout: SplitParser {
      onRead: function(line) {
        var text = String(line)
        var added = text.indexOf(" add ") >= 0
        var removed = text.indexOf(" remove ") >= 0
        // Unlocked, both directions keep the presence current: a key plugged
        // in after a password unlock has to be known before it can be missed.
        if ((added || removed) && !root.lockRequested) keyEventSettle.restart()
      }
    }
  }

  // Same settle as fido2HotplugSettle: collapses the burst of events one plug
  // produces, and gives the node time to get its permissions.
  Timer {
    id: keyEventSettle
    interval: 400
    repeat: false
    onTriggered: {
      root.keyEventProbe = true
      root.refreshFido2Status()
    }
  }

  // Any HID device can be what went in, so the probe decides: the display
  // wakes only when the key is there (see fido2CheckProc), and the same
  // answer starts the round.
  Timer {
    id: keyInsertSettle
    interval: 400
    repeat: false
    onTriggered: {
      if (!root.lockRequested || !root.screenBlanked) return
      root.keyInsertProbe = true
      root.refreshFido2Status()
    }
  }

  Process {
    id: fido2CheckProc
    command: [root.checkFido2AuthPath]
    stdout: StdioCollector { id: fido2CheckStdout; waitForEnd: true }
    onExited: {
      // A request that arrived while this probe ran may be about a change
      // this probe started too early to see -- a key pulled after it had
      // already listed the devices. Its answer is not acted on; the next one is.
      if (root.fido2ProbeQueued && root.fido2ProbeReruns < root.fido2ProbeRerunLimit) {
        root.fido2ProbeQueued = false
        root.fido2ProbeReruns += 1
        Qt.callLater(function() { fido2CheckProc.running = true })
        return
      }
      root.fido2ProbeQueued = false
      root.fido2ProbeReruns = 0

      var answer = String(fido2CheckStdout.text || "").trim().split(/\s+/)
      var wasPresent = root.fido2TokenPresent
      root.fido2Installed = answer[0] === "yes"
      root.fido2TokenPresent = answer[1] === "present"
      var keyEvent = root.keyEventProbe
      var keyInsert = root.keyInsertProbe
      root.keyEventProbe = false
      root.keyInsertProbe = false

      // Not configured any more wins over a pending failure: the round is
      // moot, and the lock goes back to the password rather than waiting on
      // a key it will not use.
      if (!root.fido2Configured) {
        root.fido2FailurePending = false
        if (root.fido2Active) root.setAuthMode("password")
        return
      }

      // Only a probe a hidraw event asked for can lock: a settings refresh
      // that happens to find no key is not somebody walking away with it.
      if (keyEvent && !root.lockRequested && root.lockOnKeyRemoval
          && wasPresent && !root.fido2TokenPresent) {
        if (root.passwordPamConfigured && !root.lockRequested) {
          root.logEvent("lock-on-key-removal")
          root.beginLock()
        }
        return
      }

      // The device that went in while the screen was dark was the key: it was
      // not there before and is now. With the key left in, a mouse or headset
      // reconnecting would otherwise light the lock for nobody. The watcher
      // sees removals while dark too, so a key that left is known as gone.
      // runWake clears screenBlanked, so the round below can start.
      if (keyInsert && root.lockRequested && root.screenBlanked
          && !wasPresent && root.fido2TokenPresent) {
        root.logEvent("wake-on-key-insert")
        root.runWake()
      }

      if (root.fido2FailurePending) {
        // A probe that finished inside the failure's settle window (one the
        // hotplug watcher asked for, say) may predate the node going away.
        // The one fido2FailureSettle sends decides.
        if (fido2FailureSettle.running) return
        root.fido2FailureChecked()
        return
      }

      if (!root.lockRequested) return
      // A key plugged back in is offered again, even after the user went to
      // the password, but only to an empty field: typed input, a check in
      // flight and a key at its PIN limit are left alone.
      if (!wasPresent && root.fido2TokenPresent && !root.fido2Active && !root.fido2Exhausted
          && !root.authenticatingPassword && root.enteredPassword.length === 0) {
        root.fido2TouchMisses = 0
        root.setAuthMode("fido2")
      }
      if (!root.fido2Active) root.settleAuthMode()
      if (root.fido2Active) root.startFido2()
    }
  }
}
