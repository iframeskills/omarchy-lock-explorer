.pragma library
.import "ExplorerStringsData.js" as Data
.import "designs/Strings.js" as Base

// The explorer's own text, its boot screen page, designer and code editor included, in the languages of designs/Strings.js and looked
// up the same way (Base.trWith): keys are the English, a line made of parts
// joined by " · " is translated a part at a time, an icon in front is kept,
// and capitals or lowercase come back as the explorer wrote them. %1 and %2
// are filled in by the caller with .arg().

var TEXT = Data.TEXT

var LOOKUP = Base.makeLookup(TEXT)

function tr(lang, text) {
  return Base.trWith(LOOKUP, lang, text)
}
