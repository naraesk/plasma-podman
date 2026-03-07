/*
 * Copyright (C) 2018 by David Baum <david.baum@naraesk.eu>
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

ColumnLayout {
    property var cfg_container: []
    property var cfg_containerDefault: []

    id: root

    Component.onCompleted: {
        var list = plasmoid.configuration.container
        cfg_container = []
        for(var i in list) {
            addService( JSON.parse(list[i]) )
        }
    }

    function up(index) {
        serviceModel.move(index, index-1, 1)
        var list = cfg_container.slice()
        var object = list.splice(index, 1)
        list.splice(index-1, 0, object[0])
        cfg_container = list
    }

    function down(index) {
        serviceModel.move(index, index+1, 1)
        var list = cfg_container.slice()
        var object = list.splice(index, 1)
        list.splice(index+1, 0, object[0])
        cfg_container = list
    }

    function addService(object) {
        serviceModel.append(object)
        var list = cfg_container.slice()
        list.push(JSON.stringify(object))
        cfg_container = list
    }

    function removeService(index) {
        if(serviceModel.count > 0) {
            serviceModel.remove(index)
            var list = cfg_container.slice()
            list.splice(index, 1)
            cfg_container = list
        }
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

        TextField {
            id: name
            Kirigami.FormData.label: i18n("Title:")
            placeholderText: "Display name of stack"
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Compose file:")

            TextField {
                id: dir
                Layout.fillWidth: true
                placeholderText: "Path of compose file"
            }

            Button {
                text: i18n("Select")
                onClicked: fileDialog.open()
            }
        }

        Button {
            text: i18n("Add stack")
            icon.name: "list-add"
            onClicked: {
                var object = ({'service': name.text, 'dir': dir.text})
                addService(object)
                name.text = ""
                dir.text = ""
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing
    }

    Kirigami.Heading {
        text: i18n("Configured stacks")
        level: 4
        Layout.topMargin: Kirigami.Units.smallSpacing
    }

    ListModel {
        id: serviceModel
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: serviceModel

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: model.service
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    elide: Text.ElideRight
                }
                Label {
                    text: model.dir
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    opacity: 0.7
                }
                ToolButton {
                    icon.name: "arrow-up"
                    enabled: model.index > 0
                    onClicked: up(model.index)
                }
                ToolButton {
                    icon.name: "arrow-down"
                    enabled: model.index < serviceModel.count - 1
                    onClicked: down(model.index)
                }
                ToolButton {
                    icon.name: "list-remove"
                    onClicked: removeService(model.index)
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    FileDialog {
        id: fileDialog
        title: i18n("Please choose a compose file")
        nameFilters: ["Compose files (*.yml *.yaml)"]
        onAccepted: {
            var folderPath = fileDialog.selectedFile.toString();
            folderPath = folderPath.replace(/^(file:\/{2})|(qrc:\/{2})|(http:\/{2})/, "");
            dir.text = decodeURIComponent(folderPath);
        }
    }
}
