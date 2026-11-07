import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "jairo.minimized-windows"

  property bool popupOpen: false
  readonly property bool opened: popupOpen
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property string countLabel: strings.tn("minimized.count", minimizedWindows.length).arg(Commons.I18n.formatNumber(minimizedWindows.length))

  readonly property var minimizedWindows: {
    var result = []
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var client = toplevels[i]
      var wayland = client.wayland
      var workspace = client.workspace
      if (!wayland || !wayland.appId || wayland.parent || !workspace || workspace.name !== "special:minimized") continue

      var appId = String(wayland.appId)
      var entry = DesktopEntries.heuristicLookup(appId)
      result.push({
        address: String(client.address || ""),
        appId: appId,
        title: String(wayland.title || ""),
        appName: entry && entry.name ? String(entry.name) : appId,
        icon: entry && entry.icon ? String(entry.icon) : appId
      })
    }
    return result
  }

  function close() {
    popupOpen = false
  }

  function togglePopup() {
    popupOpen = !popupOpen
  }

  function restoreWindow(window) {
    var address = String(window && window.address || "")
    if (address && address.indexOf("0x") !== 0) address = "0x" + address
    if (!/^0x[0-9a-fA-F]+$/.test(address)) return

    var monitor = Hyprland.focusedMonitor
    var workspaceId = monitor && monitor.activeWorkspace ? Number(monitor.activeWorkspace.id) : -1
    if (!(workspaceId >= 1) || Math.floor(workspaceId) !== workspaceId) return

    var target = 'window = "address:' + address + '"'
    var steps = [
      'hl.dsp.window.set_prop({ prop = "no_anim", value = "1", ' + target + ' })',
      'hl.dsp.window.move({ workspace = "' + workspaceId + '", follow = false, ' + target + ' })',
      'hl.dsp.focus({ ' + target + ' })',
      'hl.dsp.window.alter_zorder({ mode = "top", ' + target + ' })'
    ]
    var command = steps.map(function(step) {
      return "hyprctl dispatch " + Util.shellQuote(step)
    }).join(" && ")
    command += "; sleep 0.4; hyprctl dispatch " + Util.shellQuote('hl.dsp.window.set_prop({ prop = "no_anim", value = "unset", ' + target + ' })')

    if (bar) bar.run(command)
    close()
  }

  visible: minimizedWindows.length > 0
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onMinimizedWindowsChanged: if (minimizedWindows.length === 0) close()

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰖰"
    active: root.popupOpen
    tooltipText: root.countLabel
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.togglePopup()
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight, Style.space(460))

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: root.countLabel
        color: root.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        width: parent.width
        elide: Text.ElideRight
      }

      Flickable {
        id: listViewport
        width: parent.width
        height: Math.min(windowRows.implicitHeight, Style.space(380))
        contentWidth: width
        contentHeight: windowRows.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: windowRows
          width: listViewport.width
          spacing: Style.space(2)

          Repeater {
            model: root.minimizedWindows

            delegate: Item {
              id: row
              required property var modelData
              width: windowRows.width
              height: Style.space(44)

              readonly property string primaryText: String(modelData.title || modelData.appName || modelData.appId || "")
              readonly property string secondaryText: String(modelData.appName || modelData.appId || "")

              Rectangle {
                anchors.fill: parent
                radius: Math.max(2, Style.cornerRadius)
                color: rowMouse.containsMouse ? Style.hoverFillFor(root.foreground, root.foreground) : "transparent"
              }

              Image {
                id: appIcon
                anchors.left: parent.left
                anchors.leftMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(24)
                height: Style.space(24)
                sourceSize.width: Math.round(width * Screen.devicePixelRatio)
                sourceSize.height: Math.round(height * Screen.devicePixelRatio)
                fillMode: Image.PreserveAspectFit
                source: Quickshell.iconPath(row.modelData.icon, true)
              }

              Column {
                anchors.left: appIcon.right
                anchors.leftMargin: Style.space(10)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(1)

                Text {
                  textFormat: Text.PlainText
                  width: parent.width
                  text: row.primaryText
                  color: root.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }

                Text {
                  visible: row.secondaryText !== "" && row.secondaryText !== row.primaryText
                  textFormat: Text.PlainText
                  width: parent.width
                  text: row.secondaryText
                  color: Qt.darker(root.foreground, 1.3)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.restoreWindow(row.modelData)
              }
            }
          }
        }
      }
    }
  }
}
