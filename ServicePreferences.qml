import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import "Designs.js" as Designs
import "DisplayPower.js" as DisplayPower
import "Bridge.js" as Bridge
import "designs/Strings.js" as Strings
import "designs" as Parts

Item {
  required property var root


  // What `omarchy-shell lock explore` opens: the side panel, which has a
  // button for the full explorer, or the full explorer straight away. Saved on
  // the plugin entry as `openAs`. An entry from before the side panel has
  // settings on it and no `openAs`, and keeps opening the full explorer; a new
  // install opens the panel. writeEntry() puts the answer on the entry with
  // the first setting saved, so it does not flip once there is one.
  property string openAsOverride: ""
  readonly property string configuredOpenAs: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (!entry || String(entry.id || "") !== root.pluginId) continue
      if (entry.openAs === "panel" || entry.openAs === "full") return entry.openAs
      return root.settingKeys(entry).length > 0 ? "full" : "panel"
    }
    return "panel"
  }
  readonly property string openAs: root.openAsOverride.length > 0 ? openAsOverride : root.configuredOpenAs

  function setOpenAs(value) {
    var v = String(value || "")
    if (v !== "panel" && v !== "full") return false
    root.openAsOverride = v
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      current.openAs = v
      root.writeEntry(current)
    }
    root.logEvent("open-as=" + v)
    return true
  }

  // The side panel's first-open tour has been through, or skipped. Saved on
  // the plugin entry as `tourSeen`, so it shows once per install.
  property int tourSeenOverride: -1
  readonly property bool configuredTourSeen: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.tourSeen !== undefined)
        return entry.tourSeen === true || String(entry.tourSeen) === "true"
    }
    return false
  }
  readonly property bool tourSeen: root.tourSeenOverride >= 0 ? root.tourSeenOverride === 1 : root.configuredTourSeen

  function setTourSeen(value) {
    var on = value === true || value === "true" || value === 1 || value === "1" || value === "on"
    if (on === root.tourSeen) return true
    root.tourSeenOverride = on ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) current.tourSeen = true
      else delete current.tourSeen
      root.writeEntry(current)
    }
    return true
  }

  // After an unlock, a notification for the failed attempts made while you
  // were away. On by default: it says nothing unless somebody tried. Saved on
  // the plugin entry as `awayReportOff` only when it is turned off.
  property int awayReportOverride: -1
  readonly property bool configuredAwayReport: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.awayReportOff !== undefined)
        return !(entry.awayReportOff === true || String(entry.awayReportOff) === "true")
    }
    return true
  }
  readonly property bool awayReport: root.awayReportOverride >= 0 ? root.awayReportOverride === 1 : root.configuredAwayReport

  function setAwayReport(value) {
    var on = value === true || value === "true" || value === 1 || value === "1" || value === "on"
    var off = value === false || value === "false" || value === 0 || value === "0" || value === "off"
    if (!on && !off) return false

    root.awayReportOverride = on ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) delete current.awayReportOff
      else current.awayReportOff = true
      root.writeEntry(current)
    }
    root.logEvent("away-report=" + (on ? "on" : "off"))
    return true
  }

  // When each failed attempt of this lock happened. The ones that run into
  // the unlock, each within awayGapMs of the next, are the person unlocking
  // getting it wrong on the way in; anything before that is reported.
  readonly property int awayGapMs: 30000
  property var failureTimes: []
  property var pendingAwayReport: null

  function awayFailures(unlockAt) {
    var times = root.failureTimes.slice()
    var edge = unlockAt
    while (times.length > 0 && edge - times[times.length - 1] <= root.awayGapMs)
      edge = times.pop()
    return times
  }

  function sendAwayReport(times) {
    var count = times.length
    var last = new Date(times[count - 1])
    var today = new Date()
    var locale = Qt.locale(Strings.localeName(root.language))
    var clock = last.toLocaleString(locale, root.twelveHour ? "h:mm AP" : "HH:mm")
    var when = last.toDateString() === today.toDateString() ? clock : last.toLocaleString(locale, "ddd") + " " + clock
    var summary = count === 1 ? root.t("1 failed attempt to unlock") : root.t("%1 failed attempts to unlock").arg(count)
    Quickshell.execDetached(["notify-send", "-a", root.t("Lock screen"), summary,
                             root.t("While the screen was locked, the last at %1").arg(when)])
    root.logEvent("away-report count=" + count)
  }
}
