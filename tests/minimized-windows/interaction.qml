import QtQuick
import QtTest
import Quickshell

ShellRoot {
  QtObject {
    id: bar
    property color foreground: "#c0caf5"
    property color barForeground: foreground
    property color background: "#1a1b26"
    property color urgent: "#f7768e"
    property string fontFamily: "monospace"
    property string position: "top"
    property bool vertical: false
    property int barSize: 30
    property bool foregroundAnimationEnabled: false
    property var activePopout: null
    property var clickTargets: []
    function registerClickTarget(target) { clickTargets = [target] }
    function unregisterClickTarget(target) { clickTargets = [] }
    function showTooltip(target, text) {}
    function hideTooltip(target) {}
    function requestPopout(owner) { activePopout = owner }
    function releasePopout(owner) { if (activePopout === owner) activePopout = null }
  }

  FloatingWindow {
    id: view
    visible: true
    implicitWidth: 640
    implicitHeight: 480
    color: bar.background

    Loader {
      id: loader
      x: 320
      width: item ? item.implicitWidth : 32
      height: 30
      source: "Fixture.qml"
      onLoaded: item.bar = bar
    }

    TestCase {
      name: "MinimizedWindowInteraction"
      when: loader.status === Loader.Ready && view.visible

      function test_interaction() {
        try {
          exerciseInteraction()
        } catch (error) {
          // Quickshell is not qmltestrunner, so make assertion failures visible.
          console.error("FAIL:", error, error.stack)
          throw error
        }
      }

      function exerciseInteraction() {
        var widget = loader.item
        var button = bar.clickTargets[0]
        var popup = null
        var process = null
        for (var i = 0; i < widget.data.length; i++) {
          var object = widget.data[i]
          if ("anchorItem" in object && "triggerMode" in object) popup = object
          if ("command" in object && "running" in object) process = object
        }
        verify(popup !== null && process !== null)
        tryVerify(function() { return button.visible && button.width > 0 && button.height > 0 })
        wait(50)
        mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton)
        compare(widget.popupOpen, true)
        mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton)
        compare(widget.popupOpen, false)
        compare(process.command.length, 0)
        console.log("PASS: Second icon click only closes the list")
        mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton)

        var column = popup.contentItem[0]
        var rowColumn = column.children[2].contentItem.children[0]
        var rows = []
        for (var n = 0; n < rowColumn.children.length; n++) {
          if ("modelData" in rowColumn.children[n]) rows.push(rowColumn.children[n])
        }
        compare(rows.length, 2)
        var title = rows[0].children[2].children[0]
        compare(title.textFormat, Text.PlainText)
        compare(title.text, "<img src=https://example.invalid/test>")
        tryVerify(function() { return rows[0].width > 0 && rows[0].height > 0 })
        mouseClick(rows[0], rows[0].width / 2, rows[0].height / 2, Qt.LeftButton)
        compare(process.command[0], "bash")
        compare(process.command[2], "0x1234")
        compare(process.command[3], "3")
        tryCompare(process, "running", false)
        if (Quickshell.env("RESTORE_TEST_FAIL") === "1") {
          tryVerify(function() { return widget.restoreError.indexOf("Forced move failure") !== -1 })
          compare(widget.popupOpen, true)
          compare(column.children[1].visible, true)
          compare(column.children[1].textFormat, Text.PlainText)
          console.log("PASS: Failed restore displays a plain-text error and keeps the popup open")
        } else {
          tryCompare(widget, "popupOpen", false)
          compare(widget.restoreError, "")
          console.log("PASS: Row restores only its selected address and closes on success")
        }
        compare(widget.minimizedWindows.length, 2)
        console.log("PASS: Markup-shaped titles are plain text")
        widget.close()
      }

      function cleanupTestCase() { Qt.quit() }
    }
  }
}
