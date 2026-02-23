/*
 * Copyright (C) 2020 by David Baum <david.baum@naraesk.eu>
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
import "stack.js" as Stack;

ColumnLayout {
    id: stackRoot;
    width: parent ? parent.width : 0;
    spacing: 0;
    property string composeFile: "";
    property bool isExpanded: false;

    Component.onCompleted: {
        composeFile = Stack.getComposeFile(section);
        isExpanded = true;
        statusSwitch.checked = Stack.checkStatus(section);
    }

    onIsExpandedChanged: {
        Stack.updateVisibility(section, stackRoot.isExpanded);
    }

    Rectangle {
        Layout.fillWidth: true;
        implicitHeight: stackRow.implicitHeight;
        color: Kirigami.Theme.alternateBackgroundColor;
        radius: Kirigami.Units.cornerRadius;

        RowLayout {
            id: stackRow;
            anchors.fill: parent;
            spacing: Kirigami.Units.smallSpacing;

            ToolButton {
                id: expandButton;
                flat: true;
                icon.name: stackRoot.isExpanded ? "go-down" : "go-next";
                onClicked: {
                    stackRoot.isExpanded = !stackRoot.isExpanded;
                }
            }

            Switch {
                id: statusSwitch;
                checked: false;
                onToggled: {
                    Stack.startAndStopStack(checked, composeFile);
                }
            }

            Kirigami.Heading {
                id: stackName;
                text: section;
                Layout.fillWidth: true;
                level: 4;
            }

            ToolButton {
                id: logButton;
                icon.name: "utilities-log-viewer";
                icon.width: Kirigami.Units.iconSizes.small;
                icon.height: Kirigami.Units.iconSizes.small;
                ToolTip.text: qsTr("Show log");
                ToolTip.visible: hovered;
                onClicked: stackProcess.showLog(composeFile);
            }

            ToolButton {
                id: editButton;
                icon.name: "document-edit";
                icon.width: Kirigami.Units.iconSizes.small;
                icon.height: Kirigami.Units.iconSizes.small;
                ToolTip.text: qsTr("Edit file");
                ToolTip.visible: hovered;
                onClicked: stackProcess.editFile(composeFile);
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true;
    }

    Timer {
        interval: 1000 * 30;
        repeat: true;
        triggeredOnStart: true;
        running: true;
        onTriggered: {
            Stack.updateSection(composeFile);
            statusSwitch.checked = Stack.checkStatus(section);
        }
    }

    Process {
        id: stackProcess;
    }
}
