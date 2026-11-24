import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

Pane {
    padding: 0
    id: consolePane
    StackView.onActivated: {
        forceActiveFocus(Qt.TabFocusReason);
        if(!Chiaki.autoConnect && !root.initialAsk && !Chiaki.window.directStream)
        {
            root.initialAsk = true;
            if(Chiaki.settings.addSteamShortcutAsk && (typeof Chiaki.createSteamShortcut === "function"))
                root.showRemindDialog(qsTr("Official Steam artwork + controller layout"), qsTr("Would you like to either create a new non-Steam game for chiaki-ng\nor update an existing non-Steam game with the official artwork and controller layout?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, click the button or press R3 from the main menu.)"), false, () => root.showSteamShortcutDialog(true));
            else if(Chiaki.settings.remotePlayAsk)
            {
                if(!Chiaki.settings.psnRefreshToken || !Chiaki.settings.psnAuthToken || !Chiaki.settings.psnAuthTokenExpiry || !Chiaki.settings.psnAccountId)
                    root.showRemindDialog(qsTr("Remote Play via PSN"), qsTr("Would you like to connect to PSN?\nThis enables:\n- Automatic registration\n- Playing outside of your home network without port forwarding?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, go to the Config section of the settings.)"), true, () => root.showPSNTokenDialog(false));
                else
                    Chiaki.settings.remotePlayAsk = false;
            }
        }
    }
    Keys.onUpPressed: {
        if(hostsView.currentItem && hostsView.currentItem.visible)
        {
            hostsView.decrementCurrentIndex()
            while(!hostsView.currentItem.visible)
                hostsView.decrementCurrentIndex()
        }
    }
    Keys.onDownPressed: {
        if(hostsView.currentItem && hostsView.currentItem.visible)
        {
            hostsView.incrementCurrentIndex()
            while(!hostsView.currentItem.visible)
                 hostsView.incrementCurrentIndex()
        }
    }
    Keys.onMenuPressed: settingsButton.clicked()
    Keys.onReturnPressed: if (hostsView.currentItem) hostsView.currentItem.connectToHost()
    Keys.onYesPressed: if (hostsView.currentItem) hostsView.currentItem.wakeUpHost()
    Keys.onNoPressed: if (hostsView.currentItem) hostsView.currentItem.deleteHost()
    Keys.onEscapePressed: root.showConfirmDialog(qsTr("Quit"), qsTr("Are you sure you want to quit?"), () => Qt.quit())
    Keys.onPressed: (event) => {
        if (event.modifiers)
            return;
        switch (event.key) {
        case Qt.Key_PageUp:
            if (hostsView.currentItem) hostsView.currentItem.setConsolePin();
            event.accepted = true;
            break;
        case Qt.Key_PageDown:
            if (Chiaki.settings.psnAuthToken) Chiaki.refreshPsnToken();
            event.accepted = true;
            break;
        case Qt.Key_F1:
            if (typeof Chiaki.createSteamShortcut === "function") root.showSteamShortcutDialog(false);
            event.accepted = true;
            break;
        case Qt.Key_F2:
            root.showManualHostDialog();
            event.accepted = true;
            break;
        }
    }

    readonly property color cardColor: "#1b1c20"
    readonly property color cardBorder: "#2c2d33"
    readonly property color mutedText: "#9a9a9a"

    function streamSummary() {
        const res = ["", "360p", "540p", "720p", "1080p"][Chiaki.settings.resolutionLocalPS5] || "";
        const codec = ["H264", "H265", "H265 HDR"][Chiaki.settings.codecLocalPS5] || "";
        return res + " · " + Chiaki.settings.fpsLocalPS5 + "fps · " + codec;
    }

    function presetName() {
        const r = Chiaki.settings.resolutionLocalPS5;
        const c = Chiaki.settings.codecLocalPS5;
        if (r === 4 && c >= 1)
            return qsTr("Best quality");
        if (r === 3 && c === 1)
            return qsTr("Balanced");
        if (r === 3 && c === 0)
            return qsTr("Lowest lag");
        return qsTr("Custom");
    }

    function applyPreset(resolution, codec) {
        Chiaki.settings.resolutionLocalPS5 = resolution;
        Chiaki.settings.fpsLocalPS5 = 60;
        Chiaki.settings.codecLocalPS5 = codec;
        Chiaki.settings.bitrateLocalPS5 = 0;
    }

    ToolBar {
        id: toolBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 72
        background: Rectangle { color: "transparent" }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 32
                rightMargin: 16
            }
            spacing: 4

            Label {
                text: qsTr("Remote Play")
                font.pixelSize: 26
                font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            Button {
                flat: true
                text: qsTr("Steam shortcut")
                font.pixelSize: 16
                focusPolicy: Qt.NoFocus
                onClicked: root.showSteamShortcutDialog(false)
                Material.roundedScale: Material.SmallScale
                visible: typeof Chiaki.createSteamShortcut === "function"
            }

            Button {
                flat: true
                text: qsTr("Refresh PSN")
                font.pixelSize: 16
                focusPolicy: Qt.NoFocus
                onClicked: Chiaki.refreshPsnToken();
                Material.roundedScale: Material.SmallScale
                visible: Chiaki.settings.psnAuthToken
            }

            Button {
                flat: true
                icon.source: "qrc:/icons/add-24px.svg"
                icon.width: 28
                icon.height: 28
                focusPolicy: Qt.NoFocus
                onClicked: root.showManualHostDialog()
                Material.roundedScale: Material.SmallScale
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Add console")
            }

            Button {
                id: settingsButton
                flat: true
                icon.source: "qrc:/icons/settings-20px.svg"
                icon.width: 28
                icon.height: 28
                focusPolicy: Qt.NoFocus
                onClicked: root.showSettingsDialog()
                Material.roundedScale: Material.SmallScale
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Settings")
            }

            Button {
                flat: true
                text: "×"
                font.pixelSize: 30
                focusPolicy: Qt.NoFocus
                onClicked: Qt.quit()
                Material.roundedScale: Material.SmallScale
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Quit")
            }
        }
    }

    ListView {
        id: hostsView
        keyNavigationWraps: true
        anchors {
            top: toolBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 12
            leftMargin: 32
            rightMargin: 32
            bottomMargin: 100
        }
        spacing: 16
        clip: true
        model: Chiaki.hosts
        onCountChanged: {
            if(!hostsView.currentItem)
                hostsView.incrementCurrentIndex();
            if(!hostsView.currentItem)
                return;
            if(!hostsView.currentItem.visible)
            {
                for(var i = 0; i < hostsView.count; i++)
                {
                    hostsView.incrementCurrentIndex()
                    if(hostsView.currentItem.visible)
                    {
                        break;
                    }
                }
            }
        }
        delegate: ItemDelegate {
            visible: modelData.display
            id: delegate
            width: hostsView.width
            height: modelData.display ? 150 : 0
            highlighted: ListView.isCurrentItem
            onClicked: connectToHost()

            background: Rectangle {
                radius: 16
                color: consolePane.cardColor
                border.width: delegate.highlighted ? 2 : 1
                border.color: delegate.highlighted ? Material.accent : consolePane.cardBorder
            }

            function connectToHost() {
                if(modelData.discovered)
                    Chiaki.connectToHost(index, modelData.name);
                else
                    Chiaki.connectToHost(index);
            }

            function wakeUpHost() {
                if(!modelData.discovered && !modelData.duid)
                    Chiaki.wakeUpHost(index);
            }

            function deleteHost() {
                if (modelData.manual)
                    root.showConfirmDialog(qsTr("Delete Console"), qsTr("Are you sure you want to delete this console?"), () => {Chiaki.deleteHost(index)});

                else if (modelData.discovered && !modelData.registered)
                    root.showConfirmDialog(qsTr("Hide Console"), qsTr("Are you sure you want to hide this console?") + "\n\n" + qsTr("Note: You can unhide from the Consoles section of the Settings under Hidden Consoles"), () => Chiaki.hideHost(modelData.mac, modelData.name));

            }

            function setConsolePin() {
                root.showConsolePinDialog(index);
            }

            readonly property bool ready: modelData.state != "standby" && (modelData.discovered || !!modelData.duid)

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 24
                    rightMargin: 24
                    topMargin: 16
                    bottomMargin: 16
                }
                spacing: 24

                Image {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 96
                    fillMode: Image.PreserveAspectFit
                    source: "image://svg/console-ps" + (modelData.ps5 ? "5" : "4") + (modelData.state == "standby" ? "#light_standby" : "#light_on")
                    sourceSize: Qt.size(width, height)
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: modelData.name ? modelData.name : (modelData.ps5 ? "PS5" : "PS4")
                        font.pixelSize: 24
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: modelData.state == "standby" ? "#e0a030" : (delegate.ready ? "#3fbf7f" : "#777777")
                        }
                        Label {
                            font.pixelSize: 16
                            color: consolePane.mutedText
                            text: {
                                let s = modelData.state == "standby" ? qsTr("Resting") : (delegate.ready ? qsTr("Ready") : qsTr("Not found"));
                                if (modelData.duid && !modelData.discovered)
                                    s = qsTr("Via PSN");
                                if (modelData.address)
                                    s += " · " + (Chiaki.settings.streamerMode ? qsTr("address hidden") : modelData.address);
                                if (!modelData.registered && !modelData.duid)
                                    s += " · " + qsTr("not registered");
                                if (modelData.app)
                                    s += " · " + modelData.app;
                                return s;
                            }
                        }
                    }

                    Label {
                        visible: !!modelData.ps5
                        font.pixelSize: 14
                        color: "#7a7a7a"
                        text: consolePane.streamSummary()
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Button {
                        flat: true
                        text: qsTr("Wake")
                        font.pixelSize: 15
                        visible: modelData.registered && !modelData.duid && !modelData.discovered
                        focusPolicy: Qt.NoFocus
                        onClicked: delegate.wakeUpHost()
                        Material.roundedScale: Material.SmallScale
                    }

                    Button {
                        flat: true
                        text: qsTr("PIN")
                        font.pixelSize: 15
                        visible: modelData.registered
                        focusPolicy: Qt.NoFocus
                        onClicked: delegate.setConsolePin()
                        Material.roundedScale: Material.SmallScale
                    }

                    Button {
                        flat: true
                        text: modelData.manual ? qsTr("Delete") : qsTr("Hide")
                        font.pixelSize: 15
                        visible: modelData.manual || (modelData.discovered && !modelData.registered)
                        focusPolicy: Qt.NoFocus
                        onClicked: delegate.deleteHost()
                        Material.roundedScale: Material.SmallScale
                    }

                    Button {
                        text: (modelData.registered || modelData.duid) ? qsTr("Play") : qsTr("Register")
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        leftPadding: 28
                        rightPadding: 28
                        highlighted: true
                        focusPolicy: Qt.NoFocus
                        onClicked: delegate.connectToHost()
                        Material.roundedScale: Material.FullScale
                    }
                }
            }
        }
    }

    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 28
        }
        spacing: 8

        Label {
            text: qsTr("Quality:")
            font.pixelSize: 16
            color: consolePane.mutedText
        }

        Repeater {
            model: [
                { name: qsTr("Best quality"), res: 4, codec: 1 },
                { name: qsTr("Balanced"), res: 3, codec: 1 },
                { name: qsTr("Lowest lag"), res: 3, codec: 0 }
            ]
            delegate: Button {
                required property var modelData
                text: modelData.name
                font.pixelSize: 15
                flat: consolePane.presetName() !== modelData.name
                highlighted: !flat
                focusPolicy: Qt.NoFocus
                onClicked: consolePane.applyPreset(modelData.res, modelData.codec)
                Material.roundedScale: Material.FullScale
            }
        }
    }

    RoundButton {
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 20
        }
        icon.source: "qrc:/icons/discover-" + (checked ? "" : "off-") + "24px.svg"
        icon.width: 50
        icon.height: 50
        padding: 20
        focusPolicy: Qt.NoFocus
        checkable: true
        checked: Chiaki.discoveryEnabled
        onToggled: Chiaki.discoveryEnabled = !Chiaki.discoveryEnabled
        Material.background: Material.accent
    }

    Label {
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 20
        }
        text: Qt.application.version
    }

    Image {
        id: logoImage
        anchors.centerIn: parent
        source: "qrc:/icons/chiaking-logo-white.svg"
        sourceSize: Qt.size(Math.min(parent.width, parent.height) / 2, Math.min(parent.width, parent.height) / 2)

        PropertyAnimation {
            target: logoImage
            property: "opacity"
            from: 0.02
            to: 0.06
            duration: 1000
            easing.type: Easing.OutCubic
            running: true
        }
    }
}
