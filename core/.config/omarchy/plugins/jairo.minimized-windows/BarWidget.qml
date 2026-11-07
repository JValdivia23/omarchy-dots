import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "jairo.minimized-windows"

  property bool popupOpen: false
  property string restoreError: ""
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
    restoreError = ""
    popupOpen = !popupOpen
  }

  function restoreWindow(window) {
    if (restoreProc.running) return
    var address = String(window && window.address || "")
    if (address && address.indexOf("0x") !== 0) address = "0x" + address
    if (!/^0x[0-9a-fA-F]+$/.test(address)) return

    var monitor = Hyprland.focusedMonitor
    var workspaceId = monitor && monitor.activeWorkspace ? Number(monitor.activeWorkspace.id) : -1
    if (!(workspaceId >= 1) || Math.floor(workspaceId) !== workspaceId) return

    restoreError = ""
    restoreProc.command = ["bash", Quickshell.env("HOME") + "/.local/bin/hypr-restore-window", address, String(workspaceId)]
    restoreProc.running = true
  }

  visible: minimizedWindows.length > 0
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onMinimizedWindowsChanged: if (minimizedWindows.length === 0) close()

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  Process {
    id: restoreProc
    stderr: StdioCollector { id: restoreStderr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) root.close()
      else {
        var details = String(restoreStderr.text || "").trim().slice(0, 512)
        root.restoreError = details || strings.t("minimized.restoreUnavailable")
        console.warn("Minimized window restore failed:", root.restoreError)
      }
    }
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

      Text {
        id: errorText
        visible: root.restoreError !== ""
        textFormat: Text.PlainText
        text: strings.t("minimized.restoreFailed").arg(root.restoreError)
        color: Commons.Color.urgent
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        width: parent.width
        wrapMode: Text.Wrap
      }

      Flickable {
        id: listViewport
        width: parent.width
        height: Math.min(windowRows.implicitHeight, Math.max(Style.space(44), Style.space(380) - (errorText.visible ? errorText.implicitHeight + contentColumn.spacing : 0)))
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
                enabled: !restoreProc.running
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
