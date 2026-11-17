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

Column {
  readonly property alias customDelayInput: customDelayInput
  required property var root
          id: settingsPage
  width: Math.min(parent.width, Style.space(900))
  visible: root.mainTab === "settings"
  spacing: Style.space(18)

  // Health: only when something is missing, with the fix a click
  // away. The full check is extras/doctor.sh, under System.
  SettingSection {
    explorer: root
    visible: root.healthIssues.length > 0
    title: root.tr("Health")
    description: root.tr("Something here keeps part of the plugin from working.")

    Column {
      width: parent.width
      spacing: Style.space(8)

      Repeater {
        model: root.healthIssues
        Rectangle {
          id: issueRow
          required property var modelData
          width: parent.width
          height: issueLine.implicitHeight + Style.space(22)
          radius: root.cornerRadius
          color: Qt.rgba(root.danger.r, root.danger.g, root.danger.b, 0.12)
          border.width: 1
          border.color: Qt.rgba(root.danger.r, root.danger.g, root.danger.b, 0.45)

          Text {
            id: issueLine
            anchors.left: parent.left
            anchors.right: installButton.visible ? installButton.left : parent.right
            anchors.leftMargin: Style.space(14)
            anchors.rightMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            text: issueRow.modelData.text
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Rectangle {
            id: installButton
            visible: issueRow.modelData.packages.length > 0 || !!issueRow.modelData.fix
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            width: installLabel.implicitWidth + Style.space(26)
            height: Style.space(34)
            radius: root.cornerRadius
            color: installArea.containsMouse ? Qt.lighter(root.accent, 1.15) : root.accent
            Text {
              id: installLabel
              anchors.centerIn: parent
              text: issueRow.modelData.fix === "copies" ? root.tr(root.movingCopies ? "Moving…" : "Move it out") : root.tr("Install")
              color: Commons.Color.background
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.weight: Font.DemiBold
            }
            MouseArea {
              id: installArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (issueRow.modelData.fix === "copies") root.moveCopies()
                else root.installPackages(issueRow.modelData.packages)
              }
            }
          }
        }
      }
    }
  }

  SettingSection {
    explorer: root
    title: root.tr("Unlock")
    description: root.tr("What happens once the password is right.")

    // The animation the lock screen leaves with.
    SettingRow {
      explorer: root
      label: root.tr("Animation")
      help: root.motionReduced
            ? root.tr("Reduce motion is on, so the lock screen leaves at once and no unlock clip plays.")
            : (root.unlockAnimation === "none" ? "" : root.tr("The lock screen stays up while it plays."))

      Column {
        width: parent.width
        spacing: Style.space(2)
        Repeater {
          model: root.unlockOptions
          Rectangle {
            id: unlockOptionRow
            required property var modelData
            readonly property bool current: modelData.id === root.unlockAnimation
            width: Math.min(parent.width, Style.space(460))
            height: Style.space(50)
            radius: root.cornerRadius
            color: current ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                           : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, unlockOptionArea.containsMouse ? 0.07 : 0.0)
            Behavior on color { ColorAnimation { duration: 100 } }

            Rectangle {
              id: unlockOptionRadio
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: Style.space(12)
              width: Style.space(18)
              height: Style.space(18)
              radius: width / 2
              color: "transparent"
              border.width: Math.max(1, Style.space(2))
              border.color: unlockOptionRow.current ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)

              Rectangle {
                anchors.centerIn: parent
                width: Style.space(9)
                height: Style.space(9)
                radius: width / 2
                color: root.accent
                visible: unlockOptionRow.current
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: unlockOptionRadio.right
              anchors.leftMargin: Style.space(12)
              spacing: 2

              Text {
                text: root.tr(unlockOptionRow.modelData.name)
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.weight: unlockOptionRow.current ? Font.DemiBold : Font.Normal
              }

              Text {
                text: root.tr(unlockOptionRow.modelData.hint)
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }

            MouseArea {
              id: unlockOptionArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.setUnlock(unlockOptionRow.modelData.id)
            }
          }
        }
      }
    }

    SettingRow {
      explorer: root
      visible: root.unlockAnimation !== "none"
      label: root.tr("Length")
      options: root.unlockDurations.map(function(ms) { return { id: ms, name: (ms / 1000).toFixed(1) + "s" } })
      current: root.unlockDuration
      onPicked: function(id) { root.setUnlockDuration(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Clip speed")
      help: root.tr("How fast the clip designs and the unlock clip play.")
      options: root.clipSpeeds.map(function(v) { return { id: v, name: v + "x" } })
      current: {
        for (var i = 0; i < root.clipSpeeds.length; i++)
          if (Math.abs(root.clipSpeeds[i] - root.clipSpeed) < 0.01) return root.clipSpeeds[i]
        return undefined
      }
      onPicked: function(id) { root.setClipSpeed(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Video ends as wallpaper")
      help: root.clipWallpaper
            ? root.tr("The desktop opens on the frame the clip stopped on, set with omarchy-theme-bg-set.")
            : root.tr("The desktop keeps its own wallpaper after a clip.")
      options: root.onOffOptions
      current: root.clipWallpaper ? "on" : "off"
      onPicked: function(id) { if ((id === "on") !== root.clipWallpaper) root.toggleClipWallpaper() }
    }
  }

  SettingSection {
    explorer: root
    title: root.tr("Look")
    description: root.tr("How every design is drawn. The preview on the right follows along.")

    SettingRow {
      explorer: root
      label: root.tr("Clock")
      options: root.clockFormats
      current: root.twelveHour ? "12" : "24"
      onPicked: function(id) { root.setTwelveHour(id === "12") }
    }

    SettingRow {
      explorer: root
      label: root.tr("Language")
      help: root.tr("The language of the lock screen and of this explorer.")
      options: root.languageChoices
      current: root.languageSetting
      onPicked: function(id) { root.setLanguage(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Wallpaper blur")
      options: root.wallpaperBlurChoices
      current: root.wallpaperBlur
      onPicked: function(id) { root.setWallpaperBlur(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Wallpaper dim")
      help: root.wallpaperBlur === "design" && root.wallpaperDim === "design"
            ? root.tr("Each design blurs and darkens the wallpaper its own way.")
            : root.tr("Designs drawn over a solid color or their own art are not affected.")
      options: root.wallpaperDimChoices
      current: root.wallpaperDim
      onPicked: function(id) { root.setWallpaperDim(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Size")
      help: root.tr("Draws the whole lock screen larger, so text, field and avatar grow together.")
      options: root.uiScaleChoices
      current: root.uiScale
      onPicked: function(id) { root.setUiScale(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Reduce motion")
      help: root.reduceMotion === "off"
            ? root.tr("Animated designs move as they were made to.")
            : root.tr("Designs hold still, changing only for what you type, a wrong password or the minute.")
              + (root.reduceMotion === "battery" ? " " + root.tr(root.motionReduced ? root.tr("On battery now.") : root.tr("Moving now: on mains power.")) : "")
      options: root.reduceMotionChoices
      current: root.reduceMotion
      onPicked: function(id) { root.setReduceMotion(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Design follows the theme")
      help: !root.followTheme
            ? root.tr("The same design shows whichever theme is active.")
            : (root.rotateDesigns !== "off"
               ? root.tr("Off while the designs rotate.")
               : root.tr("Each theme remembers the design picked while it is active, and a theme change brings it back.")
                 + " " + root.tr("Enter picks for the theme that is on, Shift+Enter for all of them."))
      options: root.onOffOptions
      current: root.followTheme ? "on" : "off"
      onPicked: function(id) { root.setFollowTheme(id === "on") }
    }

    SettingRow {
      explorer: root
      label: root.tr("Rotate designs")
      help: root.rotateDesigns === "off"
            ? root.tr("The same design every time.")
            : (root.favoriteIds.length < 2
               ? root.tr("Star at least two designs as favorites (F) and they take turns.")
               : (root.rotateDesigns === "lock"
                  ? root.tr("The favorites take turns: the next one each time the screen locks.")
                  : root.tr("The favorites take turns: a new one each day.")))
      options: root.rotateDesignsOptions
      current: root.rotateDesigns
      onPicked: function(id) { root.setRotateDesigns(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Owner message")
      help: root.ownerMessage.length > 0
            ? root.tr("Shown in the bottom left corner of every design, for whoever finds the computer.")
            : root.tr("Nothing is shown. A line here, such as who to call, sits in the bottom left corner of every design.")

      Rectangle {
        width: Style.space(440)
        height: Style.space(34)
        radius: root.cornerRadius
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
        border.width: Math.max(1, Style.space(2))
        border.color: ownerInput.activeFocus ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: Style.space(10)
          visible: ownerInput.activeFocus
          text: root.tr("Enter saves")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          visible: ownerInput.text.length === 0 && !ownerInput.activeFocus
          text: root.tr("If found, please call …")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        // Enter saves, Escape puts the saved line back. Typing breaks
        // the binding to the saved line, so a change from elsewhere
        // (the IPC) is copied in by hand.
        TypedInput {
          id: ownerInput
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(100)
          verticalAlignment: TextInput.AlignVCenter
          clip: true
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          maximumLength: root.ownerMessageMaxLength
          text: root.ownerMessage
          onActiveFocusChanged: root.ownerEditing = activeFocus
          Keys.onEscapePressed: { text = root.ownerMessage; root.keyCatcher.forceActiveFocus() }
          Keys.onReturnPressed: { root.setOwnerMessage(text); root.keyCatcher.forceActiveFocus() }
          Connections {
            target: root
            function onOwnerMessageChanged() { if (!ownerInput.activeFocus) ownerInput.text = root.ownerMessage }
          }
        }
      }
    }
  }

  SettingSection {
    explorer: root
    title: root.tr("Password field")
    description: root.tr("What the field shows next to what you type, in the designs that use it.")

    SettingRow {
      explorer: root
      label: root.tr("Keyboard layout")
      help: root.tr("The layout code, such as DK or DE, shown when it is not US or when you have more than one. Click it to switch.")
      options: root.shownHiddenOptions
      current: root.showLayoutBadge ? "show" : "hide"
      onPicked: function(id) { root.setFieldItem("layout", id === "show") }
    }

    SettingRow {
      explorer: root
      label: root.tr("Caps lock warning")
      help: root.tr("A CAPS badge while caps lock is on.")
      options: root.shownHiddenOptions
      current: root.showCapsBadge ? "show" : "hide"
      onPicked: function(id) { root.setFieldItem("caps", id === "show") }
    }

    SettingRow {
      explorer: root
      label: root.tr("Show password button")
      help: root.tr("The eye that shows what you typed. Ctrl+E does the same either way.")
      options: root.shownHiddenOptions
      current: root.allowPasswordToggle ? "show" : "hide"
      onPicked: function(id) { root.setFieldItem("reveal", id === "show") }
    }

    SettingRow {
      explorer: root
      label: root.tr("Sign-in icons")
      help: root.tr("The fingerprint, face and security key icons. Without them Tab still switches to the key and Enter on an empty field still starts face unlock.")
      options: root.shownHiddenOptions
      current: root.showAuthIcons ? "show" : "hide"
      onPicked: function(id) { root.setFieldItem("icons", id === "show") }
    }
  }

  SettingSection {
    explorer: root
    title: root.tr("Screen and power")
    description: root.tr("How long the lock screen stays lit, and what it can do besides take a password.")

    // Never keeps it powered for the whole lock: video designs keep
    // playing and slow monitors are never re-blanked mid-wake.
    SettingRow {
      explorer: root
      label: root.tr("Blank the display after")
      help: root.keepDisplayOn
            ? root.tr("The lock screen stays lit for the whole lock: video designs keep playing.")
            : root.tr("The lock screen stays lit, then the display powers down.")
      options: [
        { id: 5000, name: "5s" }, { id: 15000, name: "15s" }, { id: 30000, name: "30s" },
        { id: 60000, name: "1m" }, { id: 300000, name: "5m" },
        { id: -1, name: root.blankDelayIsCustom ? root.tr("Custom (%1m)").arg(Math.round(root.blankDelay / 60000)) : root.tr("Custom") },
        { id: 0, name: root.tr("Never") }
      ]
      current: root.keepDisplayOn ? 0 : (root.blankDelayIsCustom ? -1 : root.blankDelay)
      onPicked: function(id) {
        if (id === -1) root.beginCustomDelay()
        else root.setBlankAfter(id)
      }

      Rectangle {
        visible: root.customDelayEditing
        width: Style.space(150)
        height: visible ? Style.space(34) : 0
        radius: root.cornerRadius
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
        border.width: Math.max(1, Style.space(2))
        border.color: root.accent

        // The unit hint lives inside the box, right-aligned, and the
        // input reserves its width so typed digits never run under it.
        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: Style.space(10)
          text: root.tr("min, Enter")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        TypedInput {
          id: customDelayInput
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(80)
          verticalAlignment: TextInput.AlignVCenter
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          text: root.customDelayText
          onTextEdited: root.customDelayText = text
          focus: root.customDelayEditing
          validator: IntValidator { bottom: 1; top: 60 }

          Keys.onEscapePressed: {
            root.customDelayEditing = false
            root.keyCatcher.forceActiveFocus()
          }
          Keys.onReturnPressed: root.commitCustomDelay()
        }
      }
    }

    // A key pressed into a blanked screen only wakes it. Nothing
    // says when a panel is lit again, so this is how long the field
    // keeps ignoring keys after the wake has run.
    SettingRow {
      explorer: root
      visible: !root.keepDisplayOn
      label: root.tr("Ignore keys after waking")
      help: root.wakeGrace === 0
            ? root.tr("Only the keys pressed before the screen wakes are dropped.")
            : root.tr("Keys keep waking the screen without typing until the panel has had %1 to light up.")
                .arg(root.wakeGrace % 1000 === 0 ? root.wakeGrace / 1000 + "s" : root.wakeGrace + "ms")
      options: [{ id: 0, name: root.tr("Off") }, { id: 500, name: "0.5s" }, { id: 1000, name: "1s" }, { id: 2000, name: "2s" }]
      current: root.wakeGrace
      onPicked: function(id) { root.setWakeGrace(id) }
    }

    // Off by default: with it on, anyone at the machine can restart
    // it without knowing the password.
    SettingRow {
      explorer: root
      label: root.tr("Power buttons")
      help: root.powerActions
            ? root.tr("Sleep, restart and shut down sit in the corner. Each asks once more before it happens.")
            : root.tr("The lock screen takes a password and nothing else.")
      options: root.onOffOptions
      current: root.powerActions ? "on" : "off"
      onPicked: function(id) { root.setPowerActions(id === "on") }
    }

    // Off by default too: on, the lock screen says what is playing.
    SettingRow {
      explorer: root
      label: root.tr("Media controls")
      help: root.mediaControls
            ? root.tr("While something plays, its title sits at the top of the lock screen with previous, play or pause, and next.")
            : root.tr("The lock screen leaves what is playing alone, and does not say what it is.")
      options: root.onOffOptions
      current: root.mediaControls ? "on" : "off"
      onPicked: function(id) { root.setMediaControls(id === "on") }
    }
  }

  SettingSection {
    explorer: root
    title: root.tr("Sign-in and security")

    // Face unlock can look the moment the lock comes up, which
    // recognises whoever locked the screen and lets them straight
    // back in. Only shown when a face is enrolled.
    SettingRow {
      explorer: root
      visible: root.faceConfigured
      label: root.tr("Face unlock starts")
      help: root.faceStart === "always"
            ? root.tr("The camera looks as soon as the screen locks. Locking while you sit in front of it can unlock it again.")
            : root.faceStart === "off"
              ? root.tr("The camera only looks when you press Enter on an empty field or click the face button.")
              : root.tr("The camera looks when the display wakes, or when you come back to a screen that stayed lit, and on Enter or the face button. It never looks at a blanked screen.")
      options: [{ id: "wake", name: root.tr("On wake") }, { id: "always", name: root.tr("Always") }, { id: "off", name: root.tr("On request") }]
      current: root.faceStart
      onPicked: function(id) { root.setFaceStart(id) }
    }

    // Only once /etc/pam.d/omarchy-lock-fido2 is in place; off sends
    // the lock screen back to the password without touching PAM, so
    // the key still works everywhere else.
    SettingRow {
      explorer: root
      visible: root.fido2Installed
      label: root.tr("Security key")
      help: root.tr("Off sends the lock screen back to the password; the key still works for sudo and the rest.")
      options: root.fido2Options
      current: root.fido2Enabled ? "on" : "off"
      onPicked: function(id) { root.setFido2Enabled(id === "on") }
    }

    // Both off by default, and only with the key turned on above:
    // they follow the key, so without it they have nothing to do.
    SettingRow {
      explorer: root
      visible: root.fido2Installed && root.fido2Enabled
      label: root.tr("Lock when the key is removed")
      help: root.tr("Removing the security key locks the screen.")
      options: root.onOffOptions
      current: root.lockOnKeyRemoval ? "on" : "off"
      onPicked: function(id) { root.setLockOnKeyRemoval(id === "on") }
    }

    SettingRow {
      explorer: root
      visible: root.fido2Installed && root.fido2Enabled
      label: root.tr("Wake when the key is inserted")
      help: root.tr("Inserting the security key lights a dark lock screen, ready for a touch.")
      options: root.onOffOptions
      current: root.wakeOnKeyInsert ? "on" : "off"
      onPicked: function(id) { root.setWakeOnKeyInsert(id === "on") }
    }

    // Mistakes on your own way in are left out.
    SettingRow {
      explorer: root
      label: root.tr("Report failed attempts")
      help: root.awayReport
            ? root.tr("After you unlock, a notification says if somebody got it wrong while you were away.")
            : root.tr("Failed attempts are not reported.")
      options: root.onOffOptions
      current: root.awayReport ? "on" : "off"
      onPicked: function(id) { root.setAwayReport(id === "on") }
    }
  }

  SettingSection {
    explorer: root
    title: root.tr("System")

    SettingRow {
      explorer: root
      label: root.tr("Opens as")
      help: root.tr("What omarchy-shell lock explore opens first. The side panel has a button for the full explorer.")
      options: root.openAsOptions
      current: root.openAs
      onPicked: function(id) { root.setOpenAs(id) }
    }

    SettingRow {
      explorer: root
      label: root.tr("Side panel tour")
      help: root.tr("The three hints from the first time the side panel opened.")

      Rectangle {
        width: tourLabel.implicitWidth + Style.space(26)
        height: Style.space(34)
        radius: root.cornerRadius
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, tourArea.containsMouse ? 0.13 : 0.06)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)
        Text {
          id: tourLabel
          anchors.centerIn: parent
          text: root.tr("Show the tour")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        MouseArea {
          id: tourArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.replayTour()
        }
      }
    }

    SettingRow {
      explorer: root
      label: root.tr("Bar icon")
      help: root.tr("A lock in the bar. A click opens the same as omarchy-shell lock explore, a right click the full explorer.")
      options: root.shownHiddenOptions
      current: root.barIconShown ? "show" : "hide"
      onPicked: function(id) { root.setBarIcon(id === "show") }
    }

    // An entry in the app launcher and under Style in the Omarchy
    // menu. A plugin cannot add those on install, so it is a choice.
    SettingRow {
      explorer: root
      label: root.tr("Omarchy menu")
      help: root.tr("An entry in the app launcher and under Style in the Omarchy menu.")
      options: root.menuEntryOptions
      current: root.menuEntryInstalled ? "on" : "off"
      onPicked: function(id) { root.setMenuEntry(id === "on") }
    }

    SettingRow {
      explorer: root
      label: root.tr("Check this install")
      help: root.healthIssues.length === 0
            ? root.tr("Nothing missing that the explorer can see. The full check opens in a terminal, with a fix for anything it finds.")
            : root.tr("Opens a terminal with every check and its fix.")

      Rectangle {
        width: doctorLabel.implicitWidth + Style.space(26)
        height: Style.space(34)
        radius: root.cornerRadius
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, doctorArea.containsMouse ? 0.13 : 0.06)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)
        Text {
          id: doctorLabel
          anchors.centerIn: parent
          text: root.tr("Run the check")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        MouseArea {
          id: doctorArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.runDoctor()
        }
      }
    }
  }
}
