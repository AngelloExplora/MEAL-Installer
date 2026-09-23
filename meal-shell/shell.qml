// shell.qml - MEAL Shell v0.1
// Barra superior minima pero real y funcional: marca MEAL + reloj.
// Se amplia con mas widgets en fases futuras.

import Quickshell
import QtQuick
import QtQuick.Layouts

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        height: 32

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8

            Text {
                text: "MEAL"
                color: "#e879f9"
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                id: reloj
                color: "white"
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
