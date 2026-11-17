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
  readonly property alias customDelayInput: settingsPane.customDelayInput
  readonly property alias settingsColumn: settingsPane.settingsColumn
  readonly property alias settingsFlick: settingsPane.settingsFlick
  readonly property alias settingsPane: settingsPane
  readonly property alias searchInput: searchInput
  required property var root
  id: header
  z: 10
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.topMargin: root.card.contentTopInset
  anchors.leftMargin: root.card.contentLeftInset
  anchors.rightMargin: root.card.contentRightInset
  height: root.headerHeight

  Column {
    anchors.left: parent.left
    anchors.top: parent.top
    spacing: 3
    Row {
      spacing: Style.space(8)
      Text {
        text: "::"
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.display
        font.weight: Font.Bold
      }
      Text {
        text: root.tr("LOCK SCREEN EXPLORER")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.display
        font.weight: Font.Bold
        font.letterSpacing: 2
      }
    }
    Text {
      text: {
        if (root.wallpaperBroken) return root.tr("Wallpaper failed to load")
          + (root.wallpaperIsWebp ? " — " + root.tr("WebP needs %1, then %2").arg("sudo pacman -S qt6-imageformats").arg("omarchy restart shell") : "")
        if (root.mainTab === "settings") return root.tr("How the lock screen looks, unlocks and looks after itself")
        if (root.mainTab === "boot") return root.tr("The disk-passphrase screen at first boot") + " · " + root.tr("A broken theme falls back to a plain text prompt")
        if (root.mainTab === "animation" && root.multimediaMissing)
          return root.tr("Video designs need qt6-multimedia") + " · " + root.tr("Settings (U) installs it")
        if (root.gridTab && root.searchText.trim().length > 0)
          return (root.designs.length === 1 ? root.tr("1 design matches “%1”").arg(root.searchText.trim())
                                            : root.tr("%1 designs match “%2”").arg(root.designs.length).arg(root.searchText.trim()))
            + " · " + root.tr("Esc clears")
        if (root.mainTab === "favorites") return root.tr("%1 starred with F").arg(root.designs.length)
        if (root.mainTab === "animation") return root.tr("%1 animated lock screens").arg(Designs.animations(root.userDesigns).length)
        if (root.mainTab === "seasonal") return root.tr("%1 seasonal lock screens").arg(Designs.seasonal(root.userDesigns).length) + " · " + root.tr("In their own colors")
        if (root.mainTab === "editor") return root.bootEditing.length > 0 ? root.tr("Editing %1").arg(root.bootEditing) : root.tr("Make a matching lock screen and boot screen")
        return (root.mainTab === "styling" ? root.tr("%1 lock screen stylings").arg(Designs.stylings(root.userDesigns).length) + " · " : "") + root.currentThemeName + " · " + root.tr("Follows your theme")
      }
      textFormat: Text.PlainText
      color: root.wallpaperBroken ? root.danger : root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  Row {
    id: headerButtons
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.space(8)

    // Search over every design. The grid keys stay the grid's: the
    // field only takes the keyboard while it has focus (/ or a click),
    // and Enter, Down or Esc hands it back.
    Rectangle {
      id: searchBox
      visible: root.gridTab
      height: Style.space(28)
      width: Style.space(220)
      radius: root.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.searching ? 0.12 : 0.07)
      border.width: 1
      border.color: root.searching ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)

      TypedInput {
        id: searchInput
        anchors.left: parent.left
        anchors.right: searchHint.left
        anchors.leftMargin: Style.space(10)
        anchors.rightMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        text: root.searchText
        color: root.foreground
        selectionColor: root.accent
        selectedTextColor: Commons.Color.background
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        onTextEdited: root.searchText = text
        onActiveFocusChanged: root.searching = activeFocus
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.searchText.length > 0) root.searchText = ""
            else root.leaveSearch()
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                     || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.leaveSearch()
            event.accepted = true
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.searchText.length === 0
          text: root.tr("Search designs")
          color: root.muted
          font: searchInput.font
        }
      }

      Text {
        id: searchHint
        anchors.right: parent.right
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.searchText.length > 0 ? "✕" : "/"
        color: searchClear.containsMouse ? root.foreground : root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        MouseArea {
          id: searchClear
          anchors.fill: parent
          anchors.margins: -Style.space(4)
          hoverEnabled: true
          onClicked: { if (root.searchText.length > 0) root.searchText = ""; else root.focusSearch() }
        }
      }

      MouseArea {
        anchors.fill: parent
        anchors.rightMargin: searchHint.width + Style.space(14)
        z: -1
        onClicked: root.focusSearch()
      }
    }

    // Back to the side panel, on the design selected here.
    Rectangle {
      visible: root.gridTab
      height: Style.space(28)
      width: sidePanelLabel.implicitWidth + Style.space(20)
      radius: root.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, sidePanelArea.containsMouse ? 0.14 : 0.07)
      border.width: 1
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
      Behavior on color { ColorAnimation { duration: 100 } }
      Text {
        id: sidePanelLabel
        anchors.centerIn: parent
        text: root.tr("Side panel") + " · O"
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
      MouseArea {
        id: sidePanelArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showPanel()
      }
    }

    // Avatar button: click to pick a picture with the normal file
    // dialog, the x clears it back to the user's initial.
    Rectangle {
      id: avatarButton
      height: Style.space(28)
      width: avatarRow.implicitWidth + Style.space(16)
      radius: root.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, avatarArea.containsMouse ? 0.14 : 0.07)
      border.width: 1
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
      Behavior on color { ColorAnimation { duration: 100 } }

      Row {
        id: avatarRow
        anchors.centerIn: parent
        spacing: Style.space(8)

        Avatar {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(20)
          source: root.avatarUrl
          initial: root.userInitial
          fontSize: Style.font.caption
          fillColor: root.accent
          textColor: Commons.Color.background
          shadow: false
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.tr(root.hasAvatar ? "Avatar" : "Add avatar")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.hasAvatar
          text: "✕"
          color: clearArea.containsMouse ? root.foreground : root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          MouseArea {
            id: clearArea
            anchors.fill: parent
            anchors.margins: -Style.space(4)
            hoverEnabled: true
            onClicked: root.clearAvatar()
          }
        }
      }

      MouseArea {
        id: avatarArea
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: root.pickAvatar()
      }
    }

    Rectangle {
      anchors.verticalCenter: avatarButton.verticalCenter
      width: activeLabel.implicitWidth + Style.space(20); height: Style.space(28); radius: root.cornerRadius
      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
      border.width: 1; border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
      Text {
        id: activeLabel
        anchors.centerIn: parent
        text: root.selectionError || root.tr("Active: %1").arg(Designs.byId(root.activeDesignId, root.userDesigns) ? Designs.byId(root.activeDesignId, root.userDesigns).name : root.activeDesignId)
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
    }
  }

  // (tabs moved to the left sidebar)

  // Category chips removed in the redesign (the sidebar splits stylings
  // from animations instead).
  Row {
    visible: false
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(10)
    spacing: Style.space(8)
    Repeater {
      model: root.categories
      Rectangle {
        id: chip
        required property var modelData
        readonly property bool current: modelData.id === root.category
        width: chipLabel.implicitWidth + Style.space(24)
        height: Style.space(30)
        radius: root.cornerRadius
        color: current ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, chipArea.containsMouse ? 0.12 : 0.06)
        border.width: 1
        border.color: current ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
          id: chipLabel
          anchors.centerIn: parent
          text: root.tr(chip.modelData.name)
          textFormat: Text.PlainText
          color: chip.current ? Commons.Color.background : root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: chip.current ? Font.DemiBold : Font.Normal
        }
        MouseArea {
          id: chipArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.setCategory(chip.modelData.id)
        }
      }
    }
  }

  // The two settings pages live where the grid otherwise is.
  ExplorerSettingsPane { id: settingsPane; root: root }
}
