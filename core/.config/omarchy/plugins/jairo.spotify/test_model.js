#!/usr/bin/env node
const fs = require("fs")
const path = require("path")
const assert = require("assert")

const code = fs
  .readFileSync(path.join(__dirname, "SoloistModel.js"), "utf8")
  .replace(/^\s*\.pragma library\s*\n/, "")
const model = {}
new Function(
  "exports",
  code +
    "\nexports.parseTraceLine=parseTraceLine;exports.extractPlayback=extractPlayback;" +
    "exports.neutralizeMarkup=neutralizeMarkup;exports.safeCoverUrl=safeCoverUrl;" +
    "exports.currentPositionMs=currentPositionMs;exports.formatTime=formatTime;" +
    "exports.barLabel=barLabel;exports.nextRepeatMode=nextRepeatMode;" +
    "exports.normalizedMaxWidth=normalizedMaxWidth;"
)(model)

assert.strictEqual(
  model.neutralizeMarkup('<img src="https://example.invalid/t"> & <b>Song</b>'),
  '&lt;img src="https://example.invalid/t"&gt; &amp; &lt;b&gt;Song&lt;/b&gt;'
)

const sampleLine =
  '1795502737996 {"type":"playback_state","status":"playing","item":{"decorations":{"identity":{"name":"<b>Track</b>"},"visual_identity":{"cover":[{"url":"https://i.scdn.co/image/ab67616d00001e021c3ebd1438e5bc5a55120ee4","size":"default"}]},"parent":{"entity":{"decorations":{"identity":{"name":"Album"}}}},"creators":[{"entity":{"decorations":{"identity":{"name":"Artist"}}}}],"playback":{"duration_ms":165000}}},"position":{"position_ms":20000,"timestamp_ms":1000,"speed":1},"volume":55,"is_active":true,"options":{"shuffle":true,"repeat":"context"}}'

const parsed = model.parseTraceLine(sampleLine)
assert.ok(parsed && parsed.type === "playback_state")
const pb = model.extractPlayback(parsed)
assert.strictEqual(pb.playing, true)
assert.strictEqual(pb.title, "<b>Track</b>")
assert.strictEqual(model.neutralizeMarkup(pb.title), "&lt;b&gt;Track&lt;/b&gt;")
assert.strictEqual(pb.artist, "Artist")
assert.strictEqual(pb.album, "Album")
assert.strictEqual(pb.artUrl, "https://i.scdn.co/image/ab67616d00001e021c3ebd1438e5bc5a55120ee4")
assert.strictEqual(pb.volume, 55)
assert.strictEqual(pb.shuffle, true)
assert.strictEqual(pb.repeat, "context")

assert.strictEqual(
  model.safeCoverUrl([{ size: "default", url: "https://evil.example/tracker.png" }]),
  ""
)
assert.strictEqual(model.currentPositionMs(20000, 1000, 1, 165000, true, 6000), 25000)
assert.strictEqual(model.formatTime(165000), "2:45")
assert.strictEqual(model.nextRepeatMode("off"), "context")
assert.strictEqual(model.nextRepeatMode("context"), "track")
assert.strictEqual(model.nextRepeatMode("track"), "off")
assert.strictEqual(model.barLabel("Song", "Artist", true, false, false, false), "")
assert.strictEqual(model.barLabel("Song", "Artist", true, true, true, true), "Song · Artist")
assert.strictEqual(model.normalizedMaxWidth("0"), 0)
assert.strictEqual(model.normalizedMaxWidth("50"), 120)

console.log("SoloistModel tests passed.")
