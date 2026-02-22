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
import "service.js" as Service;

RowLayout {
    id: serviceRow;
    visible: aVisible;
    property bool online: model.online;
    Layout.leftMargin: 20;
    Layout.fillWidth: true;
    spacing: 0;

    onVisibleChanged: {
        height = Service.getHeight(visible, text.height);
    }

    onOnlineChanged: {
        statusIndicator.active = online;
    }

    Behavior on height {
        NumberAnimation { duration: 100; }
    }

    Rectangle {
        id: spacer;
        width: Kirigami.Units.largeSpacing * 3;
    }

    MouseArea {
        id: statusButton;
        height: 15;
        width: 15;
        onClicked: {
            statusIndicator.active = !statusIndicator.active;
            Service.startAndStopService(statusIndicator.active, model.file, model.name);
        }

        Rectangle {
            id: statusIndicator;
            property bool active: online;
            anchors.fill: parent;
            radius: width / 2;
            color: active ? "green" : "gray";
        }
    }

    Rectangle {
        id: spacer2;
        width: Kirigami.Units.smallSpacing;
    }

    Label {
        Layout.topMargin: Kirigami.Units.smallSpacing;
        Layout.bottomMargin: Kirigami.Units.smallSpacing;
        id: text;
        text: name;
    }

    Rectangle {
        id: spacer3;
        width: Kirigami.Units.largeSpacing;
    }

    ToolButton {
        id: execButton;
        icon.name: "bash";
        icon.width: Kirigami.Units.iconSizes.small;
        icon.height: Kirigami.Units.iconSizes.small;
        ToolTip.text: qsTr("Run shell");
        ToolTip.visible: hovered;
        visible: model.online;
        onClicked: serviceProcess.runShell(model.file, model.name);
    }

    ToolButton {
        id: browserButton;
        icon.name: "browser";
        icon.width: Kirigami.Units.iconSizes.small;
        icon.height: Kirigami.Units.iconSizes.small;
        ToolTip.text: qsTr("Open in browser");
        ToolTip.visible: hovered;
        visible: model.online && model.port;
        onClicked: serviceProcess.startBrowser(model.file, model.name);
    }

    Process {
        id: serviceProcess;
    }
}
