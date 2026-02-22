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

RowLayout {
    id: stackRow;
    height: stackName.height;
    property string composeFile: "";
    property bool isExpanded: false;

    Component.onCompleted: {
        composeFile = Stack.getComposeFile(section);
        isExpanded = true;
        statusIndicator.active = Stack.checkStatus(section);
    }

    onIsExpandedChanged: {
        Stack.updateVisibility(section, stackRow.isExpanded);
        Stack.updateIcon(expandButton, stackRow.isExpanded);
    }

    ToolButton {
        id: expandButton;
        flat: true;
        icon.name: "list-add";
        onClicked: {
            stackRow.isExpanded = !stackRow.isExpanded;
        }
    }

    MouseArea {
        height: 15;
        width: 15;
        onClicked: {
            statusIndicator.active = !statusIndicator.active;
            Stack.startAndStopStack(statusIndicator.active, composeFile);
        }

        Rectangle {
            id: statusIndicator;
            property bool active: false;
            anchors.fill: parent;
            radius: width / 2;
            color: active ? "green" : "gray";
        }
    }

    Kirigami.Icon {
        id: item;
        source: "stack";
        implicitWidth: Kirigami.Units.iconSizes.small;
        implicitHeight: Kirigami.Units.iconSizes.small;
    }

    Label {
        id: stackName;
        text: section;
        Layout.fillWidth: true;
        font.pixelSize: 22;
    }

    ToolButton {
        id: logButton;
        icon.name: "text-plain";
        icon.width: Kirigami.Units.iconSizes.small;
        icon.height: Kirigami.Units.iconSizes.small;
        ToolTip.text: qsTr("Show log");
        ToolTip.visible: hovered;
        onClicked: stackProcess.showLog(composeFile);
    }

    ToolButton {
        id: editButton;
        icon.name: "edit";
        icon.width: Kirigami.Units.iconSizes.small;
        icon.height: Kirigami.Units.iconSizes.small;
        ToolTip.text: qsTr("Edit file");
        ToolTip.visible: hovered;
        onClicked: stackProcess.editFile(composeFile);
    }

    Timer {
        interval: 1000 * 30;
        repeat: true;
        triggeredOnStart: true;
        running: true;
        onTriggered: {
            Stack.updateSection(composeFile);
            statusIndicator.active = Stack.checkStatus(section);
        }
    }

    Process {
        id: stackProcess;
    }
}
