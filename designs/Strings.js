.pragma library
.import "StringsData.js" as Data

// What the lock screen says, in the languages below. The explorer itself is
// English; this covers what everyone sees on a locked screen: prompts,
// greetings, failures, status lines. Keys are the English text; a design asks
// for it through `lock.tr("Press Enter to unlock")` and gets it back unchanged
// in English or in a language without that line yet.
//
// A string made of parts ("󰌾  Locked  ·  Esc clears input") is translated a
// part at a time, the icon in front of a part is kept, and a part written in
// capitals or all lowercase comes back the same way, so one entry serves
// "LOCKED", "locked" and "Locked". %1 is filled in by the caller with .arg().
//
// The languages and their text are in StringsData.js. Corrections and new
// languages are welcome: add a block to TEXT there, and a line to LANGUAGES.

var TEXT = Data.TEXT
var LANGUAGES = Data.LANGUAGES

// Lowercased keys, built once, remembering how the English was written.
// ExplorerStrings.js builds its own table the same way.
function makeLookup(text) {
  var out = {}
  for (var lang in text) {
    out[lang] = {}
    for (var key in text[lang]) out[lang][key.toLowerCase()] = { key: key, text: text[lang][key] }
  }
  return out
}
var LOOKUP = makeLookup(TEXT)

function known(id) {
  for (var i = 0; i < LANGUAGES.length; i++) if (LANGUAGES[i].id === id) return true
  return false
}

// "de_DE.UTF-8", "pt_BR", "nn_NO" -> a language this file has, or "en".
function fromLocale(name) {
  var code = String(name || "").toLowerCase().split(/[_.@-]/)[0]
  if (code === "no" || code === "nn") code = "nb"
  return known(code) ? code : "en"
}

function localeName(id) {
  for (var i = 0; i < LANGUAGES.length; i++) if (LANGUAGES[i].id === id) return LANGUAGES[i].locale
  return "en_US"
}

function piece(table, part) {
  // Whatever stands in front of the words (an icon, spaces) is kept as is.
  var m = /^([^A-Za-zÀ-ÿ0-9%]*)([\s\S]*?)(\s*)$/.exec(part)
  var core = m ? m[2] : ""
  if (core.length === 0) return null
  var hit = table[core.toLowerCase()]
  if (hit === undefined) return null
  var text = hit.text
  // Written the way the English entry is: as translated. Otherwise the
  // design chose capitals or lowercase for the look, and gets them.
  if (core !== hit.key) {
    if (core === core.toUpperCase() && core !== core.toLowerCase()) text = text.toUpperCase()
    else if (core === core.toLowerCase() && core !== core.toUpperCase()) text = text.toLowerCase()
  }
  return m[1] + text + m[3]
}

function tr(lang, text) {
  return trWith(LOOKUP, lang, text)
}

function trWith(lookup, lang, text) {
  var s = String(text === undefined || text === null ? "" : text)
  var table = lookup[lang]
  if (!table || s.length === 0) return s
  var whole = piece(table, s)
  if (whole !== null) return whole
  var parts = s.split(/(\s+·\s+)/)
  if (parts.length === 1) return s
  for (var i = 0; i < parts.length; i += 2) {
    var t = piece(table, parts[i])
    if (t !== null) parts[i] = t
  }
  return parts.join("")
}
