/*
 * Copyright (C) 2020 by David Baum <david.baum@naraesk.eu>
 *
 * This file is part of plasma-docker.
 *
 * plasma-docker is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * plasma-docker is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with plasma-docker.  If not, see <http://www.gnu.org/licenses/>.
 */

function loadServices() {
    serviceModel.clear();
    var list = plasmoid.configuration.container;
    for(var i in list) {
        var item = JSON.parse(list[i]);
        var file = item.dir;
        var services = process.getServices(file);
        for(var j in services) {
            var realitem = createModelItem(file, services[j], item.service);
            serviceModel.append(realitem);
        }
    }
}

function createModelItem(file, name, stack) {
    return {
        file: file,
        name: name,
        stack: stack,
        aVisible: false,
        online: false,
        port: process.isPublic(file, name)
    };
}
