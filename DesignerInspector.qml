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
  id: inspector
  anchors.top: designer.errorBanner.bottom
  anchors.topMargin: Style.space(8)
  anchors.bottom: designer.footer.top
  anchors.bottomMargin: Style.space(8)
  anchors.right: parent.right
  width: designer.inspectorW
  radius: 6
  color: designer.well
  border.width: 1
  border.color: designer.line
  clip: true

  Flickable {
    anchors.fill: parent
    anchors.margins: Style.space(10)
    contentWidth: width
    contentHeight: inspectorColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: inspectorColumn
      width: parent.width
      spacing: Style.space(10)

      DesignerField {

        language: designer.language
        width: parent.width
        label: designer.tr("DESIGN NAME")
        type: "text"
        value: designer.docName
        foreground: designer.foreground
        accent: designer.accent
        onEdited: function(next) {
          designer.pushUndo("name")
          designer.docName = String(next)
          designer.touch()
        }
        onEscaped: designer.focusCanvas()
      }

      // The base's own chrome (media strip, owner message) follows the
      // design: square for a sharp layout, a pill for a round one.
      DesignerField {
        language: designer.language
        width: parent.width
        label: designer.tr("CORNERS")
        type: "number"
        minimum: 0
        maximum: 24
        step: 1
        value: designer.docCorners
        foreground: designer.foreground
        accent: designer.accent
        onEdited: function(next) {
          designer.pushUndo("corners")
          designer.docCorners = D.clampCorners(next)
          designer.touch()
        }
        onEscaped: designer.focusCanvas()
      }

      Rectangle { width: parent.width; height: 1; color: designer.line }

      Text {
        width: parent.width
        text: designer.selection.length === 0 ? designer.tr("NOTHING SELECTED")
          : (designer.selection.length > 1 ? designer.tr("%1 PIECES SELECTED").arg(designer.selection.length)
             : (designer.primaryKind ? designer.tr(designer.primaryKind.name).toUpperCase() : ""))
        textFormat: Text.PlainText
        color: designer.selection.length === 0 ? designer.muted : designer.accent
        font.family: designer.fontFamily
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        font.weight: Font.DemiBold
      }

      Text {
        width: parent.width
        visible: designer.selection.length === 0
        text: designer.tr("Drag a piece onto the screen, or click one there to change it.")
        textFormat: Text.PlainText
        color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b, 0.35)
        font.family: designer.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
      }

      // ------------------------------------------------------- placement

      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: designer.primary !== null && !D.isFill(designer.primary)

        Text {
          text: designer.tr("STICKS TO")
          color: designer.muted
          font.family: designer.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
        }

        Row {
          spacing: Style.space(10)

          // A design has to survive a different screen, so a piece is not
          // parked at an absolute spot: it holds on to a corner, an edge or
          // the middle, and keeps its distance from that.
          Grid {
            columns: 3
            spacing: Style.space(3)
            Repeater {
              model: D.ANCHORS
              Rectangle {
                required property string modelData
                readonly property bool current: designer.primary && designer.primary.anchor === modelData
                width: Style.space(20)
                height: Style.space(20)
                radius: 3
                color: current ? designer.accent
                  : Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b,
                            anchorArea.containsMouse ? 0.18 : 0.08)
                border.width: 1
                border.color: current ? designer.accent : designer.line
                Rectangle {
                  anchors.centerIn: parent
                  width: Style.space(5)
                  height: width
                  radius: 1
                  color: parent.current ? Commons.Color.background : designer.muted
                }
                MouseArea {
                  id: anchorArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: designer.setAnchor(parent.modelData)
                }
              }
            }
          }

          Column {
            spacing: Style.space(4)
            width: inspectorColumn.width - Style.space(84)
            DesignerField {
              language: designer.language
              width: parent.width
              label: designer.tr("OFFSET X")
              type: "number"
              minimum: -10000
              maximum: 10000
              step: 1
              value: designer.primary ? designer.primary.dx : 0
              foreground: designer.foreground
              accent: designer.accent
              onEdited: function(next) { designer.setGeometry("dx", next) }
              onEscaped: designer.focusCanvas()
            }
            DesignerField {
              language: designer.language
              width: parent.width
              label: designer.tr("OFFSET Y")
              type: "number"
              minimum: -10000
              maximum: 10000
              step: 1
              value: designer.primary ? designer.primary.dy : 0
              foreground: designer.foreground
              accent: designer.accent
              onEdited: function(next) { designer.setGeometry("dy", next) }
              onEscaped: designer.focusCanvas()
            }
          }
        }

        Row {
          spacing: Style.space(8)
          visible: designer.primary !== null && D.isSized(designer.primary)
          DesignerField {
            language: designer.language
            width: (inspectorColumn.width - Style.space(8)) / 2
            label: designer.tr("WIDTH")
            type: "number"
            minimum: 0
            maximum: 10000
            step: 1
            value: designer.primary ? designer.primary.w : 0
            foreground: designer.foreground
            accent: designer.accent
            onEdited: function(next) { designer.setGeometry("w", next) }
            onEscaped: designer.focusCanvas()
          }
          DesignerField {
            language: designer.language
            width: (inspectorColumn.width - Style.space(8)) / 2
            label: designer.tr("HEIGHT")
            type: "number"
            minimum: 0
            maximum: 10000
            step: 1
            visible: designer.primary ? !D.isSquare(designer.primary) : false
            value: designer.primary ? designer.primary.h : 0
            foreground: designer.foreground
            accent: designer.accent
            onEdited: function(next) { designer.setGeometry("h", next) }
            onEscaped: designer.focusCanvas()
          }
        }

        Text {
          width: parent.width
          visible: designer.primary !== null && !D.isSized(designer.primary)
          text: designer.tr("Set a width to make it wrap; leave it at 0 and it hugs its text.")
          textFormat: Text.PlainText
          color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b, 0.35)
          font.family: designer.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.Wrap
        }

        DesignerField {

          language: designer.language
          width: parent.width
          visible: designer.primary !== null && !D.isSized(designer.primary)
          label: designer.tr("WIDTH (0 = FIT TEXT)")
          type: "number"
          minimum: 0
          maximum: 10000
          step: 10
          value: designer.primary ? designer.primary.w : 0
          foreground: designer.foreground
          accent: designer.accent
          onEdited: function(next) { designer.setGeometry("w", next) }
          onEscaped: designer.focusCanvas()
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: designer.line
        visible: designer.primary !== null
      }

      // ---------------------------------------------------------- fields

      Repeater {
        model: designer.primaryKind ? designer.primaryKind.fields : []

        DesignerField {

          language: designer.language
          required property var modelData
          width: inspectorColumn.width
          label: designer.tr(modelData.label).toUpperCase()
          type: modelData.type
          options: (modelData.options ? modelData.options : []).map(function(o) { return { id: o.id, name: designer.tr(o.name) } })
          minimum: modelData.min !== undefined ? modelData.min : 0
          maximum: modelData.max !== undefined ? modelData.max : 1
          step: modelData.step !== undefined ? modelData.step : 0.05
          value: {
            if (!designer.primary) return null
            var v = designer.primary.spec[modelData.key]
            return v === undefined ? null : v
          }
          foreground: designer.foreground
          accent: designer.accent
          onEdited: function(next) { designer.setProp(modelData.key, next) }
          onEscaped: designer.focusCanvas()
          onPickFileRequested: {
            designer.pendingFileKey = modelData.key
            designer.pickFileRequested()
          }
          onDrawArtRequested: designer.openArtEditor(modelData.key, designer.primary ? designer.primary.spec[modelData.key] : "")
        }
      }

      // --------------------------------------------------------- actions

      Rectangle {
        width: parent.width
        height: 1
        color: designer.line
        visible: designer.selection.length > 0
      }

      Flow {
        width: parent.width
        spacing: Style.space(5)
        visible: designer.selection.length > 0

        DesignerButton {
          label: designer.tr("Duplicate")
          foreground: designer.foreground
          accent: designer.accent
          onClicked: designer.duplicateSelected()
        }
        DesignerButton {
          label: designer.tr("Delete")
          foreground: designer.foreground
          accent: designer.accent
          onClicked: designer.removeSelected()
        }
        DesignerButton {
          label: designer.tr("Front")
          foreground: designer.foreground
          accent: designer.accent
          onClicked: designer.restack(2)
        }
        DesignerButton {
          label: designer.tr("Forward")
          foreground: designer.foreground
          accent: designer.accent
          onClicked: designer.restack(1)
        }
        DesignerButton {
          label: designer.tr("Back")
          foreground: designer.foreground
          accent: designer.accent
          onClicked: designer.restack(-1)
        }
        DesignerButton {
          label: designer.tr("Bottom")
          foreground: designer.foreground
          accent: designer.accent
          onClicked: designer.restack(-2)
        }
      }

      DesignerButton {
        width: parent.width
        visible: designer.selection.length > 0 && !designer.namingComponent
        label: designer.tr("Save as component")
        foreground: designer.foreground
        accent: designer.accent
        onClicked: {
          designer.namingComponent = true
          Qt.callLater(function() { componentName.forceFieldFocus() })
        }
      }

      Column {
        id: componentName
        width: parent.width
        spacing: Style.space(5)
        visible: designer.namingComponent

        function forceFieldFocus() { nameEntry.forceActiveFocus() }

        Text {
          text: designer.tr("NAME IT")
          color: designer.muted
          font.family: designer.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
        }

        Rectangle {
          width: parent.width
          height: Style.space(28)
          radius: 4
          color: Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b, 0.07)
          border.width: 1
          border.color: nameEntry.activeFocus ? designer.accent : designer.line
          TypedInput {
            id: nameEntry
            anchors.fill: parent
            anchors.leftMargin: Style.space(8)
            anchors.rightMargin: Style.space(8)
            verticalAlignment: TextInput.AlignVCenter
            color: designer.foreground
            selectionColor: designer.accent
            selectByMouse: true
            font.family: designer.fontFamily
            font.pixelSize: Style.font.bodySmall
            onAccepted: if (text.trim().length > 0) designer.saveSelectionAsComponent(text.trim())
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                designer.namingComponent = false
                designer.focusCanvas()
                event.accepted = true
              }
            }
          }
        }

        Row {
          spacing: Style.space(5)
          DesignerButton {
            label: designer.tr("Save")
            primary: true
            foreground: designer.foreground
            accent: designer.accent
            onClicked: if (nameEntry.text.trim().length > 0) designer.saveSelectionAsComponent(nameEntry.text.trim())
          }
          DesignerButton {
            label: designer.tr("Cancel")
            foreground: designer.foreground
            accent: designer.accent
            onClicked: { designer.namingComponent = false; designer.focusCanvas() }
          }
        }
      }

      // ---------------------------------------------------------- layers

      Rectangle { width: parent.width; height: 1; color: designer.line }

      Text {
        text: designer.tr("LAYERS  ·  TOP FIRST")
        color: designer.muted
        font.family: designer.fontFamily
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }

      Column {
        width: parent.width
        spacing: 1

        Repeater {
          // Top of the screen first, which is the end of the list.
          model: designer.nodes.slice().reverse()

          Rectangle {
            id: layerRow
            required property var modelData
            readonly property bool current: designer.selection.indexOf(modelData.nodeId) !== -1
            width: inspectorColumn.width
            height: Style.space(24)
            radius: 3
            color: current ? Qt.rgba(designer.accent.r, designer.accent.g, designer.accent.b, 0.25)
              : Qt.rgba(designer.foreground.r, designer.foreground.g, designer.foreground.b,
                        layerArea.containsMouse ? 0.1 : 0.0)

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              text: D.kind(layerRow.modelData.kind).glyph
              color: layerRow.current ? designer.accent : designer.muted
              font.family: designer.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(26)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              text: {
                var name = designer.tr(D.kindName(layerRow.modelData.kind))
                var body = String(layerRow.modelData.spec.text || "")
                return body.length > 0 ? name + " · " + body : name
              }
              textFormat: Text.PlainText
              color: layerRow.current ? designer.foreground : designer.muted
              font.family: designer.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }

            MouseArea {
              id: layerArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: function(mouse) {
                designer.nodePressed(layerRow.modelData.nodeId, (mouse.modifiers & Qt.ControlModifier) !== 0)
                if (!(mouse.modifiers & Qt.ControlModifier)) designer.select([layerRow.modelData.nodeId])
                designer.focusCanvas()
              }
            }
          }
        }
      }
    }
  }
}
