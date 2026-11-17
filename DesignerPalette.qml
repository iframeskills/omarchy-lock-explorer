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
  id: palette
  anchors.top: designer.errorBanner.bottom
  anchors.topMargin: Style.space(8)
  anchors.bottom: designer.footer.top
  anchors.bottomMargin: Style.space(8)
  anchors.left: parent.left
  width: designer.panelW
  radius: 6
  color: designer.well
  border.width: 1
  border.color: designer.line
  clip: true

  Flickable {
    anchors.fill: parent
    anchors.margins: Style.space(10)
    contentWidth: width
    contentHeight: paletteColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: paletteColumn
      width: parent.width
      spacing: Style.space(6)

      Text {
        text: designer.tr("YOUR COMPONENTS")
        color: designer.muted
        font.family: designer.fontFamily
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }

      Text {
        width: parent.width
        visible: designer.componentList.length === 0
        text: designer.tr("Select a piece (or several with Ctrl) and press “Save as component” to keep it here for every design.")
        textFormat: Text.PlainText
        color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b, 0.35)
        font.family: designer.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
      }

      Repeater {
        model: designer.componentList

        Rectangle {
          id: componentEntry
          required property var modelData
          width: paletteColumn.width
          height: Style.space(54)
          radius: 5
          color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b,
                         componentArea.containsMouse ? 0.14 : 0.06)
          border.width: 1
          border.color: designer.line
          Behavior on color { ColorAnimation { duration: 100 } }

          DesignerThumb {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(6)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(56)
            height: Style.space(40)
            lock: designer.stage
            comp: componentEntry.modelData.comp
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(68)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(22)
            anchors.verticalCenter: parent.verticalCenter
            text: componentEntry.modelData.comp ? componentEntry.modelData.comp.name : componentEntry.modelData.slug
            textFormat: Text.PlainText
            color: designer.foreground
            font.family: designer.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(7)
            anchors.top: parent.top
            anchors.topMargin: Style.space(5)
            visible: componentArea.containsMouse || removeArea.containsMouse
            text: "✕"
            color: removeArea.containsMouse ? Commons.Color.lock.textError : designer.muted
            font.family: designer.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea {
              id: removeArea
              anchors.fill: parent
              anchors.margins: -Style.space(5)
              hoverEnabled: true
              onClicked: designer.deleteComponent(componentEntry.modelData.slug)
            }
          }

          Item {
            id: componentGhost
            parent: designer.dragLayer
            visible: componentArea.dragging
            width: Style.space(120)
            height: Style.space(30)
            Drag.active: componentArea.dragging
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.keys: ["lock-designer-drop"]
            property string payloadKind: ""
            property var payloadComponent: componentEntry.modelData.comp

            Rectangle {
              anchors.fill: parent
              radius: 5
              color: Qt.rgba(designer.accent.r, designer.accent.g, designer.accent.b, 0.85)
              Text {
                anchors.centerIn: parent
                text: componentEntry.modelData.comp ? componentEntry.modelData.comp.name : ""
                textFormat: Text.PlainText
                color: Commons.Color.background
                font.family: designer.fontFamily
                font.pixelSize: Style.font.caption
                font.weight: Font.DemiBold
              }
            }
          }

          MouseArea {
            id: componentArea
            anchors.fill: parent
            anchors.rightMargin: Style.space(20)
            hoverEnabled: true
            // Same as the built-in pieces: the ghost is carried by hand.
            property bool dragging: false
            property real pressX: 0
            property real pressY: 0

            function carry(mouse) {
              var p = mapToItem(designer.dragLayer, mouse.x, mouse.y)
              componentGhost.x = p.x - componentGhost.width / 2
              componentGhost.y = p.y - componentGhost.height / 2
            }

            onPressed: function(mouse) {
              pressX = mouse.x
              pressY = mouse.y
              dragging = false
              carry(mouse)
            }
            onPositionChanged: function(mouse) {
              if (!pressed) return
              if (!dragging && Math.abs(mouse.x - pressX) < 6 && Math.abs(mouse.y - pressY) < 6) return
              dragging = true
              carry(mouse)
            }
            onReleased: {
              if (dragging) {
                componentGhost.Drag.drop()
                dragging = false
              } else {
                designer.addComponent(componentEntry.modelData.comp, designer.screenWidth / 2, designer.screenHeight / 2)
              }
            }
            onCanceled: dragging = false
          }
        }
      }

      Repeater {
        model: D.GROUPS

        Column {
          id: group
          required property string modelData
          // In the order of the names as they are shown.
          readonly property var entries: D.paletteFor(modelData).sort(function(a, b) {
            return designer.tr(a.kind.name).localeCompare(designer.tr(b.kind.name))
          })
          width: paletteColumn.width
          spacing: Style.space(4)
          topPadding: Style.space(6)

          Text {
            text: designer.tr(group.modelData).toUpperCase()
            color: designer.muted
            font.family: designer.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
          }

          Repeater {
            model: group.entries

            Rectangle {
              id: entry
              required property var modelData
              width: group.width
              height: Style.space(32)
              radius: 5
              color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b,
                             entryArea.containsMouse ? 0.14 : 0.06)
              border.width: 1
              border.color: designer.line
              Behavior on color { ColorAnimation { duration: 100 } }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(9)
                anchors.verticalCenter: parent.verticalCenter
                text: entry.modelData.kind.glyph
                color: designer.accent
                font.family: designer.fontFamily
                font.pixelSize: Style.font.title
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(32)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                text: designer.tr(entry.modelData.kind.name)
                textFormat: Text.PlainText
                color: designer.foreground
                font.family: designer.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }

              Item {
                id: entryGhost
                parent: designer.dragLayer
                visible: entryArea.dragging
                width: Style.space(120)
                height: Style.space(30)
                Drag.active: entryArea.dragging
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
                Drag.keys: ["lock-designer-drop"]
                property string payloadKind: entry.modelData.id
                property var payloadComponent: null

                Rectangle {
                  anchors.fill: parent
                  radius: 5
                  color: Qt.rgba(designer.accent.r, designer.accent.g, designer.accent.b, 0.85)
                  Text {
                    anchors.centerIn: parent
                    text: designer.tr(entry.modelData.kind.name)
                    textFormat: Text.PlainText
                    color: Commons.Color.background
                    font.family: designer.fontFamily
                    font.pixelSize: Style.font.caption
                    font.weight: Font.DemiBold
                  }
                }
              }

              MouseArea {
                id: entryArea
                anchors.fill: parent
                hoverEnabled: true
                // The ghost is carried by hand rather than with drag.target:
                // it lives in the drag layer, outside this Flickable, and
                // MouseArea's own dragging maps the delta between the two
                // coordinate systems wrongly — the ghost ends up hundreds of
                // pixels away and drops onto nothing.
                property bool dragging: false
                property real pressX: 0
                property real pressY: 0

                function carry(mouse) {
                  var p = mapToItem(designer.dragLayer, mouse.x, mouse.y)
                  entryGhost.x = p.x - entryGhost.width / 2
                  entryGhost.y = p.y - entryGhost.height / 2
                }

                onPressed: function(mouse) {
                  pressX = mouse.x
                  pressY = mouse.y
                  dragging = false
                  carry(mouse)
                }
                onPositionChanged: function(mouse) {
                  if (!pressed) return
                  if (!dragging && Math.abs(mouse.x - pressX) < 6 && Math.abs(mouse.y - pressY) < 6) return
                  dragging = true
                  carry(mouse)
                }
                onReleased: {
                  if (dragging) {
                    entryGhost.Drag.drop()
                    dragging = false
                  } else {
                    designer.addNode(entry.modelData.id, designer.screenWidth / 2, designer.screenHeight / 2)
                  }
                }
                onCanceled: dragging = false
                // What it is, said in the footer where there is room for it.
                onEntered: designer.hoverHint = entry.modelData.kind.hint
                onExited: if (designer.hoverHint === entry.modelData.kind.hint) designer.hoverHint = ""
              }
            }
          }
        }
      }
    }
  }
}
