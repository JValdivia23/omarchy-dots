import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1280
    color: "#090d16"

    // Responsive scale factor tuned for 1920x1280 (scale=1 in SDDM Hyprland)
    readonly property real ui: Math.max(0.85, Math.min(root.width / 1280.0, root.height / 800.0))
    readonly property string sansFont: (config.Font && config.Font.length > 0) ? config.Font : "Adwaita Sans"
    readonly property string monoFont: (config.MonoFont && config.MonoFont.length > 0) ? config.MonoFont : "JetBrainsMono Nerd Font"

    // Palette
    readonly property color accentPrimary: "#86cc57"   // Omarchy green
    readonly property color accentMobile: "#8b5cf6"    // Denial violet
    readonly property color accentError: "#f87171"
    readonly property color textPrimary: "#f1f5f9"
    readonly property color textSecondary: "#94a3b8"
    readonly property color textMuted: "#64748b"

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string currentUser: userModel.lastUser || (userModel.rowCount() > 0 ? (userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 1) || "user") : "user")
    property int sessionIndex: resolveInitialSessionIndex()
    property bool loginFailed: false
    property string statusMessage: ""
    property bool loggingIn: false
    property bool showPassword: false
    property bool oskVisible: false
    property bool oskShift: false
    property bool oskSymbols: false
    property bool showOtherSessions: false
    property var nowDate: new Date()

    function sessionNameAt(idx) {
        if (idx < 0 || idx >= sessionModel.rowCount()) return ""
        // SDDM Qt6 SessionModel: NameRole = Qt.UserRole + 4
        var name = sessionModel.data(sessionModel.index(idx, 0), Qt.UserRole + 4)
        if (!name) name = sessionModel.data(sessionModel.index(idx, 0), Qt.DisplayRole)
        return (name || "").toString()
    }

    function sessionFileAt(idx) {
        if (idx < 0 || idx >= sessionModel.rowCount()) return ""
        // SDDM Qt6 SessionModel: FileRole = Qt.UserRole + 2
        return (sessionModel.data(sessionModel.index(idx, 0), Qt.UserRole + 2) || "").toString()
    }

    function sessionKind(idx) {
        var name = sessionNameAt(idx).toLowerCase()
        var file = sessionFileAt(idx).toLowerCase()
        if (name.indexOf("denial mobile") !== -1 || file.indexOf("denial-mobile") !== -1)
            return "denial-mobile"
        if (name.indexOf("omarchy") !== -1 || file.indexOf("omarchy") !== -1)
            return "omarchy"
        if (name.indexOf("denial") !== -1 || file.indexOf("denial") !== -1)
            return "denial-desktop"
        if (name.indexOf("hyprland") !== -1 || file.indexOf("hyprland") !== -1)
            return "hyprland"
        return "other"
    }

    function isPrimarySession(idx) {
        var k = sessionKind(idx)
        return k === "omarchy" || k === "denial-mobile"
    }

    function primarySessionIndices() {
        var list = []
        var omarchyIdx = -1
        var denialMobileIdx = -1
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            var k = sessionKind(i)
            if (k === "omarchy" && omarchyIdx === -1) omarchyIdx = i
            else if (k === "denial-mobile" && denialMobileIdx === -1) denialMobileIdx = i
        }
        if (omarchyIdx !== -1) list.push(omarchyIdx)
        if (denialMobileIdx !== -1) list.push(denialMobileIdx)
        // Fallback if neither primary exists (e.g. test mode with mock sessions)
        if (list.length === 0) {
            for (var j = 0; j < Math.min(2, sessionModel.rowCount()); j++) {
                list.push(j)
            }
        }
        return list
    }

    function secondarySessionIndices() {
        var primaries = primarySessionIndices()
        var list = []
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            if (primaries.indexOf(i) === -1) list.push(i)
        }
        return list
    }

    function resolveInitialSessionIndex() {
        if (sessionModel.lastIndex >= 0 && sessionModel.lastIndex < sessionModel.rowCount()) {
            return sessionModel.lastIndex
        }
        var primaries = primarySessionIndices()
        return primaries.length > 0 ? primaries[0] : 0
    }

    function cycleSession(delta) {
        var count = sessionModel.rowCount()
        if (count <= 1) return
        var primaries = primarySessionIndices()
        if (!showOtherSessions && primaries.length > 1) {
            var pos = primaries.indexOf(sessionIndex)
            if (pos !== -1) {
                sessionIndex = primaries[(pos + delta + primaries.length) % primaries.length]
                return
            }
        }
        sessionIndex = (sessionIndex + delta + count) % count
    }

    function sessionTitle(idx) {
        var k = sessionKind(idx)
        if (k === "omarchy") return "Omarchy"
        if (k === "denial-mobile") return "Denial Mobile"
        if (k === "denial-desktop") return "Denial Desktop"
        return sessionNameAt(idx)
    }

    function sessionSubtitle(idx) {
        var k = sessionKind(idx)
        if (k === "omarchy") return "Hyprland · Desktop"
        if (k === "denial-mobile") return "Touch & Tablet Shell"
        if (k === "denial-desktop") return "Flutter · Desktop"
        if (k === "hyprland") return "Wayland Compositor"
        return "Wayland Session"
    }

    function sessionAccent(idx) {
        var k = sessionKind(idx)
        if (k === "denial-mobile" || k === "denial-desktop") return accentMobile
        return accentPrimary
    }

    function submitLogin() {
        if (loggingIn) return
        loggingIn = true
        loginFailed = false
        statusMessage = ""
        sddm.login(currentUser, passwordInput.text, sessionIndex)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.nowDate = new Date()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loggingIn = false
            root.loginFailed = true
            root.statusMessage = "Incorrect password — try again"
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            shakeAnim.restart()
        }
        function onLoginSucceeded() {
            root.loggingIn = false
            root.loginFailed = false
            root.statusMessage = ""
        }
    }

    // --- Atmospheric Backdrop ---
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b1120" }
            GradientStop { position: 0.52; color: "#0f172a" }
            GradientStop { position: 1.0; color: "#070b14" }
        }
    }

    // Soft ambient top-left glow (shifts hue smoothly with active session)
    Rectangle {
        id: glowTopLeft
        width: root.width * 0.62
        height: width
        radius: width / 2
        x: -width * 0.22
        y: -height * 0.30
        color: sessionAccent(root.sessionIndex)
        opacity: 0.13
        Behavior on color { ColorAnimation { duration: 420; easing.type: Easing.OutCubic } }
    }

    // Soft ambient bottom-right glow
    Rectangle {
        width: root.width * 0.55
        height: width
        radius: width / 2
        x: root.width - width * 0.72
        y: root.height - height * 0.62
        color: sessionKind(root.sessionIndex) === "denial-mobile" ? "#38bdf8" : "#818cf8"
        opacity: 0.09
        Behavior on color { ColorAnimation { duration: 420; easing.type: Easing.OutCubic } }
    }

    // Subtle top status pill (hostname + keyboard hint)
    Row {
        anchors.top: parent.top
        anchors.topMargin: Math.round(28 * root.ui)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.round(10 * root.ui)

        Rectangle {
            height: Math.round(30 * root.ui)
            width: hostLabel.implicitWidth + Math.round(28 * root.ui)
            radius: height / 2
            color: "#14ffffff"
            border.width: 1
            border.color: "#1effffff"

            Row {
                anchors.centerIn: parent
                spacing: Math.round(8 * root.ui)

                Rectangle {
                    width: Math.round(7 * root.ui)
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: sessionAccent(root.sessionIndex)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    id: hostLabel
                    text: sddm.hostName || "surface-go3"
                    color: root.textSecondary
                    font.family: root.monoFont
                    font.pixelSize: Math.round(12 * root.ui)
                    font.letterSpacing: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // --- Main Centered Stack (shifts up smoothly when touch keyboard opens) ---
    Item {
        id: mainStage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: oskDrawer.top

        Column {
            id: centerCol
            anchors.centerIn: parent
            spacing: Math.round((root.oskVisible ? 16 : 28) * root.ui)
            Behavior on spacing { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // Clock & Date
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(4 * root.ui)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.nowDate, "HH:mm")
                    color: root.textPrimary
                    font.family: root.sansFont
                    font.pixelSize: Math.round((root.oskVisible ? 48 : 74) * root.ui)
                    font.weight: Font.Light
                    font.letterSpacing: -1.5
                    Behavior on font.pixelSize { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.nowDate, "dddd, MMMM d")
                    color: root.textSecondary
                    font.family: root.sansFont
                    font.pixelSize: Math.round((root.oskVisible ? 14 : 17) * root.ui)
                    font.weight: Font.Normal
                }
            }

            // Frosted Glass Main Card
            Rectangle {
                id: glassCard
                width: Math.min(root.width - Math.round(48 * root.ui), Math.round(590 * root.ui))
                height: cardCol.implicitHeight + Math.round(48 * root.ui)
                radius: Math.round(24 * root.ui)
                color: "#13ffffff"
                border.width: 1
                border.color: root.loginFailed ? "#99f87171" : "#22ffffff"
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on border.color { ColorAnimation { duration: 200 } }

                transform: Translate { id: cardShake; x: 0 }

                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: cardShake; property: "x"; to: -10; duration: 45 }
                    NumberAnimation { target: cardShake; property: "x"; to: 10; duration: 45 }
                    NumberAnimation { target: cardShake; property: "x"; to: -7; duration: 45 }
                    NumberAnimation { target: cardShake; property: "x"; to: 7; duration: 45 }
                    NumberAnimation { target: cardShake; property: "x"; to: 0; duration: 45 }
                }

                Column {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Math.round(24 * root.ui)
                    spacing: Math.round(18 * root.ui)

                    // Section header
                    Text {
                        text: "CHOOSE ENVIRONMENT"
                        color: root.textMuted
                        font.family: root.monoFont
                        font.pixelSize: Math.round(11 * root.ui)
                        font.letterSpacing: 1.4
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Primary Session Cards (Omarchy + Denial Mobile)
                    Row {
                        id: primaryRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(14 * root.ui)

                        property var indices: root.primarySessionIndices()
                        readonly property real cardWidth: (cardCol.width - spacing * Math.max(0, indices.length - 1)) / Math.max(1, indices.length)

                        Repeater {
                            model: primaryRow.indices

                            delegate: Rectangle {
                                readonly property int sIdx: modelData
                                readonly property bool selected: root.sessionIndex === sIdx
                                readonly property string kind: root.sessionKind(sIdx)
                                readonly property color cardAccent: root.sessionAccent(sIdx)

                                width: primaryRow.cardWidth
                                height: Math.round((root.oskVisible ? 88 : 112) * root.ui)
                                radius: Math.round(18 * root.ui)
                                color: selected ? "#22ffffff" : (cardMouse.containsMouse ? "#18ffffff" : "#0cffffff")
                                border.width: selected ? 2 : 1
                                border.color: selected ? cardAccent : "#1cffffff"

                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on border.color { ColorAnimation { duration: 180 } }
                                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                // Top-right active badge dot
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: Math.round(12 * root.ui)
                                    width: Math.round(10 * root.ui)
                                    height: width
                                    radius: width / 2
                                    color: cardAccent
                                    opacity: selected ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 160 } }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: Math.round(16 * root.ui)
                                    spacing: Math.round(14 * root.ui)

                                    // Official Omarchy Logo / Denial "Dl" Monogram Badge
                                    Rectangle {
                                        width: Math.round(52 * root.ui)
                                        height: width
                                        radius: Math.round(14 * root.ui)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: (kind === "denial-mobile" || kind === "denial-desktop") ? "#1b1824" : "#151c24"
                                        border.width: selected ? 1.5 : 1
                                        border.color: selected ? Qt.rgba(cardAccent.r, cardAccent.g, cardAccent.b, 0.75) : "#24ffffff"
                                        clip: true

                                        // Omarchy emblem
                                        Image {
                                            visible: kind !== "denial-mobile" && kind !== "denial-desktop"
                                            anchors.fill: parent
                                            anchors.margins: Math.round(9 * root.ui)
                                            source: "omarchy-logo.png"
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            mipmap: true
                                        }

                                        // Denial "Dl" monogram: crisp white "D" + vertical white-to-purple gradient "l"
                                        Row {
                                            visible: kind === "denial-mobile" || kind === "denial-desktop"
                                            anchors.centerIn: parent
                                            spacing: Math.round(2.5 * root.ui)

                                            Text {
                                                text: "D"
                                                color: "#f0eef5"
                                                font.family: root.sansFont
                                                font.pixelSize: Math.round(27 * root.ui)
                                                font.weight: Font.Medium
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: Math.max(3, Math.round(4.5 * root.ui))
                                                height: Math.round(22 * root.ui)
                                                radius: Math.max(1, Math.round(1.2 * root.ui))
                                                anchors.verticalCenter: parent.verticalCenter
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: "#ffffff" }
                                                    GradientStop { position: 0.35; color: "#d3c1f5" }
                                                    GradientStop { position: 0.72; color: "#9c79db" }
                                                    GradientStop { position: 1.0; color: "#7150b8" }
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Math.round(3 * root.ui)
                                        width: parent.width - Math.round(66 * root.ui)

                                        Text {
                                            text: root.sessionTitle(sIdx)
                                            color: selected ? root.textPrimary : "#cbd5e1"
                                            font.family: root.sansFont
                                            font.pixelSize: Math.round(16 * root.ui)
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: root.sessionSubtitle(sIdx)
                                            color: selected ? root.textSecondary : root.textMuted
                                            font.family: root.sansFont
                                            font.pixelSize: Math.round(12 * root.ui)
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.sessionIndex = sIdx
                                        passwordInput.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }

                    // Secondary Sessions (compact expandable pill row, e.g. Denial Desktop / Hyprland)
                    Column {
                        id: secondaryCol
                        width: parent.width
                        spacing: Math.round(8 * root.ui)
                        property var extraIndices: root.secondarySessionIndices()
                        visible: extraIndices.length > 0

                        Item {
                            width: parent.width
                            height: Math.round(24 * root.ui)

                            Rectangle {
                                anchors.centerIn: parent
                                height: Math.round(24 * root.ui)
                                width: otherLbl.implicitWidth + Math.round(22 * root.ui)
                                radius: height / 2
                                color: otherBtnMouse.containsMouse ? "#1affffff" : "transparent"

                                Text {
                                    id: otherLbl
                                    anchors.centerIn: parent
                                    text: {
                                        var extraSelected = secondaryCol.extraIndices.indexOf(root.sessionIndex) !== -1
                                        if (extraSelected) return "Selected: " + root.sessionTitle(root.sessionIndex) + (root.showOtherSessions ? "  ▴" : "  ▾")
                                        return (root.showOtherSessions ? "Hide other sessions  ▴" : "Other sessions  ▾")
                                    }
                                    color: secondaryCol.extraIndices.indexOf(root.sessionIndex) !== -1 ? root.accentPrimary : root.textMuted
                                    font.family: root.sansFont
                                    font.pixelSize: Math.round(12 * root.ui)
                                }

                                MouseArea {
                                    id: otherBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showOtherSessions = !root.showOtherSessions
                                }
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: Math.round(8 * root.ui)
                            visible: root.showOtherSessions
                            layoutDirection: Qt.LeftToRight

                            Repeater {
                                model: secondaryCol.extraIndices

                                delegate: Rectangle {
                                    readonly property int sIdx: modelData
                                    readonly property bool selected: root.sessionIndex === sIdx
                                    height: Math.round(34 * root.ui)
                                    width: extraText.implicitWidth + Math.round(24 * root.ui)
                                    radius: height / 2
                                    color: selected ? "#2860a5fa" : (extraMouse.containsMouse ? "#18ffffff" : "#0effffff")
                                    border.width: 1
                                    border.color: selected ? root.accentPrimary : "#1effffff"

                                    Text {
                                        id: extraText
                                        anchors.centerIn: parent
                                        text: root.sessionTitle(sIdx)
                                        color: selected ? root.textPrimary : root.textSecondary
                                        font.family: root.sansFont
                                        font.pixelSize: Math.round(12.5 * root.ui)
                                    }

                                    MouseArea {
                                        id: extraMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.sessionIndex = sIdx
                                            passwordInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#18ffffff"
                    }

                    // User row
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(10 * root.ui)

                        Rectangle {
                            width: Math.round(30 * root.ui)
                            height: width
                            radius: width / 2
                            color: Qt.rgba(sessionAccent(root.sessionIndex).r, sessionAccent(root.sessionIndex).g, sessionAccent(root.sessionIndex).b, 0.25)
                            border.width: 1
                            border.color: Qt.rgba(sessionAccent(root.sessionIndex).r, sessionAccent(root.sessionIndex).g, sessionAccent(root.sessionIndex).b, 0.55)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.currentUser.length > 0 ? root.currentUser.charAt(0).toUpperCase() : "U"
                                color: root.textPrimary
                                font.family: root.sansFont
                                font.pixelSize: Math.round(13 * root.ui)
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: root.currentUser
                            color: root.textPrimary
                            font.family: root.sansFont
                            font.pixelSize: Math.round(15 * root.ui)
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Password Pill Input + Touch Keyboard Toggle + Submit Button
                    Rectangle {
                        id: passwordPill
                        width: parent.width
                        height: Math.round(52 * root.ui)
                        radius: Math.round(15 * root.ui)
                        color: "#18000000"
                        border.width: passwordInput.activeFocus ? 1.5 : 1
                        border.color: root.loginFailed ? root.accentError : (passwordInput.activeFocus ? sessionAccent(root.sessionIndex) : "#26ffffff")

                        Behavior on border.color { ColorAnimation { duration: 160 } }

                        // Placeholder text
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(18 * root.ui)
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Password"
                            color: root.textMuted
                            font.family: root.sansFont
                            font.pixelSize: Math.round(15 * root.ui)
                            visible: passwordInput.text.length === 0
                        }

                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(18 * root.ui)
                            anchors.right: controlsRow.left
                            anchors.rightMargin: Math.round(8 * root.ui)
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "\u2022"
                            color: root.textPrimary
                            selectionColor: "#4460a5fa"
                            selectedTextColor: root.textPrimary
                            font.family: root.showPassword ? root.sansFont : root.monoFont
                            font.pixelSize: Math.round((root.showPassword ? 15 : 18) * root.ui)
                            font.letterSpacing: root.showPassword ? 0 : 2
                            clip: true
                            focus: true

                            onTextChanged: {
                                if (root.loginFailed && text.length > 0) {
                                    root.loginFailed = false
                                    root.statusMessage = ""
                                }
                            }

                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.submitLogin()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
                                    root.cycleSession(1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {
                                    root.cycleSession(-1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Right && (event.modifiers & Qt.AltModifier)) {
                                    root.cycleSession(1)
                                    event.accepted = true
                                }
                            }
                        }

                        Row {
                            id: controlsRow
                            anchors.right: parent.right
                            anchors.rightMargin: Math.round(6 * root.ui)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Math.round(6 * root.ui)

                            // Show / Hide password button
                            Rectangle {
                                width: Math.round(38 * root.ui)
                                height: width
                                radius: Math.round(11 * root.ui)
                                color: eyeMouse.containsMouse ? "#1cffffff" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: root.showPassword ? "Hide" : "Show"
                                    color: root.textSecondary
                                    font.family: root.sansFont
                                    font.pixelSize: Math.round(11 * root.ui)
                                }

                                MouseArea {
                                    id: eyeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.showPassword = !root.showPassword
                                        passwordInput.forceActiveFocus()
                                    }
                                }
                            }

                            // Touch Keyboard toggle button
                            Rectangle {
                                width: Math.round(40 * root.ui)
                                height: Math.round(38 * root.ui)
                                radius: Math.round(11 * root.ui)
                                color: root.oskVisible ? Qt.rgba(sessionAccent(root.sessionIndex).r, sessionAccent(root.sessionIndex).g, sessionAccent(root.sessionIndex).b, 0.28) : (kbdMouse.containsMouse ? "#1cffffff" : "#10ffffff")
                                border.width: 1
                                border.color: root.oskVisible ? sessionAccent(root.sessionIndex) : "#1cffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: "KB"
                                    color: root.oskVisible ? root.textPrimary : root.textSecondary
                                    font.family: root.monoFont
                                    font.pixelSize: Math.round(11.5 * root.ui)
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: kbdMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.oskVisible = !root.oskVisible
                                }
                            }

                            // Submit Login button
                            Rectangle {
                                width: Math.round(40 * root.ui)
                                height: Math.round(38 * root.ui)
                                radius: Math.round(11 * root.ui)
                                color: submitMouse.pressed ? Qt.darker(sessionAccent(root.sessionIndex), 1.15) : sessionAccent(root.sessionIndex)
                                opacity: root.loggingIn ? 0.55 : 1.0

                                Behavior on color { ColorAnimation { duration: 180 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "→"
                                    color: "#090d16"
                                    font.family: root.sansFont
                                    font.pixelSize: Math.round(18 * root.ui)
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    id: submitMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.submitLogin()
                                }
                            }
                        }
                    }

                    // Status / Error / Shortcut Hint Line
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.statusMessage.length > 0
                              ? root.statusMessage
                              : "Alt+←/→ switches session  ·  Tap KB for touch keyboard"
                        color: root.loginFailed ? root.accentError : root.textMuted
                        font.family: root.sansFont
                        font.pixelSize: Math.round(12 * root.ui)
                    }
                }
            }
        }
    }

    // --- Bottom-Right Power Bar (hidden while touch keyboard is open) ---
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(24 * root.ui)
        spacing: Math.round(10 * root.ui)
        visible: !root.oskVisible

        Repeater {
            model: [
                { label: "Suspend", enabled: sddm.canSuspend, action: "suspend" },
                { label: "Reboot", enabled: sddm.canReboot, action: "reboot" },
                { label: "Power Off", enabled: sddm.canPowerOff, action: "poweroff" }
            ]

            delegate: Rectangle {
                visible: modelData.enabled
                height: Math.round(38 * root.ui)
                width: pwrTxt.implicitWidth + Math.round(28 * root.ui)
                radius: height / 2
                color: pwrMouse.containsMouse ? "#20ffffff" : "#12ffffff"
                border.width: 1
                border.color: pwrMouse.containsMouse ? "#32ffffff" : "#1cffffff"

                Text {
                    id: pwrTxt
                    anchors.centerIn: parent
                    text: modelData.label
                    color: root.textSecondary
                    font.family: root.sansFont
                    font.pixelSize: Math.round(13 * root.ui)
                }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "suspend") sddm.suspend()
                        else if (modelData.action === "reboot") sddm.reboot()
                        else if (modelData.action === "poweroff") sddm.powerOff()
                    }
                }
            }
        }
    }

    // --- Built-in Touch On-Screen Keyboard Drawer ---
    Rectangle {
        id: oskDrawer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.oskVisible ? Math.round(272 * root.ui) : 0
        clip: true
        color: "#e60b1120"
        border.width: root.oskVisible ? 1 : 0
        border.color: "#22ffffff"

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        readonly property var rowsAlpha: [
            ["1","2","3","4","5","6","7","8","9","0"],
            ["q","w","e","r","t","y","u","i","o","p"],
            ["a","s","d","f","g","h","j","k","l"],
            ["SHIFT","z","x","c","v","b","n","m","BKSP"],
            ["SYM","SPACE","ENTER"]
        ]
        readonly property var rowsSym: [
            ["!","@","#","$","%","^","&","*","(",")"],
            ["-","_","=","+","[","]","{","}","\\","|"],
            [";",":","'","\"",",",".","<",">","/","?"],
            ["`","~","_","-",".",",",":",";","BKSP"],
            ["ABC","SPACE","ENTER"]
        ]

        Column {
            anchors.centerIn: parent
            spacing: Math.round(8 * root.ui)

            Repeater {
                model: root.oskSymbols ? oskDrawer.rowsSym : oskDrawer.rowsAlpha

                delegate: Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(7 * root.ui)

                    Repeater {
                        model: modelData

                        delegate: Rectangle {
                            readonly property string keyVal: modelData
                            readonly property bool isSpecial: keyVal === "SHIFT" || keyVal === "BKSP" || keyVal === "SYM" || keyVal === "ABC" || keyVal === "SPACE" || keyVal === "ENTER"
                            readonly property real keyW: {
                                if (keyVal === "SPACE") return Math.round(320 * root.ui)
                                if (keyVal === "ENTER") return Math.round(130 * root.ui)
                                if (keyVal === "SHIFT" || keyVal === "BKSP" || keyVal === "SYM" || keyVal === "ABC") return Math.round(96 * root.ui)
                                return Math.round(68 * root.ui)
                            }
                            width: keyW
                            height: Math.round(44 * root.ui)
                            radius: Math.round(10 * root.ui)
                            color: {
                                if (keyVal === "ENTER") return keyMouse.pressed ? Qt.darker(sessionAccent(root.sessionIndex), 1.15) : sessionAccent(root.sessionIndex)
                                if (keyVal === "SHIFT" && root.oskShift) return "#3860a5fa"
                                if (keyMouse.pressed) return "#34ffffff"
                                return isSpecial ? "#1cffffff" : "#14ffffff"
                            }
                            border.width: 1
                            border.color: keyVal === "ENTER" ? sessionAccent(root.sessionIndex) : "#20ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (keyVal === "SHIFT") return "Shift"
                                    if (keyVal === "BKSP") return "⌫"
                                    if (keyVal === "SYM") return "?123"
                                    if (keyVal === "ABC") return "ABC"
                                    if (keyVal === "SPACE") return "Space"
                                    if (keyVal === "ENTER") return "Sign in"
                                    return (root.oskShift && !root.oskSymbols) ? keyVal.toUpperCase() : keyVal
                                }
                                color: keyVal === "ENTER" ? "#090d16" : root.textPrimary
                                font.family: root.sansFont
                                font.pixelSize: Math.round((isSpecial ? 13.5 : 16) * root.ui)
                                font.weight: keyVal === "ENTER" ? Font.DemiBold : Font.Medium
                            }

                            MouseArea {
                                id: keyMouse
                                anchors.fill: parent
                                onClicked: {
                                    if (keyVal === "SHIFT") {
                                        root.oskShift = !root.oskShift
                                    } else if (keyVal === "SYM") {
                                        root.oskSymbols = true
                                        root.oskShift = false
                                    } else if (keyVal === "ABC") {
                                        root.oskSymbols = false
                                    } else if (keyVal === "BKSP") {
                                        if (passwordInput.text.length > 0) {
                                            passwordInput.text = passwordInput.text.slice(0, -1)
                                        }
                                    } else if (keyVal === "SPACE") {
                                        passwordInput.text += " "
                                    } else if (keyVal === "ENTER") {
                                        root.submitLogin()
                                    } else {
                                        var ch = (root.oskShift && !root.oskSymbols) ? keyVal.toUpperCase() : keyVal
                                        passwordInput.text += ch
                                        if (root.oskShift) root.oskShift = false
                                    }
                                    passwordInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        passwordInput.forceActiveFocus()
    }
}
