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

GridView {
  required property var root
  id: grid
  visible: root.gridTab
  anchors.top: root.header.bottom
  anchors.bottom: root.footer.top
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.leftMargin: root.card.contentLeftInset + root.sidebarW + Style.space(20)
  anchors.rightMargin: root.card.contentRightInset + root.rightPanelW + Style.space(20)
  anchors.bottomMargin: Style.space(8)
  clip: true
  model: root.designs
  cellWidth: root.cellWidth
  cellHeight: root.thumbHeight + root.captionHeight + root.gap
  topMargin: Style.space(4)
  cacheBuffer: cellHeight * 2
  boundsBehavior: Flickable.StopAtBounds
  flickDeceleration: 4000
  maximumFlickVelocity: 3000

  delegate: Item {
    id: cell
    required property var modelData
    required property int index
    readonly property bool selected: index === root.selectedIndex
    readonly property bool active: modelData.id === root.activeDesignId
    // A preview is a whole lock screen, so only the ones on screen are
    // worth drawing. The rest stay built but out of the scene graph.
    readonly property bool inView: (y + height > root.grid.contentY - root.grid.cellHeight / 2)
      && (y < root.grid.contentY + root.grid.height + root.grid.cellHeight / 2)
    width: root.grid.cellWidth
    height: root.grid.cellHeight

    // Its turn to build: see thumbSlots. Once started it stays built.
    readonly property int rank: index - root.gridTopRow * root.columns
    readonly property bool mayLoad: inView && rank < root.thumbSlots
    property bool wanted: false
    onMayLoadChanged: if (mayLoad) wanted = true
    Component.onCompleted: if (mayLoad) wanted = true

    readonly property string cachedThumb: root.thumbFor(modelData.id)
    readonly property bool designUp: thumbLoader.status === Loader.Ready && !!thumbLoader.item && !!thumbLoader.item.item
    // Over a picture the live design fades in once it has had a moment
    // to draw; with no picture it shows as soon as it is there.
    property bool liveShown: false
    onDesignUpChanged: {
      if (!designUp) return
      if (cachedThumb.length === 0) liveShown = true
      else thumbnailRevealTimer.restart()
      if (cachedThumb.length === 0) grabTimer.restart()
    }
    onCachedThumbChanged: if (cachedThumb.length === 0 && designUp) grabTimer.restart()
    Timer { id: thumbnailRevealTimer; interval: 700; onTriggered: cell.liveShown = true }
    // A first picture soon, so a quick change of tab already has one,
    // and a second once slow wallpapers and intros have finished.
    Timer { id: grabTimer; interval: 1200; onTriggered: { cell.grabThumb(false); regrabTimer.restart() } }
    Timer { id: regrabTimer; interval: 3500; onTriggered: cell.grabThumb(true) }
    function grabThumb(again) {
      if (!root.opened || !cell.inView || !thumbLoader.item || (!again && cell.cachedThumb.length > 0)) return
      var id = cell.modelData.id
      var key = root.thumbStateKey
      var dpr = Screen.devicePixelRatio || 1
      thumbLoader.item.grabToImage(function(result) { root.keepThumb(id, key, result) },
        Qt.size(Math.round(root.thumbWidth * dpr), Math.round(root.thumbHeight * dpr)))
    }

    Rectangle {
      id: frame
      width: root.thumbWidth
      height: root.thumbHeight
      radius: root.cornerRadius
      color: Commons.Color.background
      border.width: cell.selected ? 3 : 1
      border.color: cell.selected ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
      clip: true
      Behavior on border.color { ColorAnimation { duration: 120 } }

      Item {
        anchors.fill: parent
        anchors.margins: frame.border.width
        clip: true
        Image {
          anchors.fill: parent
          visible: cell.inView && source != "" && !(cell.liveShown && cell.designUp)
          source: cell.cachedThumb
          cache: false
          smooth: true
        }
        Item {
          width: root.panel.width
          height: root.panel.height
          scale: (frame.width - frame.border.width * 2) / root.panel.width
          transformOrigin: Item.TopLeft
          visible: cell.inView
          opacity: cell.liveShown ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180 } }
          Loader {
            id: thumbLoader
            anchors.fill: parent
            asynchronous: true
            active: cell.wanted
            sourceComponent: LockHost {
              stillTextureSize: Qt.size(root.thumbWidth, root.thumbHeight)
              designId: cell.modelData.id
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
              avatarPath: root.service ? root.service.avatarPath : ""
              avatarVersion: root.service ? root.service.avatarVersion : 0
              fingerprintConfigured: root.service ? root.service.fingerprintConfigured : false
              inputEnabled: false
              loadBackground: root.opened
              passwordText: "omarchy"
              videoPath: root.service ? root.service.videoPath : ""
              // Only the cell on screen decodes, the rest hold still.
              videoPlaying: cell.inView
            }
          }
        }
      }

      Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: Style.space(10)
        width: Style.space(24); height: Style.space(24); radius: 5
        color: root.shade(0.55)
        Text {
          anchors.centerIn: parent
          text: (cell.index + 1)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      // Favorite: shown when starred, and on the selected card as the
      // way to star it with the mouse. Above the card's own click area,
      // which is declared after it.
      Rectangle {
        z: 2
        readonly property bool starred: root.isFavorite(cell.modelData.id)
        visible: starred || cell.selected
        anchors.left: parent.left; anchors.top: parent.top
        anchors.leftMargin: Style.space(40); anchors.topMargin: Style.space(10)
        width: Style.space(24); height: Style.space(24); radius: 5
        color: root.shade(0.55)
        Text {
          anchors.centerIn: parent
          text: parent.starred ? "★" : "☆"
          color: parent.starred ? root.accent : root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        MouseArea {
          anchors.fill: parent
          z: 1
          onClicked: {
            root.selectedIndex = cell.index
            if (root.service && typeof root.service.toggleFavorite === "function") root.service.toggleFavorite(cell.modelData.id)
          }
        }
      }

      Rectangle {
        visible: cell.active
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Style.space(10)
        width: activeText.implicitWidth + Style.space(14); height: Style.space(24); radius: root.cornerRadius
        color: root.accent
        Text {
          id: activeText
          anchors.centerIn: parent
          text: "󰄬 " + root.tr("Active")
          color: Commons.Color.background
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.selectedIndex = cell.index
        onDoubleClicked: { root.selectedIndex = cell.index; root.apply() }
      }

      Row {
        visible: cell.selected
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.space(10)
        spacing: Style.space(6)
        Rectangle {
          width: useLabel.implicitWidth + Style.space(16); height: Style.space(26); radius: 6
          color: root.accent
          Text {
            id: useLabel
            anchors.centerIn: parent
            text: root.tr("Use") + "  ⏎"
            color: Commons.Color.background
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          MouseArea { anchors.fill: parent; onClicked: { root.selectedIndex = cell.index; root.apply() } }
        }
        // While the design follows the theme, Use picks for the theme that
        // is on; this picks for all of them and forgets the per-theme picks.
        Rectangle {
          visible: root.followTheme
          width: allLabel.implicitWidth + Style.space(16); height: Style.space(26); radius: 6
          color: root.shade(0.6)
          border.width: 1
          border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
          Text {
            id: allLabel
            anchors.centerIn: parent
            text: root.tr("All themes") + "  ⇧⏎"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          MouseArea { anchors.fill: parent; onClicked: { root.selectedIndex = cell.index; root.apply(true) } }
        }
        Rectangle {
          width: custLabel.implicitWidth + Style.space(16); height: Style.space(26); radius: 6
          color: root.shade(0.6)
          border.width: 1
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
          Text {
            id: custLabel
            anchors.centerIn: parent
            text: cell.modelData.designer ? root.tr("Design") + "  E"
              : (cell.modelData.path ? root.tr("Edit") + "  E" : root.tr("Customize") + "  C")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          MouseArea { anchors.fill: parent; onClicked: { root.selectedIndex = cell.index; root.customizeSelected() } }
        }
        // Only your own designs can be deleted; two clicks to confirm.
        Rectangle {
          visible: cell.modelData.path ? true : false
          width: delLabel.implicitWidth + Style.space(16); height: Style.space(26); radius: 6
          color: root.confirmingDelete === cell.modelData.id ? root.danger : root.shade(0.6)
          border.width: 1
          border.color: root.confirmingDelete === cell.modelData.id ? Qt.lighter(root.danger, 1.3) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
          Text {
            id: delLabel
            anchors.centerIn: parent
            text: root.tr(root.confirmingDelete === cell.modelData.id ? "Sure?" : "Delete") + "  X"
            color: root.confirmingDelete === cell.modelData.id ? Commons.Color.background : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          MouseArea { anchors.fill: parent; onClicked: { root.selectedIndex = cell.index; root.deleteSelected() } }
        }
      }
    }

    Column {
      anchors.top: frame.bottom
      anchors.topMargin: Style.space(8)
      width: root.thumbWidth
      spacing: 2
      Row {
        spacing: Style.space(8)
        Text {
          text: cell.modelData.name
          textFormat: Text.PlainText
          color: cell.selected ? root.foreground : root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.weight: cell.selected ? Font.DemiBold : Font.Normal
        }
        Row {
          spacing: Style.space(4)
          anchors.verticalCenter: parent.verticalCenter
          Repeater {
            model: cell.modelData.tags || []
            Rectangle {
              required property string modelData
              width: tagLabel.implicitWidth + Style.space(10)
              height: Style.space(18)
              radius: 4
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
              Text {
                id: tagLabel
                anchors.centerIn: parent
                text: {
                  var cats = Designs.categories()
                  for (var i = 0; i < cats.length; i++) if (cats[i].id === parent.modelData) return root.tr(cats[i].name)
                  return parent.modelData
                }
                textFormat: Text.PlainText
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }
      }
      Text {
        width: parent.width
        text: cell.modelData.description + (cell.modelData.credit ? "  ·  " + root.tr("Clip by %1").arg(cell.modelData.credit) : "")
        textFormat: Text.PlainText
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }
  }
}
