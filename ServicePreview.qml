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
  readonly property alias previewFailureTimer: previewFailureTimer
  readonly property alias previewUnlockTimer: previewUnlockTimer


  property string previewDesignId: ""
  property string previewTyped: ""
  property string previewFailure: ""
  property bool previewUnlocking: false
  Timer { id: previewFailureTimer; interval: 2500; onTriggered: root.previewFailure = "" }

  // Runs the unlock animation on the preview so it can be seen without locking.
  Timer {
    id: previewUnlockTimer
    interval: Math.max(1, root.unlockDuration + 80)
    repeat: false
    onTriggered: {
      root.previewVisible = false
      root.previewDesignId = ""
      root.previewTyped = ""
      root.previewUnlocking = false
    }
  }
  property bool previewVisible: false
  property bool previewClipPlaying: false

  PanelWindow {
    id: previewWindow
    visible: root.previewVisible
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-lock-explorer-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    UnlockLayer {
      anchors.fill: parent
      animation: root.unlockAnimation
      duration: root.unlockDuration
      active: root.previewUnlocking

      LockHost {
        anchors.fill: parent
        designId: root.previewDesignId.length > 0 ? root.previewDesignId : root.designId
        revision: root.designsRevision
        userDesigns: root.userDesigns
        backgroundPath: root.backgroundPath
        backgroundVersion: root.backgroundVersion
        avatarPath: root.avatarPath
        avatarVersion: root.avatarVersion
        fingerprintConfigured: root.fingerprintConfigured
        authenticatingPassword: false
        failureMessage: root.previewFailure
        failedAttempts: root.previewFailure.length > 0 ? 1 : 0
        inputEnabled: root.previewVisible && !root.previewUnlocking
        loadBackground: root.previewVisible
        passwordText: root.previewTyped
        videoPath: root.videoPath
        videoPlaying: root.previewVisible
        faceConfigured: root.faceConfigured
        fido2Configured: root.fido2Configured
        unlockPlayback: root.previewClipPlaying
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
        batteryLow: root.batteryLow
        batteryPercent: root.batteryPercent
        ownerMessage: root.ownerMessage
        // Hold the clip's last frame in the preview instead of snapping back
        // to the start; Esc (hidePreview) resets it.
        onUnlockFinished: {}
        onPasswordTextEdited: function(password) { root.previewTyped = password }
        onFaceRequested: root.retryFace()
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: { root.previewVisible = false; root.previewDesignId = "" }
    }
  }
}
