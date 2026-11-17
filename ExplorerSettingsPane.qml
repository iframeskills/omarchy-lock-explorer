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
  readonly property alias customDelayInput: settingsPage.customDelayInput
  readonly property alias settingsColumn: settingsColumn
  readonly property alias settingsFlick: settingsFlick
  required property var root
  id: settingsPane
  visible: !root.gridTab
  anchors.top: parent.bottom
  anchors.topMargin: Style.space(6)
  anchors.left: parent.left
  anchors.leftMargin: root.sidebarW + Style.space(20)
  anchors.right: parent.right
  anchors.rightMargin: root.mainTab === "editor" ? Style.space(40) : root.rightPanelW + Style.space(40)
  // Sized against the card (footer is not a sibling, so no anchor),
  // clipped and scrollable so tall content never draws over the nav.
  height: root.card.height - root.headerHeight - root.footerHeight - Style.space(80)

  Flickable {
    id: settingsFlick
    anchors.fill: parent
    clip: true
    contentWidth: width
    contentHeight: settingsColumn.implicitHeight + Style.space(20)
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 4000

  Column {
    id: settingsColumn
    width: root.settingsPane.width
    spacing: Style.space(14)

    ExplorerSettingsPage { id: settingsPage; root: root }

    ExplorerBootPage { id: bootPage; root: root }
  }
  }
}
