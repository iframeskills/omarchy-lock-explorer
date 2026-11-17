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
  required property var root
          id: bootPage
  // Sized to the pane, not to the widest child: children bind to
  // parent.width, so an unset width here balloons to the longest
  // unwrapped text and pushes the Apply button under the preview.
  width: parent.width
  visible: root.mainTab === "boot" || root.mainTab === "editor"
  spacing: Style.space(14)

  Text {
    visible: root.mainTab === "boot"
    width: parent.width
    wrapMode: Text.WordWrap
    text: root.tr("Now: %1").arg(root.bootNowName) + (root.bootAppliedTheme.length > 0 ? " \u00b7 " + root.tr("Baked from %1").arg(root.bootAppliedTheme) : "")
    textFormat: Text.PlainText
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  // Apply banner: nothing is built until you press Apply.
  Rectangle {
    visible: root.mainTab === "boot" && (root.bootDirty || root.bootApplying)
    width: parent.width
    height: applyBannerRow.implicitHeight + Style.space(20)
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
    border.width: 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)

    Row {
      id: applyBannerRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(14)
      anchors.rightMargin: Style.space(14)
      spacing: Style.space(14)

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(8); height: Style.space(8); radius: width / 2
        color: root.accent
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - applyBtn.width - Style.space(50)
        wrapMode: Text.WordWrap
        text: root.bootApplying
          ? root.tr("Applying the boot theme\u2026")
          : root.tr("Set to %1. Applying writes the boot theme to the EFI partition and asks for your password.").arg(root.bootDesiredName)
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        id: applyBtn
        anchors.verticalCenter: parent.verticalCenter
        width: applyBtnLabel.implicitWidth + Style.space(24)
        height: Style.space(30)
        radius: root.cornerRadius
        opacity: root.bootApplying ? 0.5 : 1
        color: root.accent
        Text {
          id: applyBtnLabel
          anchors.centerIn: parent
          text: root.bootApplying ? root.tr("Building\u2026") : root.tr("Apply")
          color: Commons.Color.background
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.DemiBold
        }
        MouseArea {
          anchors.fill: parent
          enabled: !root.bootApplying
          onClicked: root.applyPendingBoot()
        }
      }
    }
  }

  Row {
    visible: root.mainTab === "boot"
    spacing: Style.space(20)

    Rectangle {
      width: followRow.implicitWidth + Style.space(8)
      height: Style.space(30)
      color: "transparent"

      Row {
        id: followRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(18)
          height: Style.space(18)
          radius: root.cornerRadius
          color: root.bootSetting === "follow" ? root.accent : "transparent"
          border.width: Math.max(1, Style.space(2))
          border.color: root.bootSetting === "follow" ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)

          Text {
            anchors.centerIn: parent
            visible: root.bootSetting === "follow"
            text: "\u2713"
            color: Commons.Color.background
            font.pixelSize: Style.font.caption
            font.weight: Font.Bold
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Text {
            text: root.tr("Follow my lock screen")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            text: root.followHint
            textFormat: Text.PlainText
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        anchors.margins: -Style.space(4)
        onClicked: root.toggleFollow()
      }
    }

    Rectangle {
      width: resyncRow.implicitWidth + Style.space(8)
      height: Style.space(30)
      color: "transparent"

      Row {
        id: resyncRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(18)
          height: Style.space(18)
          radius: root.cornerRadius
          color: root.bootResync ? root.accent : "transparent"
          border.width: Math.max(1, Style.space(2))
          border.color: root.bootResync ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)

          Text {
            anchors.centerIn: parent
            visible: root.bootResync
            text: "\u2713"
            color: Commons.Color.background
            font.pixelSize: Style.font.caption
            font.weight: Font.Bold
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.tr("Re-apply when the Omarchy theme changes")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      MouseArea {
        anchors.fill: parent
        anchors.margins: -Style.space(4)
        onClicked: root.toggleBootResync()
      }
    }

    Rectangle {
      // Rotation ships hidden: it has not been tested end to
      // end, and each step asks through polkit after login.
      visible: false
      width: rotateRow.implicitWidth + Style.space(8)
      height: Style.space(30)
      color: "transparent"

      Row {
        id: rotateRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(18)
          height: Style.space(18)
          radius: root.cornerRadius
          color: root.bootRotating ? root.accent : "transparent"
          border.width: Math.max(1, Style.space(2))
          border.color: root.bootRotating ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)

          Text {
            anchors.centerIn: parent
            visible: root.bootRotating
            text: "\u2713"
            color: Commons.Color.background
            font.pixelSize: Style.font.caption
            font.weight: Font.Bold
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Text {
            text: root.tr("Rotate boot screens")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            // The toggles row can meet the preview panel; give in
            // gracefully instead of drawing under it.
            width: Math.min(implicitWidth, Style.space(230))
            elide: Text.ElideRight
            text: root.bootRotating
              ? root.tr("Tick the cards below") + " \u00b7 " + root.tr("advances one per boot (%1 picked)").arg(root.bootRotation.length)
              : root.tr("A different one each boot, set up once")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        anchors.margins: -Style.space(4)
        onClicked: root.toggleRotationMode()
      }
    }
  }

  Row {
    visible: root.mainTab === "boot"
    spacing: Style.space(6)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.tr("Clip length")
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: [0, 2, 4, 6]
        Rectangle {
          id: clipLen
          required property int modelData
          readonly property bool current: modelData === root.bootClipSeconds
          width: clipLenLabel.implicitWidth + Style.space(16)
          height: Style.space(24)
          radius: root.cornerRadius
          color: current ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, clipLenArea.containsMouse ? 0.12 : 0.06)
          Behavior on color { ColorAnimation { duration: 100 } }

          Text {
            id: clipLenLabel
            anchors.centerIn: parent
            text: clipLen.modelData === 0 ? root.tr("Full") : clipLen.modelData + "s"
            color: clipLen.current ? Commons.Color.background : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.weight: clipLen.current ? Font.DemiBold : Font.Normal
          }

          MouseArea {
            id: clipLenArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.setBootClipSeconds(clipLen.modelData)
          }
        }
      }
    }

  Flow {
    visible: root.mainTab === "boot"
    width: root.card.width - root.sidebarW - root.rightPanelW - Style.space(120)
    spacing: Style.space(14)

    Repeater {
      model: root.bootCards
      Column {
        id: bootCard
        required property var modelData
        readonly property bool picked: root.bootSetting === modelData.id || root.bootFollowTarget === modelData.id
        readonly property bool onDisk: root.bootApplied === modelData.id || (modelData.id === "stock" && root.bootApplied.length === 0)
        readonly property bool editable: modelData.id.indexOf("custom:") === 0
        spacing: Style.space(6)
        opacity: root.bootApplying ? 0.55 : 1

        Rectangle {
          width: Style.space(252)
          height: Style.space(142)
          radius: root.cornerRadius
          color: root.shade(0.3)
          border.width: bootCard.picked ? Math.max(2, Style.space(3)) : 1
          border.color: bootCard.picked ? root.accent
                      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, bootCardArea.containsMouse ? 0.4 : 0.15)
          clip: true
          Behavior on border.color { ColorAnimation { duration: 100 } }

          Text {
            anchors.centerIn: parent
            text: root.tr("rendering preview...")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Image {
            anchors.fill: parent
            anchors.margins: 1
            source: root.bootCardPreview(bootCard.modelData.id)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
          }

          Rectangle {
            visible: bootCard.onDisk && !root.bootRotating
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.space(8)
            width: onDiskLabel.implicitWidth + Style.space(14)
            height: Style.space(24)
            radius: root.cornerRadius
            color: root.accent

            Text {
              id: onDiskLabel
              anchors.centerIn: parent
              text: "\u2713 " + root.tr("Applied")
              color: Commons.Color.background
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.weight: Font.DemiBold
            }
          }

          MouseArea {
            id: bootCardArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.bootRotating
              ? (bootCard.modelData.id !== "stock" ? root.toggleInRotation(bootCard.modelData.id) : undefined)
              : root.setBoot(bootCard.modelData.id)
          }

          // Rotation membership tick, shown while rotating.
          Rectangle {
            visible: root.bootRotating && bootCard.modelData.id !== "stock"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Style.space(8)
            width: Style.space(26)
            height: Style.space(26)
            radius: root.cornerRadius
            color: root.inRotation(bootCard.modelData.id) ? root.accent : root.shade(0.55)
            border.width: 1
            border.color: root.inRotation(bootCard.modelData.id) ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)

            Text {
              anchors.centerIn: parent
              text: root.inRotation(bootCard.modelData.id) ? "\u2713" : "+"
              color: root.inRotation(bootCard.modelData.id) ? Commons.Color.background : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.weight: Font.Bold
            }
          }

          Rectangle {
            visible: bootCard.editable
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: Style.space(8)
            width: bootEditLabel.implicitWidth + Style.space(14)
            height: Style.space(24)
            radius: root.cornerRadius
            color: root.shade(bootEditArea.containsMouse ? 0.8 : 0.55)
            border.width: 1
            border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)

            Text {
              id: bootEditLabel
              anchors.centerIn: parent
              text: root.tr("Edit")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: bootEditArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.openBootEditor(bootCard.modelData.id.substring(7))
            }
          }

          // Your own videos and layouts can be deleted; press twice.
          Rectangle {
            visible: (bootCard.modelData.id.indexOf("video:") === 0 || bootCard.editable) && !root.bootRotating
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: Style.space(8)
            width: bootDelLabel.implicitWidth + Style.space(14)
            height: Style.space(24)
            radius: root.cornerRadius
            color: root.confirmingDelete === bootCard.modelData.id ? root.danger : root.shade(bootDelArea.containsMouse ? 0.8 : 0.55)
            border.width: 1
            border.color: root.confirmingDelete === bootCard.modelData.id ? Qt.lighter(root.danger, 1.3) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)

            Text {
              id: bootDelLabel
              anchors.centerIn: parent
              text: root.tr(root.confirmingDelete === bootCard.modelData.id ? "Sure?" : "Delete")
              color: root.confirmingDelete === bootCard.modelData.id ? Commons.Color.background : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: bootDelArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.deleteBootCard(bootCard.modelData.id)
            }
          }
        }

        Row {
          spacing: Style.space(8)

          Text {
            text: bootCard.modelData.name
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.weight: bootCard.picked ? Font.DemiBold : Font.Normal
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bootCard.modelData.kind
            textFormat: Text.PlainText
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.9)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }

    // Snapshot the current lock screen as a static boot background.
    Column {
      spacing: Style.space(6)

      Rectangle {
        width: Style.space(252)
        height: Style.space(142)
        radius: root.cornerRadius
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, snapshotCardArea.containsMouse ? 0.16 : 0.08)
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
        Behavior on color { ColorAnimation { duration: 100 } }

        Column {
          anchors.centerIn: parent
          spacing: Style.space(4)
          width: parent.width - Style.space(24)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "+"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.tr("Snapshot this lock screen")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        MouseArea {
          id: snapshotCardArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.snapshotActiveDesign()
        }
      }

      Text {
        text: root.tr("%1 as a still").arg(Designs.byId(root.activeDesignId, root.userDesigns) ? Designs.byId(root.activeDesignId, root.userDesigns).name : root.tr("current"))
        textFormat: Text.PlainText
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

  }

  // Editor tab, gallery view: existing custom layouts to edit,
  // plus a card to start a new one.
  Flow {
    visible: root.mainTab === "editor" && root.bootEditing.length === 0
    width: root.card.width - root.sidebarW - root.rightPanelW - Style.space(120)
    spacing: Style.space(14)

    Repeater {
      model: root.bootCustomDesigns
      Column {
        id: editorCard
        required property var modelData
        spacing: Style.space(6)

        Rectangle {
          width: Style.space(252)
          height: Style.space(142)
          radius: root.cornerRadius
          color: root.shade(0.3)
          border.width: 1
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, editorCardArea.containsMouse ? 0.4 : 0.15)
          clip: true
          Behavior on border.color { ColorAnimation { duration: 100 } }

          Image {
            anchors.fill: parent
            anchors.margins: 1
            source: root.bootCardPreview("custom:" + editorCard.modelData)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
          }

          MouseArea {
            id: editorCardArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.openBootEditor(editorCard.modelData)
          }
        }

        Text {
          text: editorCard.modelData
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }

    Column {
      spacing: Style.space(6)

      Rectangle {
        width: Style.space(252)
        height: Style.space(142)
        radius: root.cornerRadius
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, newBootArea.containsMouse ? 0.10 : 0.04)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
        Behavior on color { ColorAnimation { duration: 100 } }

        Column {
          anchors.centerIn: parent
          spacing: Style.space(4)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "+"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.tr("New layout")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        MouseArea {
          id: newBootArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.newBootDesign()
        }
      }

      Text {
        text: root.tr("One layout, both screens")
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  // Unified layout editor: fields on the left, the matching lock
  // and boot previews on the right. Changes save and re-render.
  Row {
    visible: root.mainTab === "editor" && root.bootEditing.length > 0
    spacing: Style.space(24)

    Column {
      width: Style.space(360)
      spacing: Style.space(12)

      Text {
        text: root.bootEditing
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
      }

      BootField {
        label: root.tr("Background")
        control: "dropdown"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("background", "theme")
        optionNames: root.bootOptionNames
        options: ["theme", "wallpaper"]
        onSelected: function(o) { root.bootFormSet("background", o) }
      }
      BootField {
        label: root.tr("Logo")
        control: "dropdown"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("logo", "theme")
        optionNames: root.bootOptionNames
        options: ["theme", "none"]
        onSelected: function(o) { root.bootFormSet("logo", o) }
      }
      BootField {
        label: root.tr("Title")
        control: "text"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("title", "")
        onEdited: function(t) { root.bootFormSet("title", t) }
      }
      BootField {
        label: root.tr("Subtitle")
        control: "text"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("subtitle", "")
        onEdited: function(t) { root.bootFormSet("subtitle", t) }
      }
      BootField {
        label: root.tr("Clock (lock screen)")
        control: "toggle"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        on: root.bootFormGet("clock", "on") === "on"
        onToggled: root.bootFormSet("clock", root.bootFormGet("clock", "on") === "on" ? "off" : "on")
      }
      BootField {
        label: root.tr("Passphrase field")
        control: "dropdown"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("entry", "pill")
        optionNames: root.bootOptionNames
        options: ["pill", "line", "none"]
        onSelected: function(o) { root.bootFormSet("entry", o) }
      }
      BootField {
        label: root.tr("Scanlines")
        control: "toggle"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        on: root.bootFormGet("scanlines", "off") === "on"
        onToggled: root.bootFormSet("scanlines", root.bootFormGet("scanlines", "off") === "on" ? "off" : "on")
      }
      BootField {
        label: root.tr("Title position")
        control: "stepper"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("title_y", "18")
        onStep: function(d) { root.bootFormSet("title_y", Math.max(0, Math.min(100, (parseInt(root.bootFormGet("title_y", "18")) || 18) + d * 4))) }
      }
      BootField {
        label: root.tr("Title size")
        control: "stepper"
        suffix: ""
        rev: root.bootFormRev
        onEscaped: root.handleEscape()
        value: root.bootFormGet("title_size", "26")
        onStep: function(d) { root.bootFormSet("title_size", Math.max(10, Math.min(64, (parseInt(root.bootFormGet("title_size", "26")) || 26) + d * 2))) }
      }
      BootField {
        label: root.tr("Subtitle position")
        control: "stepper"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("subtitle_y", "26")
        onStep: function(d) { root.bootFormSet("subtitle_y", Math.max(0, Math.min(100, (parseInt(root.bootFormGet("subtitle_y", "26")) || 26) + d * 4))) }
      }
      BootField {
        label: root.tr("Subtitle size")
        control: "stepper"
        suffix: ""
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("subtitle_size", "15")
        onStep: function(d) { root.bootFormSet("subtitle_size", Math.max(8, Math.min(40, (parseInt(root.bootFormGet("subtitle_size", "15")) || 15) + d * 1))) }
      }
      BootField {
        label: root.tr("Field position")
        control: "stepper"
        rev: root.bootFormRev
        onEscaped: { root.keyCatcher.forceActiveFocus(); root.handleEscape() }
        value: root.bootFormGet("entry_y", "72")
        onStep: function(d) { root.bootFormSet("entry_y", Math.max(0, Math.min(100, (parseInt(root.bootFormGet("entry_y", "72")) || 72) + d * 4))) }
      }
    }

    Column {
      spacing: Style.space(14)

      // Both previews on one row so neither hides below the fold.
      Row {
        spacing: Style.space(14)

        Column {
          spacing: Style.space(6)
          Text {
            text: root.tr("Lock screen")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.weight: Font.DemiBold
          }
          Rectangle {
            id: edLockRect
            width: Math.floor((root.settingsColumn.width - Style.space(360) - Style.space(24) - Style.space(14)) / 2)
            height: Math.round(width * 9 / 16)
            radius: root.cornerRadius
            color: root.shade(0.3)
            border.width: 1
            border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
            clip: true
            Text {
              anchors.centerIn: parent
              visible: editorLockPreview.status !== Image.Ready
              text: root.tr("rendering preview...")
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Rectangle {
              visible: root.bootEditBusy
              z: 2
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: Style.space(8)
              width: busyLabel1.implicitWidth + Style.space(14)
              height: Style.space(22)
              radius: root.cornerRadius
              color: root.shade(0.6)
              Text {
                id: busyLabel1
                anchors.centerIn: parent
                text: root.tr("re-rendering…")
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                SequentialAnimation on opacity {
                  running: root.bootEditBusy
                  loops: Animation.Infinite
                  NumberAnimation { from: 1; to: 0.35; duration: 600 }
                  NumberAnimation { from: 0.35; to: 1; duration: 600 }
                }
              }
            }
            Image {
              id: editorLockPreview
              anchors.fill: parent; anchors.margins: 1
              source: "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/lock-explorer-boot-previews/custom-" + root.bootEditing + "-lock-" + root.bootCurrentTheme + ".png?v=" + root.bootPreviewsVersion
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
            }
          }
        }

        Column {
          spacing: Style.space(6)
          Text {
            text: root.tr("Boot screen")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.weight: Font.DemiBold
          }
          Rectangle {
            width: edLockRect.width
            height: edLockRect.height
            radius: root.cornerRadius
            color: root.shade(0.3)
            border.width: 1
            border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
            clip: true
            Text {
              anchors.centerIn: parent
              visible: editorBootPreview.status !== Image.Ready
              text: root.tr("rendering preview...")
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Rectangle {
              visible: root.bootEditBusy
              z: 2
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: Style.space(8)
              width: busyLabel2.implicitWidth + Style.space(14)
              height: Style.space(22)
              radius: root.cornerRadius
              color: root.shade(0.6)
              Text {
                id: busyLabel2
                anchors.centerIn: parent
                text: root.tr("re-rendering…")
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                SequentialAnimation on opacity {
                  running: root.bootEditBusy
                  loops: Animation.Infinite
                  NumberAnimation { from: 1; to: 0.35; duration: 600 }
                  NumberAnimation { from: 0.35; to: 1; duration: 600 }
                }
              }
            }
            Image {
              id: editorBootPreview
              anchors.fill: parent; anchors.margins: 1
              source: root.bootCardPreview("custom:" + root.bootEditing)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
            }
          }
        }
      }

      Text {
        width: edLockRect.width * 2 + Style.space(14)
        wrapMode: Text.WordWrap
        text: root.tr("Changes save and re-render automatically") + " \u00b7 " + root.tr("Esc goes back") + " \u00b7 "
          + root.tr("apply the boot screen from its card, pick the lock screen under Styling or Animation. $USER and $HOST expand.")
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
