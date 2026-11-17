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


  readonly property string userDesignsDir: root.home + "/.config/omarchy/lock-designs"
  property int designsRevision: 0
  // Designs found in userDesignsDir, see Designs.fromUserFile. Every reader
  // gets this list passed in rather than reading Designs.js module state.
  property var userDesigns: []

  function rescanUserDesigns() {
    if (!userDesignsProc.running) userDesignsProc.running = true
  }

  // The clip designs' videos ship in <plugin>/videos; link any that are
  // missing into ~/.config/omarchy/lock-videos, where ClipDesign and the
  // boot twins resolve them. Idempotent, never overwrites a user's file.
  Process {
    id: shippedClipsProc
    running: true
    command: ["bash", "-c",
      "dst=\"$HOME/.config/omarchy/lock-videos\"; mkdir -p \"$dst\"; for f in \"$0\"/videos/*.mp4; do [ -e \"$f\" ] || continue; b=$(basename \"$f\"); [ -e \"$dst/$b\" ] || ln -s \"$f\" \"$dst/$b\"; done",
      root.pluginDir]
  }

  // Bumps the revision so every LockHost showing a user design reloads it.
  function reloadDesigns() {
    root.designsRevision += 1
  }

  function customizeDesign(id) {
    var d = String(id || "") === "new"
      ? { id: "new", file: "MyDesign.qml", name: "new", template: true }
      : Designs.byId(String(id || ""), root.userDesigns)
    if (!d) return false
    if (d.path) { root.designCustomized(d.id, decodeURIComponent(d.path.replace(/^file:\/\//, ""))); return true }
    var source = d.template ? root.pluginDir + "/extras/lock-designs/" + d.file : root.pluginDir + "/designs/" + d.file
    if (customizeProc.running) return false
    var importLine = 'import "../plugins/' + root.pluginId + '/designs"'
    customizeProc.command = ["bash", "-c", root.customizeScript, root.safePathsLib, source, root.userDesignsDir, d.file.replace(/\.qml$/, ""), d.template ? "" : importLine, d.name]
    customizeProc.running = true
    return true
  }

  readonly property string customizeScript: '
set -e; source "$0"
src="$1"; dir="$2"; base="$3"; imp="$4"; name="$5"
safe_dir "$dir"
target="$dir/$base.qml"; n=2
while [[ -e "$target" ]]; do target="$dir/$base$n.qml"; n=$((n+1)); done
{
  if [[ $name == new ]]; then echo "// New design. Edit it in the explorer (E) or with:"; else echo "// Customized copy of the $name design. Edit it here or with:"; fi
  echo "//   omarchy-shell lock editDesign my-$(basename "$target" .qml | tr "[:upper:]" "[:lower:]")"
  awk -v imp="$imp" \'
    /^import / { last = NR }
    { lines[NR] = $0 }
    END { for (i = 1; i <= NR; i++) { print lines[i]; if (i == last && imp != "") print imp } }
  \' "$src"
} | put_file "$dir" "$(basename "$target")"
echo "$target"
'

  Process {
    id: customizeProc
    stdout: StdioCollector {
      id: customizeOut
      waitForEnd: true
      onStreamFinished: {
        var target = String(customizeOut.text || "").trim()
        if (target.length === 0) return
        var d = Designs.fromUserFile(target)
        root.userDesigns = root.userDesigns.concat([d])
        root.designsRevision += 1
        root.designCustomized(d.id, target)
        root.rescanUserDesigns()
      }
    }
  }

  // Makes the file and hands its path back, so the explorer can drop straight
  // into the designer on it.
  function createDesignerDesign(content) {
    if (designerCreateProc.running) return false
    designerCreateProc.command = ["bash", "-c", root.designerCreateScript, root.safePathsLib, root.userDesignsDir, String(content)]
    designerCreateProc.running = true
    return true
  }

  readonly property string designerCreateScript: '
set -e; source "$0"
dir="$1"; content="$2"
safe_dir "$dir"
target="$dir/MyLayout.qml"; n=2
while [[ -e $target ]]; do target="$dir/MyLayout$n.qml"; n=$((n+1)); done
printf %s "$content" | put_file "$dir" "$(basename "$target")"
echo "$target"
'

  Process {
    id: designerCreateProc
    stdout: StdioCollector {
      id: designerCreateOut
      waitForEnd: true
      onStreamFinished: {
        var target = String(designerCreateOut.text || "").trim()
        if (target.length === 0) return
        var d = Designs.fromUserFile(target)
        d.designer = true
        root.userDesigns = root.userDesigns.concat([d])
        root.designsRevision += 1
        root.designerDesignCreated(d.id, target)
        root.rescanUserDesigns()
        root.logEvent("designer-design=" + d.id)
      }
    }
  }

  // -------------------------------------------------------------- components
  //
  // Pieces saved out of the designer, so they can be dropped into any design
  // later. One JSON file each in ~/.config/omarchy/lock-components, written
  // on a single line; the scan below reads them all in one go.

  readonly property string componentsDir: root.home + "/.config/omarchy/lock-components"
  property var components: []

  function rescanComponents() {
    if (!componentsProc.running) componentsProc.running = true
  }

  function saveComponent(slug, json) {
    var safe = String(slug || "").toLowerCase().replace(/[^a-z0-9-]+/g, "-").replace(/^-+|-+$/g, "")
    if (safe.length === 0 || String(json || "").length === 0) return false
    if (componentSaveProc.running) return false
    if (String(json).length > 65536) return false
    componentSaveProc.command = ["bash", "-c",
      'source "$4" && safe_dir "$1" && printf %s "$3" | put_file "$1" "$2.json"', "savecomponent", root.componentsDir, safe, String(json), root.safePathsLib]
    componentSaveProc.running = true
    root.logEvent("component-saved=" + safe)
    return true
  }

  function deleteComponent(slug) {
    var safe = String(slug || "").toLowerCase().replace(/[^a-z0-9-]+/g, "-").replace(/^-+|-+$/g, "")
    if (safe.length === 0) return false
    if (componentDeleteProc.running) return false
    componentDeleteProc.command = ["bash", "-c",
      'rm -f -- "$1/$2.json"', "delcomponent", root.componentsDir, safe]
    componentDeleteProc.running = true
    root.logEvent("component-deleted=" + safe)
    return true
  }

  Process {
    id: componentsProc
    running: true
    // slug<TAB>json, one component per line. The files the designer writes
    // have no newlines in them; tr keeps a hand-edited one from splitting the
    // listing across lines. Plain files of at most 64 KiB only: a FIFO or a
    // huge file would hold the scan up.
    command: ["bash", "-c",
      'dir="$1"; mkdir -p "$dir"; for f in "$dir"/*.json; do [ -f "$f" ] && [ ! -L "$f" ] && [ "$(stat -c %s -- "$f")" -le 65536 ] || continue; printf "%s\\t" "$(basename "$f" .json)"; head -c 65536 -- "$f" | tr -d "\\n"; printf "\\n"; done',
      "components", root.componentsDir]
    stdout: StdioCollector {
      id: componentsOut
      waitForEnd: true
      onStreamFinished: {
        var lines = String(componentsOut.text || "").split("\n")
        var list = []
        for (var i = 0; i < lines.length; i++) {
          var tab = lines[i].indexOf("\t")
          if (tab === -1) continue
          var slug = lines[i].substring(0, tab).trim()
          try {
            var comp = JSON.parse(lines[i].substring(tab + 1))
            if (comp && comp.nodes instanceof Array) list.push({ slug: slug, comp: comp })
          } catch (e) {
            console.warn("lock-explorer: cannot read component", slug, e)
          }
        }
        list.sort(function(a, b) { return String(a.comp.name).localeCompare(String(b.comp.name)) })
        if (JSON.stringify(list) === JSON.stringify(root.components)) return
        root.components = list
      }
    }
  }

  Process {
    id: componentSaveProc
    onExited: root.rescanComponents()
  }

  Process {
    id: componentDeleteProc
    onExited: root.rescanComponents()
  }

  // Names that are joined into a path under one of the plugin's folders. They
  // arrive over IPC (any process of the account can call it), from the saved
  // settings and from design files, so they are held to a pattern instead of
  // trusted: no separator, no leading dot, no "..".
  function fileItemNameValid(n) {
    var v = String(n || "")
    return /^[A-Za-z0-9_-][A-Za-z0-9._ -]{0,127}$/.test(v) && v.indexOf("..") === -1
  }
  function layoutNameValid(n) {
    return /^[A-Za-z0-9_-]{1,64}$/.test(String(n || ""))
  }
  // A boot option: a design id, or video:/custom:/snapshot: and a name.
  function bootItemValid(v) {
    v = String(v || "")
    if (v.indexOf("custom:") === 0) return root.layoutNameValid(v.substring(7))
    if (v.indexOf("video:") === 0) return root.fileItemNameValid(v.substring(6))
    if (v.indexOf("snapshot:") === 0) return root.fileItemNameValid(v.substring(9))
    return /^[a-z0-9-]{1,32}$/.test(v)
  }

  // Delete a user design from ~/.config/omarchy/lock-designs. A clip design's
  // video goes with it, unless the boot screen, the Motion video or the unlock
  // clip still point at it, or another design names it.
  function deleteDesign(id) {
    var d = Designs.byId(String(id || ""), root.userDesigns)
    if (!d || !d.path) return false
    var file = decodeURIComponent(String(d.path).replace(/^file:\/\//, ""))
    if (file.indexOf(root.userDesignsDir + "/") !== 0) return false
    // The clip name is whatever the design file says; only a plain file name
    // in lock-videos is ever deleted along with it.
    var clip = String(d.clipFile || "")
    if (!root.fileItemNameValid(clip)) clip = ""
    if (clip.length > 0) {
      var tail = "/" + clip
      var keep = root.bootSetting === "video:" + clip
        || (root.videoPath.length >= tail.length && root.videoPath.lastIndexOf(tail) === root.videoPath.length - tail.length)
        || (root.stingPath.length >= tail.length && root.stingPath.lastIndexOf(tail) === root.stingPath.length - tail.length)
      if (keep) clip = ""
    }
    if (root.designId === d.id) root.setDesign(Designs.DEFAULT_ID)
    deleteDesignProc.command = ["bash", "-c", root.deleteDesignScript, "deldesign",
      file, root.home + "/.config/omarchy/lock-videos", clip, root.userDesignsDir]
    deleteDesignProc.running = true
    root.logEvent("delete-design=" + d.id)
    return true
  }

  readonly property string deleteDesignScript: '
set -e
file="$1"; videos="$2"; clip="$3"; dir="$4"
rm -f -- "$file"
if [[ -n $clip ]] && ! grep -D skip -qs -- "$clip" "$dir"/*.qml 2>/dev/null; then
  rm -f -- "$videos/$clip"
fi
'

  Process {
    id: deleteDesignProc
    onExited: function(exitCode) {
      root.rescanUserDesigns()
      root.refreshBootLists()
    }
  }

  Process {
    id: userDesignsProc
    // Files built on ClipDesign are tagged (with their clip file when it is
    // named inline) so they keep their animation flag and their video across
    // rescans.
    command: ["bash", "-c", "for f in \"$0\"/*.qml; do [ -f \"$f\" ] || continue; c=$(grep -o 'clipName: \"[^\"]*\"' \"$f\" 2>/dev/null | head -1 | cut -d'\"' -f2); if [ -n \"$c\" ]; then printf '%s\\tclip\\t%s\\n' \"$f\" \"$c\"; elif grep -q ClipDesign \"$f\" 2>/dev/null; then printf '%s\\tclip\\n' \"$f\"; elif grep -q '// designer:1:' \"$f\" 2>/dev/null; then printf '%s\\tdesigner\\n' \"$f\"; else printf '%s\\n' \"$f\"; fi; done", root.userDesignsDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n").filter(function(l) { return l.trim().length > 0 })
        var list = lines.map(function(l) {
          var parts = l.split("\t")
          var d = Designs.fromUserFile(parts[0].trim())
          if (parts.length > 1 && parts[1].trim() === "clip") { d.anim = true; d.clip = true }
          // Made in the designer: E opens it there instead of in the code editor.
          if (parts.length > 1 && parts[1].trim() === "designer") {
            d.designer = true
            d.description = "Made in the designer"
          }
          if (parts.length > 2 && parts[2].trim().length > 0) d.clipFile = parts[2].trim()
          return d
        })
        if (JSON.stringify(list) !== JSON.stringify(root.userDesigns)) {
          root.userDesigns = list
          root.designsRevision += 1
        }
      }
    }
  }
}
