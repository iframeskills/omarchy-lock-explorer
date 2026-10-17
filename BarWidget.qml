import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// A lock in the bar. The bar loads this as a custom QML module, put into the
// layout by extras/bar-icon.sh (Settings > System > Bar icon). A click opens
// what `omarchy-shell lock explore` opens (the side panel or the full
// explorer, see Settings > System > Opens as), a right click always the full
// explorer.
Item {
  id: root

  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌾"
    slotSize: Style.bar.statusSlot
    tooltipText: "Lock screen settings"

    // A lock with a small cog at its lower right, so it reads as the lock
    // screen's settings and not as "lock now". No Nerd Font glyph has both.
    iconComponent: Component {
      Item {
        Text {
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: -Math.round(button.fontSize * 0.12)
          anchors.verticalCenterOffset: -Math.round(button.fontSize * 0.08)
          text: "󰌾"
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          color: button.foreground
        }
        Text {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          text: "󰒓"
          font.family: button.fontFamily
          font.pixelSize: Math.round(button.fontSize * 0.6)
          color: button.foreground
        }
      }
    }

    onPressed: function(b) {
      if (b === Qt.RightButton) Quickshell.execDetached(["omarchy-shell", "lock", "exploreFull"])
      else Quickshell.execDetached(["omarchy-shell", "lock", "explore"])
    }
  }
}
