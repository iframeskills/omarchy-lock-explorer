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


  // Avatar picture for the designs that show the user. The chosen path lives on
  // the plugin entry in shell.json; "none" there means the user cleared it and
  // wants the initial back, an empty setting falls back to the usual dotfiles.
  property string avatarOverride: ""
  readonly property string configuredAvatar: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.avatar) return String(entry.avatar)
    }
    return ""
  }
  property string detectedAvatar: ""
  property int avatarVersion: 0
  readonly property string avatarSetting: root.avatarOverride.length > 0 ? avatarOverride : root.configuredAvatar
  readonly property string avatarPath: root.avatarSetting === "none" ? ""
    : (root.avatarSetting.length > 0 ? avatarSetting : root.detectedAvatar)
  readonly property string avatarUrl: {
    if (root.avatarPath.length === 0) return ""
    var encoded = String(root.avatarPath).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + root.avatarVersion
  }

  // A looping video for the designs that show one (Motion), and a clip that
  // plays over the desktop right after the password checks out. Both live on
  // the plugin entry in shell.json, as `video` and `sting`; "none" there means
  // it was cleared on purpose.
  property string videoOverride: ""
  readonly property string configuredVideo: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.video) return String(entry.video)
    }
    return ""
  }
  readonly property string videoSetting: root.videoOverride.length > 0 ? videoOverride : root.configuredVideo
  readonly property string videoPath: root.videoSetting === "none" ? "" : root.videoSetting

  property string stingOverride: ""
  readonly property string configuredSting: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.sting) return String(entry.sting)
    }
    return ""
  }
  readonly property string stingSetting: root.stingOverride.length > 0 ? stingOverride : root.configuredSting
  readonly property string stingPath: root.stingSetting === "none" ? "" : root.stingSetting
  readonly property string stingUrl: {
    if (root.stingPath.length === 0) return ""
    var encoded = String(root.stingPath).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded
  }

  property int stingVolumeOverride: -1
  readonly property int configuredStingVolume: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.stingVolume !== undefined)
        return Math.max(0, Math.min(100, Number(entry.stingVolume) || 0))
    }
    return 0
  }
  readonly property int stingVolume: root.stingVolumeOverride >= 0 ? stingVolumeOverride : root.configuredStingVolume

  // How fast unlock clips play, 1.0 is natural speed. Applies to the clip
  // designs and the separate unlock clip. Saved on the plugin entry as
  // `clipSpeed` when it is not 1.
  property real clipSpeedOverride: -1
  readonly property real configuredClipSpeed: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.clipSpeed !== undefined) {
        var v = Number(entry.clipSpeed)
        if (isFinite(v) && v > 0) return Math.max(0.25, Math.min(4, v))
      }
    }
    return 1
  }
  readonly property real clipSpeed: root.clipSpeedOverride > 0 ? clipSpeedOverride : root.configuredClipSpeed

  function setClipSpeed(v) {
    var speed = Number(v)
    if (!isFinite(speed) || speed <= 0) return false
    speed = Math.max(0.25, Math.min(4, speed))
    root.clipSpeedOverride = speed
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (speed === 1) delete current.clipSpeed
      else current.clipSpeed = speed
      root.writeEntry(current)
    }
    root.logEvent("clip-speed=" + speed)
    return true
  }
  property bool imagePickReopens: false

  function pickImage(reopenExplorer) {
    if (imagePickProc.running) return false
    root.imagePickReopens = reopenExplorer === true
    imagePickProc.running = true
    return true
  }

  Process {
    id: imagePickProc
    command: ["omarchy-file-select", "--title", "Pick an image for the design", "--extensions", "png jpg jpeg webp svg"]
    stdout: StdioCollector {
      id: imagePickOut
      waitForEnd: true
      onStreamFinished: {
        var picked = String(imagePickOut.text || "").trim().split("\n")[0] || ""
        if (picked.length > 0) root.imagePicked(picked)
        if (root.imagePickReopens && root.shell && typeof root.shell.summon === "function")
          root.shell.summon(root.pluginId, "{}")
        root.imagePickReopens = false
      }
    }
  }

  // ------------------------------------------------------------------ avatar

  function setAvatar(path) {
    var value = String(path || "").trim()
    if (value.indexOf("file://") === 0) value = decodeURIComponent(value.replace(/^file:\/\//, ""))
    var setting = value.length > 0 ? value : "none"
    root.avatarOverride = setting
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      current.avatar = setting
      root.writeEntry(current)
    }
    root.avatarVersion += 1
    root.logEvent("avatar=" + setting)
    return true
  }

  function clearAvatar() {
    return root.setAvatar("")
  }

  // Back to the detected ~/.face and friends.
  function resetAvatar() {
    root.avatarOverride = ""
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      delete current.avatar
      root.writeEntry(current)
    }
    root.avatarVersion += 1
    root.detectAvatar()
    root.logEvent("avatar=auto")
    return true
  }

  function detectAvatar() {
    if (!detectAvatarProc.running) detectAvatarProc.running = true
  }

  // The desktop file chooser, so picking a picture is a normal file dialog.
  // The explorer grabs the keyboard, so it closes itself before asking for one
  // and comes back when the dialog is answered.
  property bool avatarPickReopens: false
  function pickAvatar(reopenExplorer) {
    if (avatarPickProc.running) return false
    root.avatarPickReopens = reopenExplorer === true
    avatarPickProc.running = true
    return true
  }

  readonly property string detectAvatarScript: '
for f in "$HOME/.config/omarchy/lock-avatar.png" "$HOME/.config/omarchy/lock-avatar.jpg" \
         "$HOME/.config/omarchy/lock-avatar.jpeg" "$HOME/.config/omarchy/lock-avatar.webp" \
         "$HOME/.face" "$HOME/.face.icon" "/var/lib/AccountsService/icons/$USER"; do
  [[ -f $f ]] && { echo "$f"; exit 0; }
done
'

  Process {
    id: detectAvatarProc
    command: ["bash", "-c", root.detectAvatarScript]
    stdout: StdioCollector {
      id: detectAvatarOut
      waitForEnd: true
      onStreamFinished: {
        var found = String(detectAvatarOut.text || "").trim().split("\n")[0] || ""
        if (found !== root.detectedAvatar) {
          root.detectedAvatar = found
          root.avatarVersion += 1
        }
      }
    }
  }

  Process {
    id: avatarPickProc
    command: ["omarchy-file-select", "--title", "Pick a lock screen avatar", "--extensions", "png jpg jpeg webp"]
    stdout: StdioCollector {
      id: avatarPickOut
      waitForEnd: true
      onStreamFinished: {
        var picked = String(avatarPickOut.text || "").trim().split("\n")[0] || ""
        if (picked.length > 0) root.setAvatar(picked)
        if (root.avatarPickReopens && root.shell && typeof root.shell.summon === "function")
          root.shell.summon(root.pluginId, "{}")
        root.avatarPickReopens = false
      }
    }
  }

  // ------------------------------------------------------------------- video

  function setVideo(path) {
    var value = String(path || "").trim()
    if (value.indexOf("file://") === 0) value = decodeURIComponent(value.replace(/^file:\/\//, ""))
    var setting = value.length > 0 ? value : "none"
    root.videoOverride = setting
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (setting === "none") delete current.video
      else current.video = setting
      root.writeEntry(current)
    }
    root.logEvent("video=" + setting)
    return true
  }

  function clearVideo() { return root.setVideo("") }

  function setSting(path) {
    var value = String(path || "").trim()
    if (value.indexOf("file://") === 0) value = decodeURIComponent(value.replace(/^file:\/\//, ""))
    var setting = value.length > 0 ? value : "none"
    root.stingOverride = setting
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (setting === "none") delete current.sting
      else current.sting = setting
      root.writeEntry(current)
    }
    root.logEvent("sting=" + setting)
    return true
  }

  function clearSting() { return root.setSting("") }

  function setStingVolume(value) {
    var text = String(value === undefined ? "" : value).trim()
    var v = Math.round(Number(text))
    if (text.length === 0 || !isFinite(v) || v < 0 || v > 100) return false
    root.stingVolumeOverride = v
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (v === 0) delete current.stingVolume
      else current.stingVolume = v
      root.writeEntry(current)
    }
    root.logEvent("sting-volume=" + v)
    return true
  }

  // Same dance as the avatar picker: the explorer steps aside for the dialog.
  property bool videoPickReopens: false
  property string videoPickTarget: "video"
  function pickVideo(reopenExplorer, target) {
    if (videoPickProc.running) return false
    root.videoPickTarget = String(target || "video")
    root.videoPickReopens = reopenExplorer === true
    videoPickProc.command = ["omarchy-file-select",
      "--title", root.videoPickTarget === "sting" ? "Pick an unlock clip"
        : root.videoPickTarget === "clip" ? "Pick a video for a new clip design"
        : "Pick a lock screen video",
      "--extensions", "mp4 mkv webm mov m4v"]
    videoPickProc.running = true
    return true
  }

  Process {
    id: videoPickProc
    stdout: StdioCollector {
      id: videoPickOut
      waitForEnd: true
      onStreamFinished: {
        var picked = String(videoPickOut.text || "").trim().split("\n")[0] || ""
        if (picked.length > 0) {
          if (root.videoPickTarget === "sting") root.setSting(picked)
          else if (root.videoPickTarget === "clip") root.createClipDesign(picked)
          else root.setVideo(picked)
        }
        if (root.videoPickReopens && root.shell && typeof root.shell.summon === "function")
          root.shell.summon(root.pluginId, "{}")
        root.videoPickReopens = false
      }
    }
  }

  function createClipDesign(path) {
    var src = String(path || "").trim()
    if (src.indexOf("file://") === 0) src = decodeURIComponent(src.replace(/^file:\/\//, ""))
    if (src.length === 0 || clipDesignProc.running) return false
    var importLine = 'import "../plugins/' + root.pluginId + '/designs"'
    clipDesignProc.command = ["bash", "-c", root.clipDesignScript, root.safePathsLib,
      src, root.home + "/.config/omarchy/lock-videos", root.userDesignsDir, importLine]
    clipDesignProc.running = true
    return true
  }

  readonly property string clipDesignScript: '
set -e; source "$0"
src="$1"; videos="$2"; dir="$3"; imp="$4"
safe_dir "$videos"; safe_dir "$dir"
base=$(basename "$src")
# The copied name is embedded in QML, comments and tab-separated metadata.
# Keep it inert in all three, and compatible with the clipName scanner.
# Only the imported copy is renamed; the source file is left untouched.
base=$(printf %s "$base" | LC_ALL=C tr -c "a-zA-Z0-9._-" "_")
if [[ -e "$videos/$base" ]] && ! cmp -s "$src" "$videos/$base"; then
  stem="${base%.*}"; ext="${base##*.}"; n=2
  while [[ -e "$videos/$stem-$n.$ext" ]]; do n=$((n+1)); done
  base="$stem-$n.$ext"
fi
[[ -e "$videos/$base" ]] || put_file "$videos" "$base" < "$src"
stem="${base%.*}"
name=$(printf %s "$stem" | tr -cd "[:alnum:]_-")
[[ -n "$name" ]] || name=Clip
target="$dir/$name.qml"; n=2
while [[ -e "$target" ]]; do target="$dir/$name$n.qml"; n=$((n+1)); done
q=\'"\'
{
  echo "// Clip design: $base holds its first frame while locked and plays"
  echo "// through as the unlock. The video lives in ~/.config/omarchy/lock-videos."
  echo "$imp"
  echo ""
  echo "ClipDesign { clipName: $q$base$q }"
} | put_file "$dir" "$(basename "$target")"
printf "%s\\t%s\\n" "$target" "$base"
'

  Process {
    id: clipDesignProc
    stdout: StdioCollector {
      id: clipDesignOut
      waitForEnd: true
      onStreamFinished: {
        var last = String(clipDesignOut.text || "").trim().split("\n").pop() || ""
        var parts = last.split("\t")
        var target = (parts[0] || "").trim()
        if (target.length === 0) return
        var d = Designs.fromUserFile(target)
        d.anim = true
        d.clip = true
        if (parts.length > 1 && parts[1].trim().length > 0) d.clipFile = parts[1].trim()
        root.userDesigns = root.userDesigns.concat([d])
        root.designsRevision += 1
        root.rescanUserDesigns()
        root.clipDesignAdded(d.id)
        root.logEvent("clip-design=" + target)
      }
    }
  }

  // The clip that plays once the lock surface is gone. It runs over the live
  // desktop rather than holding the session lock, so nothing it does can leave
  // the screen stuck: any key, any click, the end of the clip or the failsafe
  // timer takes it away.
  property bool stingPlaying: false

  function playSting() {
    if (root.stingPath.length === 0 || root.stingPlaying) return false
    // No player without qt6-multimedia; setting stingPlaying anyway would
    // stick, since only the window's timers ever call endSting().
    if (!root.multimediaAvailable) return false
    root.stingPlaying = true
    root.logEvent("sting-playing")
    return true
  }

  function endSting() {
    if (!root.stingPlaying) return
    root.stingPlaying = false
    root.logEvent("sting-done")
    root.commitClipWallpaper()
  }

  // "The last frame becomes your wallpaper": with clipWallpaper on, the frame
  // the unlock video ends on is extracted while the screen is still locked and
  // handed to omarchy-theme-bg-set the moment the clip gives the screen back,
  // so the desktop opens exactly where the video stopped. Saved on the plugin
  // entry as `clipWallpaper: true`, off by default.
  property int clipWallpaperOverride: -1
  readonly property bool configuredClipWallpaper: {
    var cfg = root.settingsConfig
    var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && String(entry.id || "") === root.pluginId && entry.clipWallpaper === true) return true
    }
    return false
  }
  readonly property bool clipWallpaper: root.clipWallpaperOverride === -1 ? configuredClipWallpaper : root.clipWallpaperOverride === 1

  function setClipWallpaper(on) {
    var enabled = on === true || on === "true" || on === "on"
    root.clipWallpaperOverride = enabled ? 1 : 0
    if (root.shell && typeof root.shell.updateEntryInline === "function") {
      var current = root.pluginEntry()
      if (enabled) current.clipWallpaper = true
      else delete current.clipWallpaper
      root.writeEntry(current)
    }
    root.logEvent("clip-wallpaper=" + enabled)
    return true
  }

  property string preparedClipWallpaper: ""

  function prepareClipWallpaper(path) {
    if (!root.clipWallpaper || !path || String(path).length === 0) return
    if (clipWallPrepProc.running) return
    root.preparedClipWallpaper = ""
    clipWallPrepProc.command = ["bash", "-c", root.clipWallScript, root.safePathsLib,
      String(path), root.home + "/.local/state/omarchy/lock-explorer-clip-wallpapers"]
    clipWallPrepProc.running = true
  }

  function commitClipWallpaper() {
    if (!root.clipWallpaper || root.preparedClipWallpaper.length === 0) return
    Quickshell.execDetached(["omarchy-theme-bg-set", root.preparedClipWallpaper])
    root.logEvent("clip-wallpaper-set=" + root.preparedClipWallpaper)
  }

  readonly property string clipWallScript: '
set -e; source "$0"
src="$1"; dir="$2"
safe_dir "$dir"
stem=$(basename "$src"); stem="${stem%.*}"
out="$dir/$stem.png"
if [[ ! -s "$out" || "$src" -nt "$out" ]]; then
  tmp=$(mktemp --suffix=.png)
  trap "rm -f -- $tmp" EXIT
  # A local video container from a file only, as in plymouth/cliptwin.sh.
  clip_in=(-protocol_whitelist file -format_whitelist mov,mp4,m4a,3gp,3g2,mj2,matroska,webm)
  ffmpeg -y -loglevel error -sseof -1 "${clip_in[@]}" -i "$src" -update 1 "$tmp" || true
  [[ -s "$tmp" ]] || ffmpeg -y -loglevel error "${clip_in[@]}" -i "$src" -update 1 "$tmp"
  put_file "$dir" "$stem.png" < "$tmp"
fi
echo "$out"
'

  Process {
    id: clipWallPrepProc
    stdout: StdioCollector {
      id: clipWallPrepOut
      waitForEnd: true
      onStreamFinished: {
        root.preparedClipWallpaper = String(clipWallPrepOut.text || "").trim().split("\n").pop() || ""
      }
    }
  }

  // The unlock clip window (see StingWindow.qml). It is the only part of the
  // service that touches QtMultimedia, so it loads through this Loader:
  // without qt6-multimedia the load fails, the video features switch off and
  // the rest of the service — the lock screen and the `lock` IPC target —
  // carries on. Importing QtMultimedia at the top of this file instead would
  // take the whole service down with a bare "Target not found".
  readonly property bool multimediaAvailable: stingLoader.status === Loader.Ready

  Loader {
    id: stingLoader
    source: Qt.resolvedUrl("StingWindow.qml")
    onLoaded: item.lock = root
    onStatusChanged: {
      if (status === Loader.Error) {
        console.warn("lock-explorer: qt6-multimedia is not installed; video designs and unlock clips are disabled."
          + " Install it with `sudo pacman -S qt6-multimedia`, then run `omarchy restart shell`.")
      }
    }
  }
}
