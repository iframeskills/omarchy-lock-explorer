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
  required property var root
  function nextTourStep() {
    if (root.tourStep >= root.tourSteps - 1) root.endTour()
    else root.tourStep += 1
  }
  function endTour() {
    root.tourStep = -1
    root.tourDone = true
    if (root.service && typeof root.service.setTourSeen === "function") root.service.setTourSeen(true)
    root.refocus()
  }
  function replayTour() {
    root.tourDone = false
    root.showPanel()
    root.tourStep = 0
  }
  function setBarIcon(on) {
    if (!root.service || typeof root.service.setBarIcon !== "function") return
    root.service.setBarIcon(on)
  }
  function setOpenAs(id) {
    if (!root.service || typeof root.service.setOpenAs !== "function") return
    root.service.setOpenAs(id)
  }

  // From the side panel into the full explorer, on the design that was
  // selected there, and back.
  function openFull(tab) {
    if (root.tourStep >= 0) root.endTour()
    root.view = "full"
    if (tab && tab.length > 0) root.mainTab = tab
    root.thumbSlots = 0
    root.refocus()
    root.revealTimer.restart()
  }
  function showPanel() {
    if (!root.gridTab) root.mainTab = "styling"
    root.fullPreview = false
    root.view = "panel"
    root.refocus()
    Qt.callLater(function() { root.reveal(GridView.Contain) })
  }

  function lockNow() {
    root.dismiss()
    Quickshell.execDetached(["omarchy-shell", "lock", "lock"])
  }

  // Enter in the side panel: the design becomes the lock screen and the panel
  // stays, since trying the next one is the likely next move.
  // `everywhere`: Shift+Enter, a pick for every theme while the design follows the theme.
  function useSelected(everywhere) {
    if (root.selectedDesign) root.useDesign(root.selectedDesign.id, false, everywhere)
  }

  // The side panel's keys. It has no pages of its own, so the ones that are
  // pages in the full explorer open it there.
  function sideKey(event) {
    if (root.tourStep >= 0) {
      // The tour takes the keys until it is done; Esc is handled before this.
      if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backspace)
        root.tourStep = Math.max(0, root.tourStep - 1)
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space
               || event.key === Qt.Key_Right || event.key === Qt.Key_Down)
        root.nextTourStep()
      event.accepted = true
      return
    }
    var tabs = ["favorites", "styling", "animation"]
    function stepTab(step) {
      root.searchText = ""
      root.mainTab = tabs[(Math.max(0, tabs.indexOf(root.mainTab)) + step + tabs.length) % tabs.length]
    }
    event.accepted = true
    if (event.text === "/" || (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier))) {
      root.fullPreview = false
      root.focusSearch()
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.useSelected(root.followTheme && (event.modifiers & Qt.ShiftModifier) !== 0)
      root.fullPreview = false
    } else if (event.key === Qt.Key_Space || event.key === Qt.Key_P) {
      root.fullPreview = !root.fullPreview
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
      root.move(-1)
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
      root.move(1)
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
      if (root.fullPreview) root.move(-1); else stepTab(-1)
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
      if (root.fullPreview) root.move(1); else stepTab(1)
    } else if (event.key === Qt.Key_Tab) {
      stepTab(1)
    } else if (event.key === Qt.Key_Backtab) {
      stepTab(-1)
    } else if (event.key === Qt.Key_Home) {
      root.selectedIndex = 0; root.reveal(GridView.Beginning)
    } else if (event.key === Qt.Key_End) {
      root.selectedIndex = Math.max(0, root.designs.length - 1); root.reveal(GridView.End)
    } else if (event.key === Qt.Key_PageDown) {
      root.sidePanel.page(1)
    } else if (event.key === Qt.Key_PageUp) {
      root.sidePanel.page(-1)
    } else if (event.key === Qt.Key_F) {
      if (root.selectedDesign && root.service && typeof root.service.toggleFavorite === "function")
        root.service.toggleFavorite(root.selectedDesign.id)
    } else if (event.key === Qt.Key_O) {
      root.openFull("")
    } else if (event.key === Qt.Key_U) {
      root.openFull("settings")
    } else if (event.key === Qt.Key_B) {
      root.openFull("boot")
    } else {
      event.accepted = false
    }
  }
  // The ? sheet: every key the explorer takes, over whatever page is open.
  property bool showingKeys: false
  // Widest row of key caps, so every description starts on one line.
  property real keyCapsWidth: 0
  readonly property var keySections: [
    { title: "Browse", rows: [
      { keys: ["←", "→", "↑", "↓"], text: "Move between designs" },
      { keys: ["H", "J", "K", "L"], text: "The same, Vim style" },
      { keys: ["Home", "End"], text: "First and last design" },
      { keys: ["PgUp", "PgDn"], text: "Scroll a page" },
      { keys: ["Space", "P"], text: "Full-size preview" },
      { keys: ["Enter"], text: "Use the selected design" },
      { keys: ["/", "Ctrl+F"], text: "Search every design" },
      { keys: ["F"], text: "Star it, or unstar it, for Favorites" }
    ] },
    { title: "Your designs", rows: [
      { keys: ["D"], text: "Designer: new, or this one if made there" },
      { keys: ["C"], text: "Copy to Custom and edit the code" },
      { keys: ["E"], text: "Edit a design of your own" },
      { keys: ["N"], text: "New design from the template" },
      { keys: ["X", "Del"], text: "Delete your own design (press twice)" }
    ] },
    { title: "Pictures and video", rows: [
      { keys: ["A", "Shift+A"], text: "Pick or clear the profile picture" },
      { keys: ["V", "Shift+V"], text: "Pick or clear the Motion video" },
      { keys: ["S", "Shift+S"], text: "Pick or clear the unlock clip" }
    ] },
    { title: "Pages", rows: [
      { keys: ["Tab", "Shift+Tab"], text: "Styling, Animation, Favorites" },
      { keys: ["U"], text: "Settings" },
      { keys: ["B"], text: "Boot screen" },
      { keys: ["O"], text: "Side panel" },
      { keys: ["?"], text: "This list" },
      { keys: ["Esc"], text: "Back, or close the explorer" }
    ] }
  ]

  function refocus() { Qt.callLater(function() { root.keyCatcher.forceActiveFocus() }) }

  function focusSearch() {
    root.searching = true
    if (root.sideView) { root.sidePanel.focusSearch(); return }
    Qt.callLater(function() { root.searchInput.forceActiveFocus(); root.searchInput.selectAll() })
  }

  function leaveSearch() {
    root.searching = false
    root.refocus()
  }

  function positionAtSelected(mode) {
    if (root.sideView) { root.sidePanel.reveal(); return }
    root.grid.positionViewAtIndex(root.selectedIndex, mode)
    var minY = root.grid.originY - root.grid.topMargin
    var maxY = Math.max(minY, root.grid.originY + root.grid.contentHeight - root.grid.height + root.grid.bottomMargin)
    if (root.grid.contentY < minY) root.grid.contentY = minY
    else if (root.grid.contentY > maxY) root.grid.contentY = maxY
  }

  function reveal(mode) {
    root.positionAtSelected(mode)
    Qt.callLater(function() { root.positionAtSelected(mode) })
  }

  function setCategory(id) {
    if (id === root.category) return
    var current = root.selectedDesign ? root.selectedDesign.id : ""
    root.category = id
    var list = Designs.inCategory(id, root.userDesigns)
    var keep = -1
    for (var i = 0; i < list.length; i++) if (list[i].id === current) keep = i
    root.selectedIndex = keep >= 0 ? keep : 0
    root.reveal(GridView.Contain)
  }

  function move(delta) {
    var n = root.designs.length
    if (n === 0) return
    root.selectedIndex = (root.selectedIndex + delta + n) % n
    root.reveal(GridView.Contain)
  }

  function moveRow(delta) {
    var next = root.selectedIndex + delta * root.columns
    if (next < 0 || next >= root.designs.length) return
    root.selectedIndex = next
    root.reveal(GridView.Contain)
  }

  function selectById(id) {
    var list = root.designs
    for (var i = 0; i < list.length; i++) if (list[i].id === id) { root.selectedIndex = i; root.reveal(GridView.Contain); return true }
    return false
  }
}
