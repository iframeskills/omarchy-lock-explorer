import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import "designs"
import "Designer.js" as D
import "ExplorerStrings.js" as UiText

// The visual designer: a palette of pieces on the left, the lock screen at
// its real size in the middle, and the settings for whatever is selected on
// the right.
//
// The layout is a list of LayoutNode objects; the canvas renders it through
// the same DesignerItem the generated file uses, so the canvas is the lock
// screen, not a drawing of it. Saving writes the QML, with the layout itself
// on one comment line for the next time it is opened.
Rectangle {
  required property var designer
  id: artEditor
  anchors.fill: parent
  visible: designer.artEditing
  color: Qt.rgba(designer.background.r, designer.background.g, designer.background.b, 0.97)
  z: 90

  // Nothing behind this reacts while it is up.
  MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

  Keys.onEscapePressed: { designer.artEditing = false; designer.artKey = ""; designer.focusCanvas() }
  Keys.onReturnPressed: designer.artApply()
  focus: designer.artEditing
  onVisibleChanged: if (visible) forceActiveFocus()

  Column {
    anchors.centerIn: parent
    spacing: Style.space(12)

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: designer.tr("DRAW THE SHAPE")
      color: designer.muted
      font.family: designer.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 2
    }

    // The grid, sized to fit whatever is left of the screen.
    Rectangle {
      id: gridBox
      anchors.horizontalCenter: parent.horizontalCenter
      // ttfx draws every cell as a character of the theme's monospace font,
      // about twice as tall as it is wide. Square cells showed the shape at
      // double its width, so the cells take the font's own proportions,
      // measured the way TtfxText measures them.
      readonly property real aspect: cellProbe.contentWidth > 0
        ? Math.max(1, Math.ceil(cellProbe.contentHeight) / (cellProbe.contentWidth / 10)) : 2
      readonly property real cell: Math.max(3, Math.floor(Math.min(
        (designer.width * 0.8) / Math.max(1, designer.artCols),
        (designer.height * 0.6) / Math.max(1, designer.artRows * aspect))))
      readonly property real cellH: Math.round(cell * aspect)
      width: designer.artCols * cell + 2
      height: designer.artRows * cellH + 2

      Text {
        id: cellProbe
        visible: false
        text: "MMMMMMMMMM"
        font.family: Style.font.family
        font.pixelSize: 100
      }
      color: designer.well
      border.width: 1
      border.color: designer.line

      Item {
        id: cells
        x: 1
        y: 1
        width: designer.artCols * gridBox.cell
        height: designer.artRows * gridBox.cellH

        Repeater {
          model: designer.artRows * designer.artCols

          Rectangle {
            required property int index
            readonly property int row: Math.floor(index / Math.max(1, designer.artCols))
            readonly property int col: index % Math.max(1, designer.artCols)
            x: col * gridBox.cell
            y: row * gridBox.cellH
            width: gridBox.cell
            height: gridBox.cellH
            color: designer.artGrid[row] && designer.artGrid[row][col] ? designer.accent : "transparent"
            border.width: gridBox.cell >= 8 ? 1 : 0
            border.color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b, 0.08)
          }
        }

        // One area for the whole grid: a press decides whether this stroke
        // fills or clears, and the drag paints every cell it crosses.
        MouseArea {
          anchors.fill: parent
          hoverEnabled: false
          function cellAt(mx, my) {
            return { r: Math.floor(my / gridBox.cellH), c: Math.floor(mx / gridBox.cell) }
          }
          onPressed: function(mouse) {
            var at = cellAt(mouse.x, mouse.y)
            if (at.r < 0 || at.r >= designer.artRows || at.c < 0 || at.c >= designer.artCols) return
            designer.artPaint = !designer.artGrid[at.r][at.c]
            designer.artSet(at.r, at.c, designer.artPaint)
          }
          onPositionChanged: function(mouse) {
            if (!pressed) return
            var at = cellAt(mouse.x, mouse.y)
            designer.artSet(at.r, at.c, designer.artPaint)
          }
        }
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(6)

      DesignerButton {
        label: designer.tr("Omarchy logo")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artLoadLogo()
      }
      DesignerButton {
        label: designer.tr("Clear")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artFill(false)
      }
      DesignerButton {
        label: designer.tr("Invert")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artInvert()
      }
      DesignerButton {
        label: designer.tr("Wider")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artResize(4, 0)
      }
      DesignerButton {
        label: designer.tr("Narrower")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artResize(-4, 0)
      }
      DesignerButton {
        label: designer.tr("Taller")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artResize(0, 2)
      }
      DesignerButton {
        label: designer.tr("Shorter")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artResize(0, -2)
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(8)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: designer.tr("%1 x %2 cells").arg(designer.artCols).arg(designer.artRows) + "   ·   " + designer.tr("Esc cancels, Enter keeps it")
        color: designer.muted
        font.family: designer.fontFamily
        font.pixelSize: Style.font.caption
      }

      DesignerButton {
        label: designer.tr("Cancel")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: { designer.artEditing = false; designer.artKey = ""; designer.focusCanvas() }
      }
      DesignerButton {
        label: designer.tr("Done")
        primary: true
        foreground: designer.foreground
        accent: designer.accent
        onClicked: designer.artApply()
      }
    }
  }
}
