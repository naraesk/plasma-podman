/*
 * Copyright (C) 2026 by David Baum <david.baum@naraesk.eu>
 *
 * This file is part of plasma-podman.
 *
 * plasma-podman is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * plasma-podman is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with plasma-podman.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick;
import QtQuick.Controls;
import QtQuick.Layouts;
import eu.naraesk.podman.process 1.2;
import org.kde.kirigami as Kirigami;
import "service.js" as Service;

ColumnLayout {
    id: serviceDelegate;
    visible: aVisible;
    property bool online: model.online;
    property bool volumesExpanded: false;
    property var parsedVolumes: model.volumes ? JSON.parse(model.volumes) : [];
    width: parent ? parent.width : 0;
    spacing: 0;
    height: aVisible ? implicitHeight : 0;

    onOnlineChanged: {
        statusSwitch.checked = online;
    }

    Behavior on height {
        NumberAnimation { duration: 100; }
    }

    RowLayout {
        id: serviceRow;
        Layout.fillWidth: true;
        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing;
        spacing: Kirigami.Units.smallSpacing;

        Switch {
            id: statusSwitch;
            checked: online;
            onToggled: {
                Service.startAndStopService(checked, model.file, model.name);
                root.fastPollGeneration++;
            }
        }

        Label {
            Layout.topMargin: Kirigami.Units.smallSpacing;
            Layout.bottomMargin: Kirigami.Units.smallSpacing;
            id: text;
            text: name;
            ToolTip.text: model.imageTag;
            ToolTip.visible: model.imageTag !== "" && nameHover.hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;

            HoverHandler {
                id: nameHover;
            }
        }

        Label {
            id: portLabel;
            text: ":" + model.port;
            visible: model.port !== "";
            opacity: 0.6;
        }

        Item {
            Layout.fillWidth: true;
        }

        ToolButton {
            id: volumeButton;
            icon.name: serviceDelegate.volumesExpanded ? "folder-open" : "folder";
            icon.width: Kirigami.Units.iconSizes.small;
            icon.height: Kirigami.Units.iconSizes.small;
            ToolTip.text: qsTr("Show volumes");
            ToolTip.visible: hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;
            visible: serviceDelegate.parsedVolumes.length > 0;
            onClicked: serviceDelegate.volumesExpanded = !serviceDelegate.volumesExpanded;
        }

        ToolButton {
            id: deleteVolumesButton;
            ToolTip.text: qsTr("Delete volumes");
            ToolTip.visible: hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;
            visible: serviceDelegate.parsedVolumes.length > 0;
            onClicked: deleteVolumesDialog.open();

            contentItem: Kirigami.Icon {
                source: "edit-delete";
                color: Kirigami.Theme.textColor;
                isMask: true;
                implicitWidth: Kirigami.Units.iconSizes.small;
                implicitHeight: Kirigami.Units.iconSizes.small;
            }
        }

        ToolButton {
            id: logButton;
            icon.name: "text-x-log";
            icon.width: Kirigami.Units.iconSizes.small;
            icon.height: Kirigami.Units.iconSizes.small;
            ToolTip.text: qsTr("Show log");
            ToolTip.visible: hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;
            visible: model.online;
            onClicked: serviceProcess.showServiceLog(model.file, model.name);
        }

        ToolButton {
            id: restartButton;
            icon.name: "view-refresh";
            icon.width: Kirigami.Units.iconSizes.small;
            icon.height: Kirigami.Units.iconSizes.small;
            ToolTip.text: qsTr("Restart service");
            ToolTip.visible: hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;
            visible: model.online;
            onClicked: {
                Service.restartService(model.file, model.name);
                root.fastPollGeneration++;
            }
        }

        ToolButton {
            id: execButton;
            icon.name: "utilities-terminal";
            icon.width: Kirigami.Units.iconSizes.small;
            icon.height: Kirigami.Units.iconSizes.small;
            ToolTip.text: qsTr("Run shell");
            ToolTip.visible: hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;
            visible: model.online;
            onClicked: serviceProcess.runShell(model.file, model.name);
        }

        ToolButton {
            id: browserButton;
            icon.name: "google-chrome";
            icon.width: Kirigami.Units.iconSizes.small;
            icon.height: Kirigami.Units.iconSizes.small;
            ToolTip.text: qsTr("Open in browser");
            ToolTip.visible: hovered;
            ToolTip.delay: Kirigami.Units.toolTipDelay;
            visible: model.online && model.port !== "";
            onClicked: serviceProcess.startBrowser(model.file, model.name);
        }
    }

    ColumnLayout {
        id: volumeList;
        visible: serviceDelegate.volumesExpanded;
        Layout.fillWidth: true;
        Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing;
        spacing: Kirigami.Units.smallSpacing;

        Repeater {
            model: serviceDelegate.parsedVolumes;

            RowLayout {
                Layout.fillWidth: true;
                spacing: Kirigami.Units.smallSpacing;

                Kirigami.Icon {
                    source: "folder-symbolic";
                    implicitWidth: Kirigami.Units.iconSizes.small;
                    implicitHeight: Kirigami.Units.iconSizes.small;
                }

                Label {
                    text: modelData.container;
                    opacity: 0.7;
                }

                Label {
                    text: "\u2192";
                    opacity: 0.5;
                }

                Label {
                    text: modelData.host;
                    Layout.fillWidth: true;
                    elide: Text.ElideMiddle;
                    color: hostMouseArea.containsMouse ? Kirigami.Theme.linkColor : Kirigami.Theme.textColor;

                    MouseArea {
                        id: hostMouseArea;
                        anchors.fill: parent;
                        hoverEnabled: true;
                        cursorShape: Qt.PointingHandCursor;
                        onClicked: serviceProcess.openDirectory(modelData.host);
                    }

                    ToolTip.text: modelData.host;
                    ToolTip.visible: hostMouseArea.containsMouse;
                    ToolTip.delay: Kirigami.Units.toolTipDelay;
                }
            }
        }
    }

    Dialog {
        id: deleteVolumesDialog;
        title: qsTr("Delete Volumes");
        modal: true;
        anchors.centerIn: Overlay.overlay;
        standardButtons: Dialog.Yes | Dialog.No;

        Label {
            text: qsTr("Delete all volumes for service \"%1\"?\nThis will stop the service and remove its containers and volumes.").arg(model.name);
        }

        onAccepted: {
            serviceProcess.deleteServiceVolumes(model.file, model.name);
            root.fastPollGeneration++;
        }
    }

    Process {
        id: serviceProcess;
    }
}
