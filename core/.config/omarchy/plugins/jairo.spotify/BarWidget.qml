import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

import "SoloistModel.js" as Model

BarWidget {
  id: root
  moduleName: "jairo.spotify"

  readonly property string homeDir: Quickshell.env("HOME") || ""
  readonly property string soloistBin: homeDir + "/.local/bin/soloist"
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color muted: Commons.Color.muted
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property bool showTrackTitle: String(root.setting("showTrackTitle", "On")) !== "Off"
  readonly property bool showArtistName: String(root.setting("showArtistName", "Off")) === "On"
  readonly property bool showPausedTrack: String(root.setting("showPausedTrack", "On")) !== "Off"
  readonly property int maxBarTextWidth: Model.normalizedMaxWidth(root.setting("maxBarTextWidth", "220"))

  property bool popupOpen: false
  readonly property bool opened: popupOpen

  property bool connected: false
  property string deviceName: "XPS Soloist"
  property bool loggedIn: false
  property bool deviceActive: false
  property bool playing: false
  property bool hasMedia: false
  property string trackTitle: ""
  property string trackArtist: ""
  property string trackAlbum: ""
  property string artUrl: ""
  property int durationMs: 0
  property int positionMs: 0
  property double positionTimestampMs: 0
  property real playbackSpeed: 0
  property int volumePercent: 40
  property int volumeBeforeMute: 40
  property bool shuffleEnabled: false
  property string repeatMode: "off"
  property double clockNow: Date.now()
  property bool serviceBusy: false

  readonly property int livePositionMs: Model.currentPositionMs(
    positionMs, positionTimestampMs, playbackSpeed, durationMs, playing, clockNow)

  readonly property string barText: connected
    ? Model.barLabel(trackTitle, trackArtist, showTrackTitle, showArtistName, playing, showPausedTrack)
    : ""
  readonly property bool iconOnly: vertical || !hasMedia || barText === ""

  readonly property string safeTooltip: {
    if (!connected) return strings.t("spotify.offline")
    if (!hasMedia) return strings.t("spotify.nothingPlaying")
    var label = trackTitle + (trackArtist ? " — " + trackArtist : "")
    return Model.neutralizeMarkup(label)
  }

  function close() {
    popupOpen = false
  }

  function togglePopup() {
    popupOpen = !popupOpen
    if (popupOpen) clockNow = Date.now()
  }

  function openFullPlayer() {
    close()
    Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "quickshell.spotify"])
  }

  function runCtl(args) {
    if (!soloistBin) return
    var cmd = [soloistBin, "ctl"]
    for (var i = 0; i < args.length; i++) cmd.push(String(args[i]))
    Quickshell.execDetached(cmd)
  }

  function togglePlayPause() {
    if (!connected) {
      startSoloist()
      return
    }
    runCtl([playing ? "pause" : "play"])
  }

  function nextTrack() {
    if (connected) runCtl(["next"])
  }

  function prevTrack() {
    if (connected) runCtl(["prev"])
  }

  function seekToMs(ms) {
    if (!connected) return
    var target = Math.max(0, Math.min(durationMs || 86400000, Math.round(Number(ms) || 0)))
    positionMs = target
    positionTimestampMs = Date.now()
    clockNow = positionTimestampMs
    runCtl(["seek", String(target)])
  }

  function setVolume(percent) {
    if (!connected) return
    var clamped = Math.max(0, Math.min(100, Math.round(Number(percent) || 0)))
    if (clamped > 0) volumeBeforeMute = clamped
    volumePercent = clamped
    runCtl(["volume", String(clamped)])
  }

  function toggleMute() {
    if (!connected) return
    if (volumePercent > 0) {
      volumeBeforeMute = volumePercent
      setVolume(0)
    } else {
      setVolume(volumeBeforeMute > 0 ? volumeBeforeMute : 40)
    }
  }

  function toggleShuffle() {
    if (!connected) return
    runCtl(["shuffle", shuffleEnabled ? "off" : "on"])
  }

  function cycleRepeat() {
    if (!connected) return
    runCtl(["repeat", Model.nextRepeatMode(repeatMode)])
  }

  function startSoloist() {
    if (serviceProc.running) return
    serviceBusy = true
    serviceProc.command = ["systemctl", "--user", "start", "spotify-soloist.service"]
    serviceProc.running = true
  }

  function stopSoloist() {
    if (serviceProc.running) return
    serviceBusy = true
    serviceProc.command = ["systemctl", "--user", "stop", "spotify-soloist.service"]
    serviceProc.running = true
  }

  function handleTraceLine(line) {
    var msg = Model.parseTraceLine(line)
    if (!msg) return
    connected = true
    if (msg.type === "auth_state") {
      loggedIn = msg.logged_in === true
      deviceActive = msg.is_active === true
      if (msg.device_name) deviceName = Model.clampText(msg.device_name, 64)
      return
    }
    var pb = Model.extractPlayback(msg)
    if (!pb) return
    playing = pb.playing
    hasMedia = pb.hasMedia
    trackTitle = pb.title
    trackArtist = pb.artist
    trackAlbum = pb.album
    artUrl = pb.artUrl
    durationMs = pb.durationMs
    positionMs = pb.positionMs
    positionTimestampMs = pb.timestampMs
    playbackSpeed = pb.speed
    volumePercent = pb.volume
    if (pb.volume > 0) volumeBeforeMute = pb.volume
    shuffleEnabled = pb.shuffle
    repeatMode = pb.repeat
    deviceActive = pb.isActive
    clockNow = Date.now()
  }

  function resetOffline() {
    connected = false
    playing = false
    deviceActive = false
    playbackSpeed = 0
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  Process {
    id: traceProc
    running: true
    command: [root.soloistBin, "ctl", "trace"]
    stdout: SplitParser {
      onRead: function(line) { root.handleTraceLine(line) }
    }
    onExited: {
      root.resetOffline()
      reconnectTimer.restart()
    }
  }

  Timer {
    id: reconnectTimer
    interval: 3000
    repeat: false
    onTriggered: {
      if (!traceProc.running) traceProc.running = true
    }
  }

  Process {
    id: serviceProc
    onExited: {
      root.serviceBusy = false
      if (!traceProc.running) reconnectTimer.restart()
    }
  }

  Timer {
    id: positionTick
    interval: 1000
    repeat: true
    running: root.popupOpen && root.connected && root.playing
    onTriggered: root.clockNow = Date.now()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.iconOnly ? "" : ""
    hasVisualContent: true
    slotSize: Style.bar.iconSlot
    opticalSize: Style.bar.iconCanvas
    fontSize: root.iconOnly ? Math.round(Style.bar.iconFont * 0.9) : Style.font.body
    active: root.playing || root.popupOpen
    foreground: root.bar ? root.bar.barForeground : root.foreground
    activeColor: foreground
    tooltipText: root.safeTooltip

    readonly property real fittedWidth: Math.ceil(barGlyph.width
      + barRow.spacing + barLabel.implicitWidth + scaledHorizontalMargin * 2)
    readonly property real cappedWidth: root.maxBarTextWidth > 0
      ? Math.min(fittedWidth, Style.space(root.maxBarTextWidth))
      : fittedWidth

    fixedWidth: root.vertical ? root.barSize
      : (root.iconOnly ? Style.bar.iconSlot : Math.max(Style.bar.iconSlot, cappedWidth))
    fixedHeight: root.vertical && root.iconOnly ? Style.bar.iconSlot : -1
    clip: true

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.togglePopup()
      else if (mouseButton === Qt.MiddleButton) root.togglePlayPause()
      else if (mouseButton === Qt.RightButton) root.openFullPlayer()
    }

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: function(event) {
        if (event.angleDelta.y > 0) root.prevTrack()
        else if (event.angleDelta.y < 0) root.nextTrack()
        event.accepted = true
      }
    }

    Row {
      id: barRow
      anchors.centerIn: parent
      spacing: Style.space(6)
      visible: !root.iconOnly
      enabled: false

      OpticalGlyph {
        id: barGlyph
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(16)
        height: Style.space(16)
        text: ""
        color: button.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.body
      }

      Text {
        id: barLabel
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        width: root.maxBarTextWidth > 0
          ? Math.min(implicitWidth, Math.max(Style.space(40),
              Style.space(root.maxBarTextWidth) - barGlyph.width - barRow.spacing - button.scaledHorizontalMargin * 2))
          : implicitWidth
        text: root.barText
        color: button.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
      }
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(330))
    contentHeight: popup.fittedContentHeight(cardColumn.implicitHeight, Style.space(360))

    Column {
      id: cardColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(12)

        Rectangle {
          id: artFrame
          width: Style.space(60)
          height: Style.space(60)
          radius: Math.max(4, Style.cornerRadius)
          color: Style.selectedFillFor(root.foreground, Commons.Color.accent)
          clip: true

          Image {
            id: coverImage
            anchors.fill: parent
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: Math.round(width * Screen.devicePixelRatio)
            sourceSize.height: Math.round(height * Screen.devicePixelRatio)
            source: root.popupOpen && root.artUrl ? root.artUrl : ""
          }

          Text {
            anchors.centerIn: parent
            visible: coverImage.status !== Image.Ready
            textFormat: Text.PlainText
            text: ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          width: parent.width - artFrame.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(3)

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: !root.connected
              ? strings.t("spotify.offline")
              : (root.hasMedia ? root.trackTitle : strings.t("spotify.nothingPlaying"))
            color: root.connected && root.hasMedia ? root.foreground : root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: text !== ""
            text: !root.connected
              ? strings.t("spotify.offlineHint")
              : root.trackArtist
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: root.connected && root.deviceName !== ""
            text: root.deviceName + (root.trackAlbum ? " · " + root.trackAlbum : "")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(2)
        visible: root.connected && root.hasMedia && root.durationMs > 0

        PanelSlider {
          id: seekSlider
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: Math.max(1, root.durationMs)
          step: 5000
          value: root.livePositionMs
          onReleased: function(val) { root.seekToMs(val) }
        }

        Item {
          width: parent.width
          height: elapsedLabel.implicitHeight

          Text {
            id: elapsedLabel
            textFormat: Text.PlainText
            anchors.left: parent.left
            text: Model.formatTime(seekSlider.dragging ? seekSlider.liveValue : root.livePositionMs)
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            text: Model.formatTime(root.durationMs)
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)
        visible: root.connected

        Button {
          iconText: "󰒟"
          foreground: root.foreground
          selected: root.shuffleEnabled
          tooltipText: strings.t("spotify.shuffle")
          onClicked: root.toggleShuffle()
        }

        Button {
          iconText: "󰒮"
          foreground: root.foreground
          tooltipText: strings.t("spotify.previous")
          onClicked: root.prevTrack()
        }

        Button {
          iconText: root.playing ? "󰏤" : "󰐊"
          foreground: root.foreground
          selected: root.playing
          bordered: true
          tooltipText: root.playing ? strings.t("spotify.pause") : strings.t("spotify.play")
          onClicked: root.togglePlayPause()
        }

        Button {
          iconText: "󰒭"
          foreground: root.foreground
          tooltipText: strings.t("spotify.next")
          onClicked: root.nextTrack()
        }

        Button {
          iconText: root.repeatMode === "track" ? "󰑘" : "󰑖"
          foreground: root.foreground
          selected: root.repeatMode !== "off"
          tooltipText: strings.t("spotify.repeat")
          onClicked: root.cycleRepeat()
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)
        visible: root.connected

        Button {
          id: muteBtn
          anchors.verticalCenter: parent.verticalCenter
          iconText: root.volumePercent === 0 ? "󰖁" : (root.volumePercent < 50 ? "󰖀" : "󰕾")
          foreground: root.foreground
          horizontalPadding: Style.space(6)
          verticalPadding: Style.space(4)
          tooltipText: strings.t("spotify.mute")
          onClicked: root.toggleMute()
        }

        PanelSlider {
          id: volSlider
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - muteBtn.width - volLabel.width - parent.spacing * 2
          bar: root.bar
          minimum: 0
          maximum: 100
          step: 5
          integer: true
          value: root.volumePercent
          onReleased: function(val) { root.setVolume(val) }
        }

        Text {
          id: volLabel
          textFormat: Text.PlainText
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(34)
          horizontalAlignment: Text.AlignRight
          text: strings.t("spotify.volumePercent").arg(
            Commons.I18n.formatNumber(Math.round(volSlider.dragging ? volSlider.liveValue : root.volumePercent)))
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      PanelSeparator {
        width: parent.width
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Button {
          width: (parent.width - parent.spacing) / 2
          text: strings.t("spotify.openFull")
          iconText: "󰓇"
          foreground: root.foreground
          bordered: true
          onClicked: root.openFullPlayer()
        }

        Button {
          width: (parent.width - parent.spacing) / 2
          text: root.connected ? strings.t("spotify.stopSoloist") : strings.t("spotify.startSoloist")
          iconText: root.connected ? "󰓛" : "󰐊"
          foreground: root.foreground
          bordered: true
          enabled: !root.serviceBusy
          onClicked: root.connected ? root.stopSoloist() : root.startSoloist()
        }
      }
    }
  }
}
