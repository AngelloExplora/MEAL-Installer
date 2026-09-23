// shell.qml - MEAL Shell v0.2
// Barra superior con marca MEAL, escritorios numerados (Hyprland real,
// via Quickshell.Hyprland - Hyprland.workspaces) y reloj.
// NOTA: el indicador de escritorios usa la IPC de Hyprland, asi que solo
// funciona corriendo bajo Hyprland. Para Niri/Mango se necesita otro modulo
// (pendiente, no inventado aqui).

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        height: 36

        Rectangle {
            anchors.fill: parent
            color: "#1a1025"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 16

                // Logo / marca MEAL
                Text {
                    text: "MEAL"
                    color: "#e879f9"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 2
                }

                // Escritorios numerados (Hyprland real)
                RowLayout {
                    spacing: 6

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Rectangle {
                            property var wsp: modelData
                            width: 24
                            height: 24
                            radius: 6
                            color: wsp.focused ? "#e879f9" : "#2d1f3d"

                            Text {
                                anchors.centerIn: parent
                                text: wsp.id
                                color: wsp.focused ? "#1a1025" : "#cccccc"
                                font.bold: wsp.focused
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: wsp.activate()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    id: reloj
                    color: "#ffffff"
                    font.pixelSize: 14
                    text: Qt.formatDateTime(new Date(), "hh:mm")

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: reloj.text = Qt.formatDateTime(new Date(), "hh:mm")
                    }
                }
            }
        }
    }
}
