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

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: compactRep;
    height: Kirigami.Units.iconSizes.toolbar;
    width: Kirigami.Units.iconSizes.toolbar;

    Image {
        id: compactIcon;
        source: "../../images/icon.png";
        fillMode: Image.PreserveAspectFit;
        anchors.fill: parent;
        height: parent.height;
        width: parent.width;
    }

    MouseArea {
        id: mouseArea;
        anchors.fill: parent;
        onClicked: {
            main.expanded = !main.expanded;
        }
        hoverEnabled: true;
    }
}
