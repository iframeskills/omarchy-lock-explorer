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

  property string designOverride: ""
  readonly property string configuredDesignId: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.design) return String(entry.design)
    }
    return Designs.DEFAULT_ID
  }
  readonly property string designId: root.designOverride.length > 0 ? designOverride : root.configuredDesignId
  readonly property bool designHasClip: {
    var r = root.designsRevision
    var d = Designs.byId(root.designId, root.userDesigns)
    return !!(d && d.clip)
  }
  // The video file behind the current clip design; user ClipDesigns get their
  // clipFile filled in by the lock-designs scan.
  readonly property string designClipPath: {
    var r = root.designsRevision
    var d = Designs.byId(root.designId, root.userDesigns)
    if (!d || !d.clip || !d.clipFile) return ""
    return root.home + "/.config/omarchy/lock-videos/" + d.clipFile
  }

  // 24-hour clocks by default; on, every design's clock reads 12-hour with
  // AM/PM. Saved on the plugin entry as `clock12` only when it is on, so a
  // 24-hour setup keeps the entry it always had.
  property int twelveHourOverride: -1
  readonly property bool configuredTwelveHour: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.clock12 !== undefined)
        return entry.clock12 === true || String(entry.clock12) === "true"
    }
    return false
  }
  readonly property bool twelveHour: root.twelveHourOverride >= 0 ? root.twelveHourOverride === 1 : root.configuredTwelveHour

  function setTwelveHour(v) {
    var on = v === true || v === 1 || v === "true" || v === "12" || v === "on"
    root.twelveHourOverride = on ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) current.clock12 = true
      else delete current.clock12
      root.writeEntry(current)
    }
    root.logEvent("clock=" + (on ? "12h" : "24h"))
    return true
  }

  // Designs starred with F in the explorer, listed under Favorites. Saved on
  // the plugin entry as `favorites`, a list of design ids, only once there is
  // one; ids of designs that no longer exist are kept and simply not shown.
  property var favoritesOverride: null
  readonly property var configuredFavorites: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && Array.isArray(entry.favorites))
        return entry.favorites.map(function(id) { return String(id) })
    }
    return []
  }
  readonly property var favorites: root.favoritesOverride !== null ? favoritesOverride : root.configuredFavorites

  function setFavorite(id, on) {
    var key = String(id || "")
    if (key.length === 0 || !Designs.byId(key, root.userDesigns)) return false
    var next = root.favorites.filter(function(f) { return f !== key })
    if (on) next.push(key)
    root.favoritesOverride = next
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (next.length > 0) current.favorites = next
      else delete current.favorites
      root.writeEntry(current)
    }
    root.logEvent("favorite " + key + "=" + (on ? "on" : "off"))
    return true
  }

  function toggleFavorite(id) {
    return root.setFavorite(id, root.favorites.indexOf(String(id || "")) === -1)
  }

  // What the password field shows beside the text, each shown unless hidden
  // in Settings. Saved on the plugin entry as hideLayoutBadge, hideCapsBadge,
  // hidePasswordToggle and hideAuthIcons, and only while hidden.
  readonly property var fieldItems: ({ layout: "hideLayoutBadge", caps: "hideCapsBadge",
                                       reveal: "hidePasswordToggle", icons: "hideAuthIcons" })
  property var fieldItemOverrides: ({})
  function fieldItemHidden(key) {
    if (root.fieldItemOverrides[key] !== undefined) return root.fieldItemOverrides[key]
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId) return entry[key] === true
    }
    return false
  }
  readonly property bool showLayoutBadge: !root.fieldItemHidden("hideLayoutBadge")
  readonly property bool showCapsBadge: !root.fieldItemHidden("hideCapsBadge")
  readonly property bool allowPasswordToggle: !root.fieldItemHidden("hidePasswordToggle")
  readonly property bool showAuthIcons: !root.fieldItemHidden("hideAuthIcons")

  function setFieldItem(name, show) {
    var key = root.fieldItems[String(name || "")]
    if (!key) return false
    var on = show === true || show === "true" || show === "on" || show === "show" || show === 1
    var next = {}
    for (var k in root.fieldItemOverrides) next[k] = root.fieldItemOverrides[k]
    next[key] = !on
    root.fieldItemOverrides = next
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) delete current[key]
      else current[key] = true
      root.writeEntry(current)
    }
    root.logEvent("field-" + name + "=" + (on ? "show" : "hide"))
    return true
  }

  // The lock screen's language: the system's (LANG, through Qt.locale()) when
  // Strings.js has it, English otherwise, or one picked in Settings. Saved on
  // the plugin entry as `language` only once it is picked.
  readonly property var languages: Strings.LANGUAGES
  readonly property string systemLanguage: Strings.fromLocale(Qt.locale().name)
  property string languageOverride: ""
  readonly property string configuredLanguage: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.language !== undefined && Strings.known(String(entry.language)))
        return String(entry.language)
    }
    return "auto"
  }
  readonly property string languageSetting: root.languageOverride.length > 0 ? languageOverride : root.configuredLanguage
  readonly property string language: root.languageSetting === "auto" ? systemLanguage : root.languageSetting
  function t(text) { return Strings.tr(root.language, text) }

  function setLanguage(value) {
    var text = String(value === undefined ? "" : value).trim().toLowerCase()
    if (text !== "auto") text = text === "no" || text === "nn" ? "nb" : text
    if (text !== "auto" && !Strings.known(text)) return false
    root.languageOverride = text
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (text === "auto") delete current.language
      else current.language = text
      root.writeEntry(current)
    }
    root.logEvent("language=" + text)
    return true
  }

  // Reduce motion: off, on, or only while on battery. Size: how much larger
  // than the design drew itself the lock screen is shown. Both are applied by
  // LockHost to every design, and saved on the plugin entry as `reduceMotion`
  // and `uiScale` only once they are changed.
  readonly property var reduceMotionOptions: ["off", "on", "battery"]
  readonly property var uiScaleOptions: [1, 1.25, 1.5]
  property string reduceMotionOverride: ""
  property real uiScaleOverride: 0
  readonly property string configuredReduceMotion: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && root.reduceMotionOptions.indexOf(String(entry.reduceMotion)) !== -1)
        return String(entry.reduceMotion)
    }
    return "off"
  }
  readonly property real configuredUiScale: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && root.uiScaleOptions.indexOf(Number(entry.uiScale)) !== -1)
        return Number(entry.uiScale)
    }
    return 1
  }
  readonly property string reduceMotion: root.reduceMotionOverride.length > 0 ? reduceMotionOverride : root.configuredReduceMotion
  readonly property real uiScale: root.uiScaleOverride > 0 ? uiScaleOverride : root.configuredUiScale
  readonly property bool onBattery: powerState.item ? powerState.item.onBattery === true : false
  // A battery running down while the screen is locked is easy to miss: the
  // lock screen says so at this level or below, on every design, while the
  // machine is not charging.
  readonly property int batteryLowAt: 15
  readonly property int batteryPercent: powerState.item ? powerState.item.percent : -1
  readonly property bool batteryLow: root.onBattery && root.batteryPercent >= 0 && root.batteryPercent <= root.batteryLowAt
  readonly property bool motionReduced: root.reduceMotion === "on" || (root.reduceMotion === "battery" && root.onBattery)

  Loader {
    id: powerState
    source: "PowerState.qml"
  }

  function setReduceMotion(value) {
    var text = String(value === undefined ? "" : value).trim().toLowerCase()
    if (text === "true" || text === "1") text = "on"
    if (text === "false" || text === "0") text = "off"
    if (root.reduceMotionOptions.indexOf(text) === -1) return false
    root.reduceMotionOverride = text
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (text === "off") delete current.reduceMotion
      else current.reduceMotion = text
      root.writeEntry(current)
    }
    root.logEvent("reduce-motion=" + text)
    return true
  }

  function setUiScale(value) {
    var text = String(value === undefined ? "" : value).trim().replace(/%$/, "")
    var n = Number(text)
    if (n >= 50) n = n / 100
    if (root.uiScaleOptions.indexOf(n) === -1) return false
    root.uiScaleOverride = n
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (n === 1) delete current.uiScale
      else current.uiScale = n
      root.writeEntry(current)
    }
    root.logEvent("ui-scale=" + n)
    return true
  }

  // How the wallpaper behind a design looks. Blur replaces the design's own
  // (sharp, soft or heavy); dim moves the design's own up or down, since some
  // designs darken the picture a lot to keep their text readable and one
  // value for all of them would undo that. "design" leaves both alone and is
  // not written, so the entry only gets `wallpaperBlur` / `wallpaperDim` once
  // they are changed.
  readonly property var wallpaperBlurOptions: ({ design: -1, sharp: 0, soft: 0.45, heavy: 1 })
  readonly property var wallpaperDimOptions: ({ design: 0, lighter: -0.15, darker: 0.2 })
  property string wallpaperBlurOverride: ""
  property string wallpaperDimOverride: ""
  function configuredWallpaperOption(key, options) {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && options[String(entry[key])] !== undefined)
        return String(entry[key])
    }
    return "design"
  }
  readonly property string wallpaperBlur: root.wallpaperBlurOverride.length > 0 ? wallpaperBlurOverride
                                                                           : root.configuredWallpaperOption("wallpaperBlur", root.wallpaperBlurOptions)
  readonly property string wallpaperDim: root.wallpaperDimOverride.length > 0 ? wallpaperDimOverride
                                                                         : root.configuredWallpaperOption("wallpaperDim", root.wallpaperDimOptions)
  readonly property real wallpaperBlurValue: root.wallpaperBlurOptions[root.wallpaperBlur]
  readonly property real wallpaperDimShift: root.wallpaperDimOptions[root.wallpaperDim]

  function setWallpaperOption(key, value, options) {
    var text = String(value === undefined ? "" : value).trim().toLowerCase()
    if (options[text] === undefined) return false
    if (key === "wallpaperBlur") root.wallpaperBlurOverride = text
    else root.wallpaperDimOverride = text
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (text === "design") delete current[key]
      else current[key] = text
      root.writeEntry(current)
    }
    root.logEvent(key + "=" + text)
    return true
  }
  function setWallpaperBlur(value) { return root.setWallpaperOption("wallpaperBlur", value, root.wallpaperBlurOptions) }
  function setWallpaperDim(value) { return root.setWallpaperOption("wallpaperDim", value, root.wallpaperDimOptions) }

  // Previous, play or pause, and next on the lock screen for whatever is
  // playing, with its title. Off by default: a locked screen says nothing
  // about what is playing unless asked to. Saved on the plugin entry as
  // `mediaControls`, and only on the screen the password goes in.
  property int mediaControlsOverride: -1
  readonly property bool configuredMediaControls: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId) return entry.mediaControls === true
    }
    return false
  }
  readonly property bool mediaControls: root.mediaControlsOverride >= 0 ? root.mediaControlsOverride === 1 : root.configuredMediaControls

  function setMediaControls(value) {
    var on = value === true || value === "true" || value === 1 || value === "1" || value === "on"
    var off = value === false || value === "false" || value === 0 || value === "0" || value === "off"
    if (!on && !off) return false

    root.mediaControlsOverride = on ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) current.mediaControls = true
      else delete current.mediaControls
      root.writeEntry(current)
    }
    root.logEvent("media-controls=" + (on ? "on" : "off"))
    return true
  }

  // The design can follow the Omarchy theme. While this is on, the design
  // picked in the explorer is remembered for the theme that is active, and a
  // theme change brings that theme's design back; a theme with nothing
  // remembered keeps whatever is up. Saved on the plugin entry as `followTheme`
  // and `themeDesigns` ({ theme name: design id }). Off by default, and the
  // map stays when it is turned off, so turning it on again finds it.
  property int followThemeOverride: -1
  readonly property bool configuredFollowTheme: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId) return entry.followTheme === true
    }
    return false
  }
  readonly property bool followTheme: root.followThemeOverride >= 0 ? root.followThemeOverride === 1 : root.configuredFollowTheme
  property var themeDesignsOverride: null
  readonly property var configuredThemeDesigns: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (!entry || String(entry.id || "") !== root.pluginId) continue
      var map = entry.themeDesigns
      return map && typeof map === "object" && !Array.isArray(map) ? map : {}
    }
    return {}
  }
  readonly property var themeDesigns: root.themeDesignsOverride ? themeDesignsOverride : root.configuredThemeDesigns

  // themeDesigns with the current theme set to `id`; also the new override.
  function rememberThemeDesign(id) {
    var map = Util.cloneJson(root.themeDesigns) || {}
    if (root.bootCurrentTheme.length > 0) map[root.bootCurrentTheme] = String(id)
    root.themeDesignsOverride = map
    return map
  }

  function setFollowTheme(value) {
    var on = value === true || value === "true" || value === 1 || value === "1" || value === "on"
    var off = value === false || value === "false" || value === 0 || value === "0" || value === "off"
    if (!on && !off) return false

    root.followThemeOverride = on ? 1 : 0
    // Turning it on starts from the design that is up, so the current theme
    // has one straight away.
    var map = on ? root.rememberThemeDesign(root.designId) : root.themeDesigns
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (on) current.followTheme = true
      else delete current.followTheme
      if (Object.keys(map).length > 0) current.themeDesigns = map
      root.writeEntry(current)
    }
    root.logEvent("follow-theme=" + (on ? "on" : "off"))
    return true
  }

  // On a theme change, and once at startup for a theme switched while the
  // shell was off: the design remembered for the theme that is now active.
  function followThemeDesign() {
    if (!root.followTheme || root.rotateDesigns !== "off" || root.bootCurrentTheme.length === 0) return
    var want = root.themeDesigns[root.bootCurrentTheme]
    if (!want || String(want) === root.designId || !Designs.byId(String(want), root.userDesigns)) return
    root.logEvent("theme-design " + root.bootCurrentTheme + " -> " + want)
    root.setDesign(String(want))
  }

  // A line for whoever finds the computer, drawn by DesignBase in the bottom
  // left corner of every design. Saved on the plugin entry as `ownerMessage`;
  // empty, the default, draws nothing. Whitespace is collapsed and the
  // length capped so a corner note stays one.
  property var ownerMessageOverride: null
  readonly property string configuredOwnerMessage: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      // The same cap as setOwnerMessage: the file can say anything.
      if (entry && String(entry.id || "") === root.pluginId && entry.ownerMessage !== undefined) return String(entry.ownerMessage).substring(0, 120)
    }
    return ""
  }
  readonly property string ownerMessage: root.ownerMessageOverride !== null ? ownerMessageOverride : root.configuredOwnerMessage
  readonly property int ownerMessageMaxLength: 120

  function setOwnerMessage(value) {
    var text = String(value === undefined || value === null ? "" : value).replace(/\s+/g, " ").trim()
    if (text.length > root.ownerMessageMaxLength) return false
    root.ownerMessageOverride = text
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (text.length > 0) current.ownerMessage = text
      else delete current.ownerMessage
      root.writeEntry(current)
    }
    root.logEvent("owner-message=" + (text.length > 0 ? "set" : "cleared"))
    return true
  }

  // The favorites can take turns: the next one each time the screen locks,
  // or a new one each day. Saved on the plugin entry as `rotateDesigns` (lock
  // or day; absent is off) and, for the daily turn, `rotatedOn`, the day it
  // last turned. Fewer than two favorites leaves nothing to rotate. While it
  // is on the rotation has the design, so the theme does not
  // (followThemeDesign).
  readonly property var rotateDesignsOptions: ["off", "lock", "day"]
  property string rotateDesignsOverride: ""
  readonly property string configuredRotateDesigns: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && (entry.rotateDesigns === "lock" || entry.rotateDesigns === "day"))
        return entry.rotateDesigns
    }
    return "off"
  }
  readonly property string rotateDesigns: root.rotateDesignsOverride.length > 0 ? rotateDesignsOverride : root.configuredRotateDesigns
  property string rotatedOnOverride: ""
  readonly property string configuredRotatedOn: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.rotatedOn) return String(entry.rotatedOn)
    }
    return ""
  }
  readonly property string rotatedOn: root.rotatedOnOverride.length > 0 ? rotatedOnOverride : root.configuredRotatedOn

  function setRotateDesigns(value) {
    var v = String(value || "")
    if (root.rotateDesignsOptions.indexOf(v) === -1) return false
    root.rotateDesignsOverride = v
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (v === "off") {
        delete current.rotateDesigns
        delete current.rotatedOn
      } else {
        current.rotateDesigns = v
      }
      root.writeEntry(current)
    }
    root.logEvent("rotate-designs=" + v)
    return true
  }

  function localDay() {
    var d = new Date()
    return d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2)
  }

  // As the screen locks: the next favorite, when it is time for one. A
  // current design that is not a favorite hands over to the first.
  function rotateDesign() {
    if (root.rotateDesigns === "off") return
    var pool = root.favorites.filter(function(id) { return !!Designs.byId(id, root.userDesigns) })
    if (pool.length < 2) return
    var day = root.localDay()
    if (root.rotateDesigns === "day" && root.rotatedOn === day) return
    var next = pool[(pool.indexOf(root.designId) + 1) % pool.length]
    if (root.rotateDesigns === "day") root.rotatedOnOverride = day
    root.logEvent("rotate-design " + root.designId + " -> " + next)
    root.setDesign(next, root.rotateDesigns === "day" ? day : "turn")
  }

  // `how` says what kind of pick this is. Nothing: a pick, filed under the
  // theme that is on while the design follows the theme. "all": a pick for
  // every theme, which forgets the per-theme picks so this design shows
  // whatever theme comes up. "turn", or a day: a rotation turn (rotateDesign),
  // which is not a pick, so the theme does not remember it; the day is saved.
  function setDesign(id, how) {
    var d = Designs.byId(String(id || ""), root.userDesigns)
    if (!d) return false
    root.designOverride = d.id
    var everywhere = how === "all"
    var map = root.followTheme && !how ? root.rememberThemeDesign(d.id) : null
    if (everywhere) root.themeDesignsOverride = {}
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      current.design = d.id
      if (map) current.themeDesigns = map
      if (everywhere) delete current.themeDesigns
      if (how && how !== "turn" && !everywhere) current.rotatedOn = how
      root.writeEntry(current)
    }
    root.logEvent("design=" + d.id + (everywhere ? " all-themes" : ""))
    if (root.bootSetting === "follow") root.applyBoot(false)
    return true
  }
}
