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

PanelWindow {
  readonly property alias sidePanel: sidePanel
  readonly property alias designerView: designerView
  readonly property alias editorView: editorView
  readonly property alias footer: card.footer
  readonly property alias grid: card.grid
  readonly property alias customDelayInput: card.customDelayInput
  readonly property alias settingsColumn: card.settingsColumn
  readonly property alias settingsFlick: card.settingsFlick
  readonly property alias settingsPane: card.settingsPane
  readonly property alias searchInput: card.searchInput
  readonly property alias header: card.header
  readonly property alias card: card
  readonly property alias keyCatcher: keyCatcher
  required property var root
  id: panel
  visible: root.opened
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  WlrLayershell.namespace: "omarchy-lock-explorer"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore

  // The side panel leaves the desktop as it is; the full explorer dims it.
  Rectangle { anchors.fill: parent; color: root.scrim; visible: !root.sideView || root.fullPreview }
  MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

  Item {
    id: keyCatcher
    anchors.fill: parent
    focus: true
    Keys.priority: Keys.BeforeItem
    // Embedded lock previews can pull keyboard focus; reclaim it whenever
    // it drifts, except while a real editor field wants it.
    onActiveFocusChanged: {
      if (!activeFocus && root.opened && root.bootEditing.length === 0 && !root.editing
          && !root.designing && !root.customDelayEditing && !root.ownerEditing && !root.searching)
        Qt.callLater(function() {
          // Asked again: a click into the search field moves focus there
          // before the field has said it is searching.
          if (!root.searching && !keyCatcher.activeFocus) keyCatcher.forceActiveFocus()
        })
    }
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) { root.handleEscape(); event.accepted = true; return }
      if (root.designing) return
      if (root.editing) return
      if (root.bootEditing.length > 0) return
      if (root.customDelayEditing) return
      if (root.sideView) { root.sideKey(event); return }
      // event.text as well, since ? sits on a different key per layout.
      var question = event.key === Qt.Key_Question || event.text === "?"
      if (root.showingKeys) {
        if (question) root.showingKeys = false
        event.accepted = true
        return
      }
      if (question) { root.showingKeys = true; event.accepted = true; return }
      if (root.gridTab && (event.text === "/" || (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)))) {
        root.fullPreview = false
        root.focusSearch()
        event.accepted = true
        return
      }
      // The settings pages scroll from the keyboard as well as the wheel.
      if (!root.gridTab && root.mainTab === "settings") {
        var page = root.settingsFlick.height * 0.85
        var bottom = Math.max(0, root.settingsFlick.contentHeight - root.settingsFlick.height)
        var y = root.settingsFlick.contentY
        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) y += Style.space(60)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) y -= Style.space(60)
        else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Space) y += page
        else if (event.key === Qt.Key_PageUp) y -= page
        else if (event.key === Qt.Key_Home) y = 0
        else if (event.key === Qt.Key_End) y = bottom
        else y = -1
        if (y !== -1) {
          root.settingsFlick.contentY = Math.max(0, Math.min(bottom, y))
          event.accepted = true
          return
        }
      }
      if (!root.gridTab) {
        if (event.key === Qt.Key_U) { root.toggleSettings("settings"); event.accepted = true }
        else if (event.key === Qt.Key_B) { root.toggleSettings("boot"); event.accepted = true }
        return
      }
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.apply(root.followTheme && (event.modifiers & Qt.ShiftModifier) !== 0); event.accepted = true
      } else if (event.key === Qt.Key_Space || event.key === Qt.Key_P) {
        root.fullPreview = !root.fullPreview; event.accepted = true
      } else if (event.key === Qt.Key_C) {
        root.customizeSelected(); event.accepted = true
      } else if (event.key === Qt.Key_E) {
        if (root.selectedDesign && root.selectedDesign.path) root.editSelected()
        else root.customizeSelected()
        event.accepted = true
      } else if (event.key === Qt.Key_D) {
        if (root.selectedDesign && root.selectedDesign.designer) root.openDesigner(root.selectedDesign)
        else root.newDesignerDesign()
        event.accepted = true
      } else if (event.key === Qt.Key_N) {
        root.newDesign(); event.accepted = true
      } else if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) {
        root.deleteSelected(); event.accepted = true
      } else if (event.key === Qt.Key_A) {
        if (event.modifiers & Qt.ShiftModifier) root.clearAvatar()
        else root.pickAvatar()
        event.accepted = true
      } else if (event.key === Qt.Key_V) {
        if (event.modifiers & Qt.ShiftModifier) root.clearVideo()
        else root.pickVideo("video")
        event.accepted = true
      } else if (event.key === Qt.Key_S) {
        if (event.modifiers & Qt.ShiftModifier) root.clearSting()
        else root.pickVideo("sting")
        event.accepted = true
      } else if (event.key === Qt.Key_U) {
        root.toggleSettings("settings")
        event.accepted = true
      } else if (event.key === Qt.Key_B) {
        root.toggleSettings("boot")
        event.accepted = true
      } else if (event.key === Qt.Key_O) {
        root.showPanel()
        event.accepted = true
      } else if (event.key === Qt.Key_F) {
        if (root.selectedDesign && root.service && typeof root.service.toggleFavorite === "function")
          root.service.toggleFavorite(root.selectedDesign.id)
        event.accepted = true
      } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
        // Through the grid entries in the sidebar, as if clicking the next.
        var tabs = ["styling", "animation", "favorites"]
        var step = event.key === Qt.Key_Backtab ? tabs.length - 1 : 1
        root.mainTab = tabs[(Math.max(0, tabs.indexOf(root.mainTab)) + step) % tabs.length]
        event.accepted = true
      } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
        root.move(-1); event.accepted = true
      } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
        root.move(1); event.accepted = true
      } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
        if (root.fullPreview) root.move(-1); else root.moveRow(-1)
        event.accepted = true
      } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
        if (root.fullPreview) root.move(1); else root.moveRow(1)
        event.accepted = true
      } else if (event.key === Qt.Key_Home) {
        root.selectedIndex = 0; root.reveal(GridView.Beginning); event.accepted = true
      } else if (event.key === Qt.Key_End) {
        root.selectedIndex = Math.max(0, root.designs.length - 1); root.reveal(GridView.End); event.accepted = true
      } else if (event.key === Qt.Key_PageDown) {
        root.grid.contentY = Math.min(root.grid.contentHeight - root.grid.height, root.grid.contentY + root.grid.height); event.accepted = true
      } else if (event.key === Qt.Key_PageUp) {
        root.grid.contentY = Math.max(0, root.grid.contentY - root.grid.height); event.accepted = true
      }
    }
  }

  ExplorerCard { id: card; root: root }

  BorderSurface {
    id: editorSurface
    visible: root.editing
    width: root.cardWidth
    height: root.cardHeight
    radius: root.cornerRadius
    anchors.centerIn: parent
    color: root.background
    borderSpec: root.borderSpec

    MouseArea { anchors.fill: parent; onClicked: {} }

    Item {
      anchors.fill: parent
      anchors.topMargin: editorSurface.contentTopInset + root.contentMargin
      anchors.bottomMargin: editorSurface.contentBottomInset + root.contentMargin
      anchors.leftMargin: editorSurface.contentLeftInset + root.contentMargin
      anchors.rightMargin: editorSurface.contentRightInset + root.contentMargin

      Item {
        id: editorHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(48)
        Column {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2
          Text {
            text: root.editingDesign ? root.editingDesign.name : ""
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            font.weight: Font.DemiBold
          }
          Text {
            text: root.tr("Custom design")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)
          Rectangle {
            width: saveLabel.implicitWidth + Style.space(20); height: Style.space(30); radius: 6
            color: editorView.dirty ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text {
              id: saveLabel
              anchors.centerIn: parent
              text: root.tr("Save  Ctrl+S")
              color: editorView.dirty ? Commons.Color.background : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: editorView.dirty
            }
            MouseArea { anchors.fill: parent; onClicked: editorView.save() }
          }
          Rectangle {
            width: useLabel2.implicitWidth + Style.space(20); height: Style.space(30); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text {
              id: useLabel2
              anchors.centerIn: parent
              text: root.tr("Use this design")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (root.editingDesign) root.useDesign(root.editingDesign.id, false)
              }
            }
          }
          Rectangle {
            width: backLabel.implicitWidth + Style.space(20); height: Style.space(30); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text {
              id: backLabel
              anchors.centerIn: parent
              text: root.tr("Back  Esc")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            MouseArea { anchors.fill: parent; onClicked: editorView.requestClose() }
          }
        }
      }

      Editor {
        id: editorView
        anchors.top: editorHeader.bottom
        anchors.topMargin: Style.space(12)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        service: root.service
        design: root.editing ? root.editingDesign : null
        background: root.background
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        screenWidth: root.panel.width
        screenHeight: root.panel.height
        onCloseRequested: root.closeEditor()
        onOpenExternalRequested: function(path) { root.openExternal(path) }
      }
    }
  }

  BorderSurface {
    id: designerCard
    visible: root.designing
    width: root.cardWidth
    height: root.cardHeight
    radius: root.cornerRadius
    anchors.centerIn: parent
    color: root.background
    borderSpec: root.borderSpec

    MouseArea { anchors.fill: parent; onClicked: {} }

    Designer {
      id: designerView
      anchors.fill: parent
      anchors.topMargin: designerCard.contentTopInset + root.contentMargin
      anchors.bottomMargin: designerCard.contentBottomInset + root.contentMargin
      anchors.leftMargin: designerCard.contentLeftInset + root.contentMargin
      anchors.rightMargin: designerCard.contentRightInset + root.contentMargin
      service: root.service
      design: root.designing ? root.designingDesign : null
      pluginId: root.pluginId
      background: root.background
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      screenWidth: root.panel.width
      screenHeight: root.panel.height
      onCloseRequested: root.closeDesigner()
      onUseRequested: if (root.designingDesign) root.useDesign(root.designingDesign.id, false)
      onPickFileRequested: root.pickDesignerImage()
      onOpenCodeRequested: function(path) {
        // Straight from the canvas into the code, on the same file.
        root.designing = false
        root.openEditor(root.designingDesign)
      }
    }
  }

  SidePanel {
    id: sidePanel
    explorer: root
    screenWidth: root.panel.width
    screenHeight: root.panel.height
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: Style.gapsOut
  }

  Item {
    anchors.fill: parent
    visible: root.fullPreview

    LockHost {
      anchors.fill: parent
      designId: root.selectedDesign ? root.selectedDesign.id : Designs.DEFAULT_ID
      revision: root.service ? root.service.designsRevision : 0
      userDesigns: root.userDesigns
      twelveHour: root.twelveHour
      wallpaperBlur: root.wallpaperBlurValue
      wallpaperDim: root.wallpaperDimShift
      uiScale: root.uiScale
      holdStill: root.motionReduced
      language: root.lockLanguage
      fullName: root.accountName
      showLayoutBadge: root.showLayoutBadge
      showCapsBadge: root.showCapsBadge
      allowPasswordToggle: root.allowPasswordToggle
      showAuthIcons: root.showAuthIcons
      backgroundPath: root.service ? root.service.backgroundPath : ""
      backgroundVersion: root.service ? root.service.backgroundVersion : 0
      fingerprintConfigured: root.service ? root.service.fingerprintConfigured : false
      inputEnabled: false
      loadBackground: root.opened && root.fullPreview
      passwordText: ""
      videoPath: root.service ? root.service.videoPath : ""
      videoPlaying: root.fullPreview
    }

    MouseArea { anchors.fill: parent; onClicked: root.fullPreview = false }

    Rectangle {
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.topMargin: Style.space(20)
      width: hud.implicitWidth + Style.space(32)
      height: hud.implicitHeight + Style.space(20)
      radius: root.cornerRadius
      color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.85)
      border.width: 1
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
      Row {
        id: hud
        anchors.centerIn: parent
        spacing: Style.space(18)
        Text {
          text: (root.selectedIndex + 1) + "/" + root.designs.length + "   " + (root.selectedDesign ? root.selectedDesign.name : "")
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.weight: Font.DemiBold
        }
        Text {
          text: root.tr("Arrows: next   Enter: select   Esc: back")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  Item {
    anchors.fill: parent
    visible: root.showingKeys
    z: 100

    Rectangle { anchors.fill: parent; color: root.scrim }
    MouseArea { anchors.fill: parent; onClicked: root.showingKeys = false }

    BorderSurface {
      id: keysSheet
      anchors.centerIn: parent
      width: keysBody.implicitWidth + contentLeftInset + contentRightInset
      height: keysBody.implicitHeight + contentTopInset + contentBottomInset
      radius: root.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        id: keysBody
        x: keysSheet.contentLeftInset
        y: keysSheet.contentTopInset
        spacing: Style.space(24)

        Column {
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
              text: root.tr("KEYBOARD SHORTCUTS")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              font.weight: Font.Bold
              font.letterSpacing: 2
            }
          }
          Text {
            text: root.tr("On the design grid") + " · " + root.tr("Esc or ? closes this")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        Grid {
          columns: 2
          columnSpacing: Style.space(48)
          rowSpacing: Style.space(24)

          Repeater {
            model: root.keySections
            Column {
              id: keySection
              required property var modelData
              spacing: Style.space(8)

              Text {
                text: root.tr(keySection.modelData.title).toUpperCase()
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
              }

              Repeater {
                model: keySection.modelData.rows
                Row {
                  id: keyRow
                  required property var modelData
                  spacing: Style.space(12)

                  Item {
                    width: root.keyCapsWidth
                    height: Style.space(22)
                    Row {
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(4)
                      onImplicitWidthChanged: root.keyCapsWidth = Math.max(root.keyCapsWidth, implicitWidth)
                      Repeater {
                        model: keyRow.modelData.keys
                        Rectangle {
                          id: keyCap
                          required property var modelData
                          width: Math.max(Style.space(22), capLabel.implicitWidth + Style.space(12))
                          height: Style.space(22)
                          radius: root.cornerRadius
                          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                          border.width: 1
                          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
                          Text {
                            id: capLabel
                            anchors.centerIn: parent
                            text: keyCap.modelData
                            textFormat: Text.PlainText
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                          }
                        }
                      }
                    }
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tr(keyRow.modelData.text)
                    textFormat: Text.PlainText
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
