import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

CavDialog {
    id: root

    title: "SETUP"
    subtitle: "Device pairing, then Apple ID"
    width: 560

    ColumnLayout {
        width: root.width
        spacing: 0

        // ── State ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: stateCol.implicitHeight + Theme.sp3 * 2
            color: Theme.bg0

            ColumnLayout {
                id: stateCol
                anchors.fill: parent
                anchors.margins: Theme.sp3
                anchors.leftMargin: Theme.sp4
                spacing: 2

                RowLayout {
                    spacing: Theme.sp2
                    Text {
                        text: "auth"
                        color: Theme.fg4
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                    Text {
                        text: Core.authLabel
                        color: Core.ready ? Theme.success : Theme.warning
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    spacing: Theme.sp2
                    Layout.fillWidth: true
                    Text {
                        text: "relay"
                        color: Theme.fg4
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                    Text {
                        text: Core.hasOsConfig ? Core.osConfigSummary : "not paired"
                        color: Theme.fg3
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ── Step 1 ───────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            spacing: Theme.sp2

            Text {
                text: "STEP 1: DEVICE PAIRING"
                color: Theme.red
                font.family: Theme.fontHeading
                font.pixelSize: 10
                font.letterSpacing: 10 * Theme.trackEyebrow
            }

            Text {
                text: "Paste a relay pairing code from the OpenBubbles setup flow on a paired Mac. " +
                      "The relay is asked for hardware info and the result is persisted as os_config.json."
                color: Theme.fg4
                font.family: Theme.fontBody
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            CavTextField {
                id: relayHost
                Layout.fillWidth: true
                placeholderText: "Relay host"
                text: Core.relayHost
                onEditingFinished: if (text !== Core.relayHost) Core.setRelayHost(text)
            }

            CavTextField {
                id: pairCode
                Layout.fillWidth: true
                placeholderText: "Pairing code"
            }

            CavTextField {
                id: beeperToken
                Layout.fillWidth: true
                placeholderText: "Beeper access token (optional)"
                echoMode: TextInput.Password
            }

            RowLayout {
                spacing: Theme.sp2

                CavButton {
                    text: "COMPLETE PAIRING"
                    primary: true
                    implicitWidth: 150
                    enabled: pairCode.text.trim() !== ""
                    onClicked: Core.completePairing(pairCode.text.trim(), beeperToken.text.trim())
                }

                CavButton {
                    text: "CLEAR"
                    danger: true
                    implicitWidth: 72
                    enabled: Core.hasOsConfig
                    onClicked: Core.clearPairing()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }

        // ── Step 2 ───────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            spacing: Theme.sp2
            enabled: Core.hasOsConfig
            opacity: enabled ? 1 : 0.45

            Text {
                text: "STEP 2: APPLE ID"
                color: Theme.red
                font.family: Theme.fontHeading
                font.pixelSize: 10
                font.letterSpacing: 10 * Theme.trackEyebrow
            }

            Text {
                text: Core.hasOsConfig
                      ? "Sign in. The account blob is cached locally so a restart does not ask for 2FA again."
                      : "Complete step 1 first."
                color: Theme.fg4
                font.family: Theme.fontBody
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            CavTextField {
                id: appleId
                Layout.fillWidth: true
                placeholderText: "you@icloud.com"
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
            }

            CavTextField {
                id: password
                Layout.fillWidth: true
                placeholderText: "Password"
                echoMode: TextInput.Password
            }

            CavButton {
                text: "SIGN IN"
                primary: true
                implicitWidth: 100
                enabled: appleId.text.trim() !== "" && password.text !== ""
                onClicked: Core.startAppleIdAuth(appleId.text.trim(), password.text)
            }

            RowLayout {
                Layout.topMargin: Theme.sp2
                spacing: Theme.sp2

                CavTextField {
                    id: twoFactor
                    Layout.preferredWidth: 110
                    placeholderText: "2FA code"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: RegularExpressionValidator { regularExpression: /[0-9]{0,8}/ }
                    onAccepted: if (text.length > 0) Core.submitTwoFactorCode(text)
                }

                CavButton {
                    text: "SUBMIT"
                    implicitWidth: 90
                    enabled: twoFactor.text.length > 0
                    onClicked: Core.submitTwoFactorCode(twoFactor.text)
                }
            }
        }
    }
}
