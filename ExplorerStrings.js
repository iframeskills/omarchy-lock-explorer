.pragma library
.import "explorer-strings/da.js" as Da
.import "explorer-strings/de.js" as De
.import "explorer-strings/es.js" as Es
.import "explorer-strings/fr.js" as Fr
.import "explorer-strings/it.js" as It
.import "explorer-strings/nl.js" as Nl
.import "explorer-strings/nb.js" as Nb
.import "explorer-strings/pl.js" as Pl
.import "explorer-strings/pt.js" as Pt
.import "explorer-strings/sv.js" as Sv
.import "explorer-strings/ko.js" as Ko
.import "designs/Strings.js" as Base

// The explorer's own text, its boot screen page, designer and code editor included, in the languages of designs/Strings.js and looked
// up the same way (Base.trWith): keys are the English, a line made of parts
// joined by " · " is translated a part at a time, an icon in front is kept,
// and capitals or lowercase come back as the explorer wrote them. %1 and %2
// are filled in by the caller with .arg().
//
// Each language has its own file in explorer-strings/. A new line goes into
// every one of them; a new language gets a file there and an entry below.

var TEXT = {
  da: Da.TEXT,
  de: De.TEXT,
  es: Es.TEXT,
  fr: Fr.TEXT,
  it: It.TEXT,
  nl: Nl.TEXT,
  nb: Nb.TEXT,
  pl: Pl.TEXT,
  pt: Pt.TEXT,
  sv: Sv.TEXT,
  ko: Ko.TEXT
}

var LOOKUP = Base.makeLookup(TEXT)

function tr(lang, text) {
  return Base.trWith(LOOKUP, lang, text)
}
