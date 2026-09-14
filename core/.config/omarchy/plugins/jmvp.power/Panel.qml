import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "jmvp.power"
  ipcTarget: "omarchy.power"
  // manageIpc: false so this panel can own the single IpcHandler the target
  // permits — needed for the togglePercentage method below.
  manageIpc: false
  property var batteryInfo: ({})
  property var systemInfo: ({})
  property var profiles: []
  property string activeProfile: ""
  property int profileIndex: 0
  property bool cursorActive: false
  readonly property bool showPercentage: setting("showPercentage", false) === true
  readonly property int sysBatteryCount: {
    var count = 0
    if (UPower.devices && UPower.devices.values) {
      for (var i = 0; i < UPower.devices.values.length; i++) {
        var d = UPower.devices.values[i]
        if (d && d.isPresent && (d.isLaptopBattery || d.type === UPowerDeviceType.Battery)) {
          count++
        }
      }
    }
    return count
  }
  readonly property int batteryCount: Math.max(sysBatteryCount, parseInt(root.batteryInfo.bat_count || "0", 10))
  readonly property bool multiBatteryAvailable: batteryCount > 1
  readonly property bool showDualBatteries: setting("showDualBatteries", true) === true && multiBatteryAvailable
  // With the percentage or dual batteries shown the button paints a wider block
  readonly property real openPanelIndicatorWidth: (showPercentage || showDualBatteries) && !button.vertical ? button.glyphPaintedWidth : 0
  readonly property bool batteryPresent: {
    var device = UPower.displayDevice
    return !!(device && device.isPresent)
  }

  function getSysBattery(idx) {
    var count = 0
    if (UPower.devices && UPower.devices.values) {
      for (var i = 0; i < UPower.devices.values.length; i++) {
        var d = UPower.devices.values[i]
        if (d && d.isPresent && (d.isLaptopBattery || d.type === UPowerDeviceType.Battery)) {
          if (count === idx) return d
          count++
        }
      }
    }
    return null
  }

  function bat1Pct() {
    if (root.batteryInfo && root.batteryInfo.bat1_pct) return root.batteryInfo.bat1_pct
    var d = getSysBattery(0)
    return d ? Math.round(d.percentage * 100) + "%" : ""
  }

  function bat2Pct() {
    if (root.batteryInfo && root.batteryInfo.bat2_pct) return root.batteryInfo.bat2_pct
    var d = getSysBattery(1)
    return d ? Math.round(d.percentage * 100) + "%" : ""
  }

  function batIcon(pctStr, stateStr, devIdx) {
    var d = getSysBattery(devIdx)
    var isChg = d ? (d.state === UPowerDeviceState.Charging) : false
    if (!d && stateStr) {
      var s = stateStr.toLowerCase()
      isChg = s.indexOf("charging") >= 0 && s.indexOf("dis") < 0 && s.indexOf("not") < 0
    }
    var pct = d ? d.percentage : (parseInt(pctStr || "0", 10) / 100)
    return Model.iconForPercentage(pct, isChg)
  }

  readonly property string buttonText: {
    if (showDualBatteries) {
      var icon1 = batIcon(root.batteryInfo.bat1_pct, root.batteryInfo.bat1_state, 0)
      var icon2 = batIcon(root.batteryInfo.bat2_pct, root.batteryInfo.bat2_state, 1)
      if (showPercentage && !button.vertical) {
        var p1 = bat1Pct() || "—"
        var p2 = bat2Pct() || "—"
        return p1 + " " + icon1 + "  " + p2 + " " + icon2
      } else {
        return icon1 + " " + icon2
      }
    } else {
      if (showPercentage && !button.vertical) {
        return Math.round(root.batteryFraction * 100) + "% " + root.batteryIcon()
      } else {
        return root.batteryIcon()
      }
    }
  }

  readonly property real buttonSlotSize: {
    if (button.vertical) return Style.bar.iconSlot
    if (showDualBatteries) {
      return Style.bar.iconSlot * (showPercentage ? 3.6 : 1.8)
    }
    return Style.bar.iconSlot * (showPercentage ? 2 : 1)
  }

  readonly property string buttonTooltipText: {
    if (showDualBatteries) {
      var b1 = (root.batteryInfo.bat1_name || "Battery 1") + ": " + (root.batteryInfo.bat1_pct || "—") + " (" + (root.batteryInfo.bat1_state || "—") + (root.batteryInfo.bat1_rate && root.batteryInfo.bat1_rate !== "0W" ? " · " + root.batteryInfo.bat1_rate : "") + ")"
      var b2 = (root.batteryInfo.bat2_name || "Battery 2") + ": " + (root.batteryInfo.bat2_pct || "—") + " (" + (root.batteryInfo.bat2_state || "—") + (root.batteryInfo.bat2_rate && root.batteryInfo.bat2_rate !== "0W" ? " · " + root.batteryInfo.bat2_rate : "") + ")"
      var tot = "Total: " + (root.batteryInfo.percentage || (Math.round(root.batteryFraction * 100) + "%")) + (root.batteryInfo.time ? " (" + root.batteryInfo.time + " left)" : "")
      return b1 + "\n" + b2 + "\n" + tot
    } else {
      return "Battery: " + (root.batteryInfo.percentage || "—") + (root.batteryInfo.time ? " (" + root.batteryInfo.time + " left)" : "")
    }
  }

  function upowerStates() {
    return {
      Charging: UPowerDeviceState.Charging,
      Discharging: UPowerDeviceState.Discharging,
      FullyCharged: UPowerDeviceState.FullyCharged,
      PendingCharge: UPowerDeviceState.PendingCharge
    }
  }

  function selectProfileByDelta(delta) {
    profileIndex = Model.selectProfileIndex(profileIndex, delta, profiles)
  }

  function activateSelectedProfile() {
    if (profileIndex < 0 || profileIndex >= profiles.length) return
    setProfile(profiles[profileIndex])
  }

  function batteryIcon() {
    var device = UPower.displayDevice
    if (device && device.percentage > 1.0) {
      return Model.iconForPercentage(root.batteryFraction, root.charging && !root.fullyCharged)
    }
    return Model.batteryIcon(device, root.discharging, upowerStates())
  }

  function modeLabel() {
    var device = UPower.displayDevice
    return Model.modeLabel(device, root.discharging, upowerStates())
  }

  function profileIcon(name) {
    return Model.profileIcon(name)
  }

  readonly property bool fullyCharged: {
    if (root.batteryInfo && root.batteryInfo.state) {
      var s = String(root.batteryInfo.state).toLowerCase()
      if (s === "full" || s === "charged" || (s === "holding" && root.batteryFraction >= 0.99)) return true
    }
    var device = UPower.displayDevice
    return device && device.isPresent && device.state === UPowerDeviceState.FullyCharged && !root.chargeThresholdActive
  }
  readonly property bool discharging: {
    if (root.batteryInfo && root.batteryInfo.state) {
      var s = String(root.batteryInfo.state).toLowerCase()
      if (s === "discharging") return true
    }
    var device = UPower.displayDevice
    return !!(device && device.isPresent && UPower.onBattery)
  }
  readonly property bool chargeThresholdActive: {
    var device = UPower.displayDevice
    return Model.chargeThresholdActive(device, root.discharging, upowerStates())
  }
  readonly property bool batteryFull: fullyCharged || (!root.discharging && batteryFraction >= 1)
  readonly property bool batteryFlowIdle: batteryFull || chargeThresholdActive

  // 0..1 charge level, used by the visual progress bar.
  readonly property real batteryFraction: {
    if (root.batteryInfo && root.batteryInfo.percentage) {
      var p = parseInt(root.batteryInfo.percentage, 10)
      if (!isNaN(p) && p >= 0) return Math.max(0, Math.min(1, p / 100))
    }
    var d = UPower.displayDevice
    if (d && d.isPresent && d.percentage >= 0 && d.percentage <= 1.0) {
      return d.percentage
    }
    return 0
  }

  readonly property bool charging: {
    if (root.batteryInfo && root.batteryInfo.state) {
      var s = String(root.batteryInfo.state).toLowerCase()
      if (s === "charging") return true
    }
    var d = UPower.displayDevice
    return d && d.isPresent && !UPower.onBattery && !root.batteryFlowIdle
  }

  readonly property color batteryFillColor: {
    return root.bar ? root.bar.foreground : Color.foreground
  }

  // Cute agent-flavored phrases shown in the hero status line, rotated on a
  // timer so the panel feels alive when current is flowing (either direction).
  readonly property var chargingPhrases: [
    "Pumping power",
    "Injecting electrons",
    "Pouring juice",
    "Amassing watts",
    "Hoarding joules",
    "Sucking volts",
    "Topping reserves",
    "Soaking amps",
    "Inhaling kilowatts"
  ]
  readonly property var onBatteryPhrases: [
    "Slurping power",
    "Spending joules",
    "Draining watts",
    "Burning electrons",
    "Sipping juice",
    "Spending coulombs",
    "Bleeding amps",
    "Guzzling volts",
    "Munching reserves"
  ]
  property int phraseIndex: 0

  // Whichever list is "active" given the current power state.
  readonly property var activePhrases: {
    if (fullyCharged) return []
    if (charging) return chargingPhrases
    if (discharging) return onBatteryPhrases
    return []
  }
  readonly property bool rotatingPhrases: activePhrases.length > 0

  readonly property string heroStatusText: {
    if (fullyCharged) return "Fully charged"
    if (rotatingPhrases) return activePhrases[phraseIndex % activePhrases.length]
    return modeLabel()
  }

  function refresh() {
    if (!batteryPresent) return

    if (!batteryProc.running) batteryProc.running = true
    if (!profilesProc.running) profilesProc.running = true
    if (!systemProc.running) systemProc.running = true
  }

  function updateKeyValue(raw, targetName) {
    var next = Model.parseKeyValue(raw)
    // Keep last known good data if a refresh briefly returns nothing — happens
    // around AC plug/unplug events. Avoids the section collapsing mid-transition.
    if (Object.keys(next).length === 0) return
    if (targetName === "battery") batteryInfo = next
    else systemInfo = next
  }

  function updateProfiles(raw) {
    var parsed = Model.parseProfiles(raw, profileIndex)
    // Same guard as battery: preserve the last known profile list across
    // transient empty payloads so the buttons don't blink out.
    if (parsed.profiles.length === 0) return
    profiles = parsed.profiles
    activeProfile = parsed.activeProfile
    profileIndex = parsed.profileIndex
    if (opened && !cursorActive) {
      var idx = profiles.indexOf(activeProfile)
      if (idx >= 0) profileIndex = idx
    }
  }

  function setProfile(profile) {
    if (!profile || actionProc.running) return
    actionProc.command = ["omarchy-powerprofiles-set", root.discharging ? "battery" : "ac", profile]
    actionProc.running = true
  }

  function togglePercentage() {
    root.settings = Object.assign({}, root.settings, { showPercentage: !root.showPercentage })
    if (root.bar && root.bar.shell) root.bar.shell.updateEntryInline(root.moduleName, root.settings)
  }

  function toggleDualBatteries() {
    root.settings = Object.assign({}, root.settings, { showDualBatteries: !root.showDualBatteries })
    if (root.bar && root.bar.shell) root.bar.shell.updateEntryInline(root.moduleName, root.settings)
  }

  IpcHandler {
    target: "omarchy.power"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function togglePercentage() { root.togglePercentage() }
    function toggleDualBatteries() { root.toggleDualBatteries() }
  }

  onOpenedChanged: {
    if (opened) {
      if (!batteryPresent) {
        close()
        return
      }

      refresh()
      var idx = profiles.indexOf(activeProfile)
      profileIndex = idx >= 0 ? idx : 0
      cursorActive = false
    }
  }

  onBatteryPresentChanged: {
    if (!batteryPresent) close()
    else refresh()
  }

  visible: batteryPresent
  implicitWidth: batteryPresent ? button.implicitWidth : 0
  implicitHeight: batteryPresent ? button.implicitHeight : 0

  Process {
    id: batteryProc
    command: [Quickshell.env("HOME") + "/.config/omarchy/plugins/jmvp.power/battery-status.sh", "--shell"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateKeyValue(text, "battery") }
  }

  Process {
    id: profilesProc
    command: ["omarchy-powerprofiles-list", "--active-state"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateProfiles(text) }
  }

  Process {
    id: systemProc
    command: ["omarchy-system-stats"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateKeyValue(text, "system") }
  }

  Process {
    id: actionProc
    onExited: root.refresh()
  }

  Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

  Connections {
    target: UPower
    function onOnBatteryChanged() { root.refresh() }
  }

  Component.onCompleted: root.refresh()

  // Rotate the status phrase while the panel is open and we're in a
  // rotating state (charging or on battery). The text swap is wrapped in a
  // fade so the changeover reads as one organism rather than a hard cut.
  Timer {
    id: phraseTimer
    interval: 2800
    running: root.opened && root.rotatingPhrases
    repeat: true
    triggeredOnStart: false
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    PropertyAnimation {
      target: heroStatus; property: "opacity"
      to: 0.0; duration: 180; easing.type: Easing.OutQuad
    }
    ScriptAction {
      script: {
        var n = root.activePhrases.length
        if (n > 0) root.phraseIndex = (root.phraseIndex + 1) % n
      }
    }
    PropertyAnimation {
      target: heroStatus; property: "opacity"
      to: 1.0; duration: 260; easing.type: Easing.InQuad
    }
  }

  // If we leave a rotating state mid-swap, halt the animation and snap back
  // to full opacity so "FULLY CHARGED" is legible immediately rather than
  // appearing dimmed.
  Connections {
    target: root
    function onRotatingPhrasesChanged() {
      if (!root.rotatingPhrases) {
        phraseSwap.stop()
        heroStatus.opacity = 1.0
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.buttonText
    slotSize: root.buttonSlotSize
    tooltipText: root.buttonTooltipText
    onPressed: function(b) {
      if (!root.batteryPresent) return
      if (b === Qt.RightButton) root.togglePercentage()
      else if (b === Qt.MiddleButton) root.toggleDualBatteries()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && root.batteryPresent
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dx !== 0) root.selectProfileByDelta(dx)
        else if (dy !== 0) root.selectProfileByDelta(dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateSelectedProfile()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // ---------- Hero: battery icon · title/status · percentage ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroPercent.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: root.batteryIcon()
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 200 } }
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: heroPercent.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Battery"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              id: heroStatus
              textFormat: Text.PlainText
              text: root.heroStatusText.toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroPercent
            textFormat: Text.PlainText
            text: root.batteryInfo.percentage || "—"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 200 } }
          }
        }

        // ---------- Battery progress bar ----------
        Item {
          width: parent.width
          implicitHeight: Style.space(8)

          Rectangle {
            id: barTrack
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
          }

          Rectangle {
            id: barFill
            anchors.left: barTrack.left
            anchors.verticalCenter: barTrack.verticalCenter
            height: barTrack.height
            radius: barTrack.radius
            color: root.batteryFillColor
            width: Math.max(barTrack.height, barTrack.width * root.batteryFraction)

            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 220 } }

            // Subtle pulse while charging — visible signal that energy is flowing in.
            SequentialAnimation on opacity {
              running: root.charging && !root.fullyCharged && root.opened
              loops: Animation.Infinite
              alwaysRunToEnd: true
              NumberAnimation { from: 1.0; to: 0.55; duration: 950; easing.type: Easing.InOutSine }
              NumberAnimation { from: 0.55; to: 1.0; duration: 950; easing.type: Easing.InOutSine }
            }
          }
        }

        // ---------- Stats ----------
        // Visibility is intentionally only gated by "we've ever loaded data" so
        // the section never collapses mid-transition. fullyCharged is *not* part
        // of the condition: UPower briefly reports FullyCharged on plug-in when
        // the battery sits above the charge-control start threshold, and we
        // refuse to flicker the whole panel for that ~1s window.
        Row {
          visible: root.batteryInfo.percentage !== undefined
          width: parent.width
          spacing: Style.space(20)

          Column {
            width: (parent.width - parent.spacing) / 2
            spacing: Style.spacing.labelGap
            InfoPair { label: "Battery size"; value: root.batteryInfo.size || "" }
            InfoPair { label: "Charge cycles"; value: root.batteryInfo.cycles || "—" }
          }

          Column {
            width: (parent.width - parent.spacing) / 2
            spacing: Style.spacing.labelGap
            InfoPair {
              label: root.chargeThresholdActive ? "Charge limit" : (root.discharging ? "Time left" : "Time to full")
              value: root.chargeThresholdActive ? (root.batteryInfo.threshold || "-") : (root.batteryFlowIdle ? "-" : (root.batteryInfo.time || "—"))
            }
            InfoPair {
              label: root.chargeThresholdActive ? "Battery state" : (root.discharging ? "Discharging" : "Charging")
              value: root.chargeThresholdActive ? "Holding" : (root.batteryFull ? "-" : (root.batteryInfo.rate || ""))
            }
          }
        }

        // ---------- Individual Batteries breakdown ----------
        PanelSeparator {
          visible: root.multiBatteryAvailable
          foreground: root.bar.foreground
        }

        Column {
          visible: root.multiBatteryAvailable
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "BATTERIES"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          BatteryCard {
            name: root.batteryInfo.bat1_name || "Battery 1"
            idText: root.batteryInfo.bat1_id || "BAT1"
            pctText: root.batteryInfo.bat1_pct || "—"
            pctFrac: (parseInt(root.batteryInfo.bat1_raw_pct || "0", 10) || 0) / 100
            stateText: root.batteryInfo.bat1_state || "—"
            energyText: root.batteryInfo.bat1_energy || ""
            rateText: root.batteryInfo.bat1_rate || ""
            cyclesText: root.batteryInfo.bat1_cycles ? (root.batteryInfo.bat1_cycles + " cycles") : ""
            iconGlyph: root.batIcon(root.batteryInfo.bat1_pct, root.batteryInfo.bat1_state)
          }

          BatteryCard {
            name: root.batteryInfo.bat2_name || "Battery 2"
            idText: root.batteryInfo.bat2_id || "BAT2"
            pctText: root.batteryInfo.bat2_pct || "—"
            pctFrac: (parseInt(root.batteryInfo.bat2_raw_pct || "0", 10) || 0) / 100
            stateText: root.batteryInfo.bat2_state || "—"
            energyText: root.batteryInfo.bat2_energy || ""
            rateText: root.batteryInfo.bat2_rate || ""
            cyclesText: root.batteryInfo.bat2_cycles ? (root.batteryInfo.bat2_cycles + " cycles") : ""
            iconGlyph: root.batIcon(root.batteryInfo.bat2_pct, root.batteryInfo.bat2_state)
          }
        }

        // ---------- Power profile picker ----------
        PanelSeparator {
          foreground: root.bar.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "POWER PROFILE"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: profileRow
            width: parent.width
            spacing: Style.space(6)

            readonly property real cellWidth: root.profiles.length > 0
              ? (width - spacing * (root.profiles.length - 1)) / root.profiles.length
              : 0

            Repeater {
              model: root.profiles
              Button {
                required property var modelData
                required property int index
                width: profileRow.cellWidth
                iconText: root.profileIcon(String(modelData))
                iconSize: Style.font.title
                text: String(modelData).charAt(0).toUpperCase() + String(modelData).slice(1)
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: root.activeProfile === modelData
                hasCursor: root.cursorActive && root.profileIndex === index
                onClicked: root.setProfile(modelData)
                onHovered: function(h) {
                  if (h) {
                    root.cursorActive = true
                    root.profileIndex = index
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""

    width: parent.width
    spacing: Style.space(8)

    InfoLabel { text: label }
    Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
    InfoValue { text: value }
  }

  component InfoLabel: Text {
    textFormat: Text.PlainText
    color: root.bar.foreground
    opacity: 0.6
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  component InfoValue: Text {
    textFormat: Text.PlainText
    color: root.bar.foreground
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  component BatteryCard: Column {
    id: card
    property string name: ""
    property string idText: ""
    property string pctText: ""
    property real pctFrac: 0
    property string stateText: ""
    property string energyText: ""
    property string rateText: ""
    property string cyclesText: ""
    property string iconGlyph: ""

    width: parent.width
    spacing: Style.space(5)

    Row {
      width: parent.width
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: card.iconGlyph
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        color: root.bar.foreground
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        text: card.name + (card.idText ? " (" + card.idText + ")" : "")
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        color: root.bar.foreground
        anchors.verticalCenter: parent.verticalCenter
      }

      Item {
        width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[1].implicitWidth - parent.children[3].implicitWidth - parent.spacing * 3)
        height: 1
      }

      Text {
        textFormat: Text.PlainText
        text: card.pctText + "  ·  " + card.stateText
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        color: Qt.darker(root.bar.foreground, 1.25)
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Item {
      width: parent.width
      implicitHeight: Style.space(4)

      Rectangle {
        id: batTrack
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
      }

      Rectangle {
        anchors.left: batTrack.left
        anchors.verticalCenter: batTrack.verticalCenter
        height: batTrack.height
        radius: batTrack.radius
        color: root.batteryFillColor
        width: Math.max(batTrack.height, batTrack.width * Math.min(1, Math.max(0, card.pctFrac)))
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: card.energyText
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        color: Qt.darker(root.bar.foreground, 1.4)
      }

      Item {
        width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2)
        height: 1
      }

      Text {
        textFormat: Text.PlainText
        text: (card.rateText && card.rateText !== "0W" ? card.rateText + "  ·  " : "") + card.cyclesText
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        color: Qt.darker(root.bar.foreground, 1.4)
      }
    }
  }
}
