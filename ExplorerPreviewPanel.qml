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
  id: previewPanel
  // The editor brings its own pair of previews; give it the width.
  visible: root.mainTab !== "editor"
  anchors.top: root.header.bottom
  anchors.bottom: root.footer.top
  anchors.right: parent.right
  anchors.rightMargin: root.card.contentRightInset + Style.space(8)
  anchors.topMargin: Style.space(6)
  anchors.bottomMargin: Style.space(10)
  width: root.rightPanelW - Style.space(8)
  spacing: Style.space(12)

  Row {
    width: parent.width
    Text {
      text: root.tr("LOCK SCREEN")
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 2
    }
    Item { width: parent.width - lockLbl.width - liveLbl.width; height: 1 }
    Text {
      id: lockLbl; visible: false; text: root.tr("LOCK SCREEN")
      font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.letterSpacing: 2
    }
    Text {
      id: liveLbl
      text: "● " + root.tr("Live")
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  // Live render of the selected design, scaled from full screen.
  Rectangle {
    width: parent.width
    height: Math.round(parent.width * 9 / 16)
    radius: root.cornerRadius
    color: Commons.Color.background
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
    clip: true

    Item {
      width: root.panel.width
      height: root.panel.height
      scale: (parent.width - 2) / root.panel.width
      transformOrigin: Item.TopLeft
      enabled: false   // never let the preview's input steal keyboard focus
      LockHost {
        anchors.fill: parent
        designId: root.selectedDesign ? root.selectedDesign.id : root.activeDesignId
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
        inputEnabled: false
        loadBackground: root.opened && !root.sideView
        passwordText: "omarchy"
        videoPath: root.service ? root.service.videoPath : ""
        videoPlaying: root.opened && !root.sideView
      }
    }
  }

  Rectangle {
    width: parent.width
    height: Style.space(30)
    radius: root.cornerRadius
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, fullBtnArea.containsMouse ? 0.12 : 0.05)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
    Text {
      anchors.centerIn: parent
      text: root.tr("Preview full screen") + " · Space"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    MouseArea {
      id: fullBtnArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.fullPreview = true
    }
  }

  Item { width: 1; height: Style.space(4) }

  Row {
    width: parent.width
    Text {
      text: root.tr("BOOT SCREEN")
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 2
    }
  }

  Row {
    width: parent.width
    spacing: Style.space(12)

    Rectangle {
      width: Style.space(150)
      height: Math.round(Style.space(150) * 9 / 16)
      radius: root.cornerRadius
      color: Commons.Color.background
      border.width: 1
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
      clip: true
      Image {
        id: appliedBootThumb
        anchors.fill: parent; anchors.margins: 1
        // Every apply writes its own preview image, so this always shows
        // exactly what is on the boot image — snapshots included, which
        // the per-card cache never carries.
        source: root.bootApplied.length > 0
          ? "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/lock-explorer-boot-preview.png?v="
            + (root.service ? root.service.bootAppliedVersion : 0)
          : root.bootCardPreview("stock")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
      }
      Text {
        anchors.centerIn: parent
        visible: root.bootApplied.length === 0 && appliedBootThumb.status !== Image.Ready
        text: root.tr("stock")
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Column {
      width: parent.width - Style.space(162)
      spacing: Style.space(3)
      Text {
        width: parent.width
        elide: Text.ElideRight
        text: root.bootNowName
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.bootApplying ? root.tr("Rebuilding…") : (root.bootAppliedTheme.length > 0 ? root.tr("Baked from %1").arg(root.bootAppliedTheme) : root.tr("The disk passphrase screen"))
        textFormat: Text.PlainText
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.tr("Boot screen settings") + " ›"
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        MouseArea { anchors.fill: parent; anchors.margins: -Style.space(4); onClicked: root.mainTab = "boot" }
      }
    }
  }
}
