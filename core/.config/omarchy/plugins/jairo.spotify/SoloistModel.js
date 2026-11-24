.pragma library

var MAX_JSON_BYTES = 65536
var MAX_TEXT_LEN = 160
var MAX_URL_LEN = 512

function clampText(value, maxLen) {
  var limit = maxLen || MAX_TEXT_LEN
  var text = String(value === undefined || value === null ? "" : value)
    .replace(/[\r\n\t]+/g, " ")
    .trim()
  return text.length > limit ? text.slice(0, limit - 1) + "…" : text
}

function neutralizeMarkup(value) {
  return String(value === undefined || value === null ? "" : value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
}

function safeCoverUrl(covers) {
  if (!Array.isArray(covers) || covers.length === 0) return ""
  var preferred = ["default", "large", "small", "xlarge"]
  var chosen = ""
  for (var p = 0; p < preferred.length && !chosen; p++) {
    for (var i = 0; i < covers.length; i++) {
      var item = covers[i]
      if (item && item.size === preferred[p] && typeof item.url === "string") {
        chosen = item.url
        break
      }
    }
  }
  if (!chosen && covers[0] && typeof covers[0].url === "string")
    chosen = covers[0].url
  if (!chosen || chosen.length > MAX_URL_LEN) return ""
  return /^https:\/\/i\.scdn\.co\/image\/[A-Za-z0-9._-]+$/.test(chosen) ? chosen : ""
}

function parseTraceLine(line) {
  if (typeof line !== "string") return null
  var trimmed = line.trim()
  if (!trimmed || trimmed.length > MAX_JSON_BYTES) return null
  var brace = trimmed.indexOf("{")
  if (brace < 0) return null
  try {
    var parsed = JSON.parse(trimmed.slice(brace))
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return null
    return parsed
  } catch (e) {
    return null
  }
}

function extractPlayback(msg) {
  if (!msg || msg.type !== "playback_state") return null
  var status = String(msg.status || "stopped")
  if (status !== "playing" && status !== "paused" && status !== "stopped")
    status = "stopped"

  var item = msg.item && typeof msg.item === "object" ? msg.item : null
  var dec = item && item.decorations && typeof item.decorations === "object"
    ? item.decorations : {}
  var title = clampText(dec.identity ? dec.identity.name : "")

  var artistNames = []
  if (Array.isArray(dec.creators)) {
    for (var i = 0; i < dec.creators.length && artistNames.length < 6; i++) {
      var c = dec.creators[i]
      var name = c && c.entity && c.entity.decorations && c.entity.decorations.identity
        ? clampText(c.entity.decorations.identity.name, 80) : ""
      if (name) artistNames.push(name)
    }
  }
  var artist = clampText(artistNames.join(", "))
  var album = clampText(dec.parent && dec.parent.entity && dec.parent.entity.decorations
    && dec.parent.entity.decorations.identity
    ? dec.parent.entity.decorations.identity.name : "")
  var artUrl = safeCoverUrl(dec.visual_identity ? dec.visual_identity.cover : null)

  var durationMs = Math.max(0, Math.min(86400000,
    Math.floor(Number(dec.playback ? dec.playback.duration_ms : 0) || 0)))
  var pos = msg.position && typeof msg.position === "object" ? msg.position : {}
  var positionMs = Math.max(0, Math.min(durationMs || 86400000,
    Math.floor(Number(pos.position_ms) || 0)))
  var timestampMs = Math.floor(Number(pos.timestamp_ms) || Date.now())
  var speed = Number(pos.speed)
  if (!isFinite(speed) || speed < 0 || speed > 4) speed = status === "playing" ? 1 : 0

  var volume = Math.max(0, Math.min(100, Math.round(Number(msg.volume) || 0)))
  var options = msg.options && typeof msg.options === "object" ? msg.options : {}
  var shuffle = options.shuffle === true
  var repeat = String(options.repeat || "off")
  if (repeat !== "off" && repeat !== "context" && repeat !== "track") repeat = "off"

  return {
    status: status,
    playing: status === "playing",
    hasMedia: title !== "",
    title: title,
    artist: artist,
    album: album,
    artUrl: artUrl,
    durationMs: durationMs,
    positionMs: positionMs,
    timestampMs: timestampMs,
    speed: speed,
    volume: volume,
    shuffle: shuffle,
    repeat: repeat,
    isActive: msg.is_active === true
  }
}

function currentPositionMs(positionMs, timestampMs, speed, durationMs, playing, nowMs) {
  var base = Math.max(0, Number(positionMs) || 0)
  if (playing && speed > 0) {
    var elapsed = Math.max(0, (Number(nowMs) || Date.now()) - (Number(timestampMs) || 0))
    base += Math.round(elapsed * speed)
  }
  var cap = Math.max(0, Number(durationMs) || 0)
  return cap > 0 ? Math.min(cap, base) : base
}

function formatTime(ms) {
  var totalSeconds = Math.max(0, Math.floor((Number(ms) || 0) / 1000))
  var hours = Math.floor(totalSeconds / 3600)
  var minutes = Math.floor((totalSeconds % 3600) / 60)
  var seconds = totalSeconds % 60
  var secStr = seconds < 10 ? "0" + seconds : String(seconds)
  if (hours > 0) {
    var minStr = minutes < 10 ? "0" + minutes : String(minutes)
    return hours + ":" + minStr + ":" + secStr
  }
  return minutes + ":" + secStr
}

function barLabel(title, artist, showTitle, showArtist, playing, showPaused) {
  if (!title) return ""
  if (!playing && !showPaused) return ""
  if (showTitle && showArtist && artist) return title + " · " + artist
  if (showTitle) return title
  if (showArtist && artist) return artist
  return ""
}

function nextRepeatMode(current) {
  if (current === "off") return "context"
  if (current === "context") return "track"
  return "off"
}

function normalizedMaxWidth(value) {
  var n = Math.floor(Number(value))
  if (!isFinite(n) || n < 0) return 220
  if (n === 0) return 0
  return Math.max(120, Math.min(480, n))
}
