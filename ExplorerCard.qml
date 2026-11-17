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

BorderSurface {
  readonly property alias footer: footer
  readonly property alias grid: grid
  readonly property alias customDelayInput: header.customDelayInput
  readonly property alias settingsColumn: header.settingsColumn
  readonly property alias settingsFlick: header.settingsFlick
  readonly property alias settingsPane: header.settingsPane
  readonly property alias searchInput: header.searchInput
  readonly property alias header: header
  required property var root
  id: card
  visible: !root.fullPreview && !root.editing && !root.sideView
  width: root.cardWidth
  height: root.cardHeight
  radius: root.cornerRadius
  anchors.centerIn: parent
  color: root.background
  borderSpec: root.borderSpec
  padding: root.contentMargin

  MouseArea { anchors.fill: parent; onClicked: {} }

  ExplorerHeader { id: header; root: root }

  // Left nav sidebar (redesign): sections as a vertical list with a
  // border-left accent, counts on the right.
  Column {
    id: sidebar
    anchors.top: header.bottom
    anchors.bottom: footer.top
    anchors.left: parent.left
    anchors.leftMargin: root.card.contentLeftInset
    anchors.topMargin: Style.space(4)
    anchors.bottomMargin: Style.space(8)
    width: root.sidebarW
    spacing: Style.space(2)

    Repeater {
      model: {
        var r = root.service ? root.service.designsRevision : 0
        return [
          { id: "styling", name: "Styling", count: Designs.stylings(root.userDesigns).length },
          { id: "animation", name: "Animation", count: Designs.animations(root.userDesigns).length },
          { id: "seasonal", name: "Seasonal", count: Designs.seasonal(root.userDesigns).length },
          { id: "favorites", name: "Favorites", count: root.favoriteDesigns().length },
          { id: "boot", name: "Boot screen", count: 0 },
          { id: "settings", name: "Settings", count: 0 }
        ]
      }
      Rectangle {
        id: navItem
        required property var modelData
        readonly property bool current: modelData.id === root.mainTab
        width: root.sidebarW
        height: Style.space(36)
        color: navItem.current ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
               : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, navItemArea.containsMouse ? 0.05 : 0.0)
        Behavior on color { ColorAnimation { duration: 100 } }

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Math.max(2, Style.space(2))
          color: navItem.current ? root.accent : "transparent"
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
          text: (root.tr(navItem.modelData.name) + (navItem.modelData.id === "boot" && root.bootApplying ? " ·" : "")).toUpperCase()
          color: navItem.current ? Commons.Color.menu.text : root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: navItem.current ? Font.Bold : Font.Normal
          font.letterSpacing: 1
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
          visible: navItem.modelData.count > 0
          text: navItem.modelData.count
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        // Pending dot when the boot screen has an unapplied change.
        Rectangle {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(12)
          anchors.verticalCenter: parent.verticalCenter
          visible: navItem.modelData.id === "boot" && root.bootApplying
          width: Style.space(7); height: Style.space(7); radius: width / 2
          color: root.accent
        }

        MouseArea {
          id: navItemArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.mainTab = navItem.modelData.id
        }
      }
    }
  }

  // "+ New design" at the top of the three: the visual designer, where a
  // lock screen is put together by dragging pieces onto the screen.
  Rectangle {
    id: newDesignBtn
    anchors.left: parent.left
    anchors.leftMargin: root.card.contentLeftInset
    anchors.bottom: newClipBtn.top
    anchors.bottomMargin: Style.space(8)
    width: root.sidebarW
    height: Style.space(34)
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, newDesignArea.containsMouse ? 0.28 : 0.14)
    border.width: 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
      anchors.centerIn: parent
      text: "+ " + root.tr("New design")
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.DemiBold
    }

    MouseArea {
      id: newDesignArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.newDesignerDesign()
    }
  }

  // "+ New clip" above it: your own video as an unlock clip design.
  Rectangle {
    id: newClipBtn
    anchors.left: parent.left
    anchors.leftMargin: root.card.contentLeftInset
    anchors.bottom: newStylingBtn.top
    anchors.bottomMargin: Style.space(8)
    width: root.sidebarW
    height: Style.space(34)
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, newClipArea.containsMouse ? 0.08 : 0.0)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
      anchors.centerIn: parent
      text: "+ " + root.tr("New clip")
      color: newClipArea.containsMouse ? Commons.Color.menu.text : root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    MouseArea {
      id: newClipArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.newClipDesign()
    }
  }

  // "+ New styling" pinned to the bottom of the sidebar.
  Rectangle {
    id: newStylingBtn
    anchors.left: parent.left
    anchors.leftMargin: root.card.contentLeftInset
    anchors.bottom: footer.top
    anchors.bottomMargin: Style.space(14)
    width: root.sidebarW
    height: Style.space(34)
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, newStylingArea.containsMouse ? 0.08 : 0.0)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
      anchors.centerIn: parent
      text: "+ " + root.tr("New styling")
      color: newStylingArea.containsMouse ? Commons.Color.menu.text : root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    MouseArea {
      id: newStylingArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.newBootDesign()
    }
  }

  // Right live-preview panel (redesign): the current lock screen rendered
  // live, plus the boot-screen preview.
  ExplorerPreviewPanel { id: previewPanel; root: root }

  // What an empty grid means: nothing starred yet, or no match.
  Text {
    visible: root.gridTab && root.designs.length === 0
    anchors.centerIn: grid
    width: Math.min(grid.width, Style.space(420))
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    textFormat: Text.PlainText
    text: root.searchText.trim().length > 0
          ? root.tr("No design matches “%1”. Esc clears the search.").arg(root.searchText.trim())
          : root.tr("Nothing starred yet. Press F on a design, or click the star on its card, to keep it here.")
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  ExplorerGrid { id: grid; root: root }

  // Above the grid: every design has a MouseArea of its own and so does the
  // cell, and those eat wheel events before the grid ever sees them. No
  // buttons, so clicks and drags still reach the cells underneath.
  MouseArea {
    anchors.fill: grid
    acceptedButtons: Qt.NoButton
    onWheel: function(wheel) {
      // Touchpads send pixel deltas with a coarse angle alongside them.
      // Reading the angle for both turned every small two finger move into
      // a whole notch, so use the pixels when they are there.
      var dy = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y * 1.2
      var next = grid.contentY - dy
      grid.contentY = Math.max(0, Math.min(Math.max(0, grid.contentHeight - grid.height), next))
    }
  }

  Rectangle {
    anchors.top: grid.top
    anchors.bottom: grid.bottom
    anchors.right: parent.right
    anchors.rightMargin: root.card.contentRightInset - Style.space(4)
    width: 4
    radius: 2
    visible: grid.visible && grid.contentHeight > grid.height
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
    Rectangle {
      width: parent.width
      radius: 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
      height: Math.max(24, parent.height * grid.height / Math.max(1, grid.contentHeight))
      y: (parent.height - height) * (grid.contentY / Math.max(1, grid.contentHeight - grid.height))
    }
  }

  Item {
    id: footer
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottomMargin: root.card.contentBottomInset
    anchors.leftMargin: root.card.contentLeftInset
    anchors.rightMargin: root.card.contentRightInset
    height: root.footerHeight
    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: {
        if (root.mainTab === "editor") return root.tr("Changes save automatically   ·   Esc: back")
        if (root.mainTab === "boot") return root.tr("Click a card to pick it   ·   Apply writes it to the boot image   ·   B / Esc: back   ·   ?: all keys")
        if (root.mainTab === "settings") return root.tr("Arrows / PgUp / PgDn: scroll   ·   U / Esc: back   ·   ?: all keys")
        return root.tr("Arrows: browse   Space: preview   Enter: select   /: search   F: favorite   D: designer   U: settings   ?: all keys   Esc: close")
      }
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }
}
