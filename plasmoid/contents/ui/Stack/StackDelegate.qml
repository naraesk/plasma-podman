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

            Kirigami.Heading {
                id: stackName;
                text: section;
                Layout.fillWidth: true;
                level: 4;
            }

            ToolButton {
                id: pullButton;
                property string pullState: "idle";
                icon.name: "download";
                icon.width: Kirigami.Units.iconSizes.small;
                icon.height: Kirigami.Units.iconSizes.small;
                icon.color: pullState === "success" ? Kirigami.Theme.positiveTextColor
                          : pullState === "failure" ? Kirigami.Theme.negativeTextColor
                          : "transparent";
                ToolTip.text: qsTr("Update");
                ToolTip.visible: hovered;
                ToolTip.delay: Kirigami.Units.toolTipDelay;
                enabled: pullState !== "pulling";
                onClicked: {
                    pullState = "pulling";
                    pullProcess.pullImages(composeFile);
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
                onClicked: stackProcess.showLog(composeFile);
            }

            ToolButton {
                id: editButton;
                icon.name: "document-edit";
                icon.width: Kirigami.Units.iconSizes.small;
                icon.height: Kirigami.Units.iconSizes.small;
                ToolTip.text: qsTr("Edit file");
                ToolTip.visible: hovered;
                ToolTip.delay: Kirigami.Units.toolTipDelay;
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
        }
    }

    Timer {
        id: fastPollTimer;
        property int remainingTicks: 0;
        interval: 1000 * 3;
        repeat: true;
        running: false;
        onTriggered: {
            Stack.updateSection(composeFile);
            remainingTicks--;
            if (remainingTicks <= 0) {
                running = false;
            }
        }
    }

    Connections {
        target: root;
        function onFastPollGenerationChanged() {
            // refresh right away, then keep watching for a while: a container
            // can take a moment to actually come up after podman returns
            Stack.updateSection(composeFile);
            fastPollTimer.remainingTicks = 10;
            fastPollTimer.restart();
        }
    }

    Process {
        id: stackProcess;
    }

    Process {
        id: pullProcess;
        onCommandFinished: function(exitCode) {
            if (exitCode === 0) {
                recreateProcess.recreateStack(composeFile);
            } else {
                pullButton.pullState = "failure";
                pullResetTimer.restart();
            }
        }
    }

    Process {
        id: recreateProcess;
        onCommandFinished: function(exitCode) {
            pullButton.pullState = exitCode === 0 ? "success" : "failure";
            pullResetTimer.restart();
            root.fastPollGeneration++;
        }
    }

    Timer {
        id: pullResetTimer;
        interval: 5000;
        onTriggered: pullButton.pullState = "idle";
    }
}
