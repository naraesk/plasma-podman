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
import QtQuick.Layouts;
import QtQuick.Controls;
import eu.naraesk.podman.process 1.2;
import org.kde.plasma.plasmoid;
import org.kde.kirigami as Kirigami;
import "model.js" as Model;
import "Service"
import "Stack"

Item {
    id: root;
    property int fastPollGeneration: 0;
    Layout.minimumWidth: Kirigami.Units.gridUnit * 12;
    Layout.minimumHeight: Kirigami.Units.gridUnit * 6;
    Layout.preferredHeight: view.contentHeight;

    Component.onCompleted: {
        Model.loadServices();
    }

    Connections {
        target: plasmoid.configuration;
        function onContainerChanged() { Model.loadServices(); }
    }

    Process {
        id: process;
        onComposeFileChanged: { Model.loadServices(); }
    }

    ListModel {
        id: serviceModel;
    }

    ListView {
        id: view;
        anchors.fill: parent;
        clip: true;
        model: serviceModel;
        spacing: Kirigami.Units.smallSpacing;
        delegate: ServiceDelegate {}
        section.property: 'stack';
        section.delegate: StackDelegate {}
    }

    Label {
        id: startLabel;
        anchors.fill: parent;
        horizontalAlignment: Text.AlignHCenter;
        verticalAlignment: Text.AlignVCenter;
        text: qsTr("Open the configuration menu to add compose files");
        wrapMode: Label.WordWrap;
        visible: serviceModel.count === 0;
    }
}
