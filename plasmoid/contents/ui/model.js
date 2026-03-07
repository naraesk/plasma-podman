/*
 * Copyright (C) 2026 by David Baum <david.baum@naraesk.eu>
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
        process.watchFile(file);
        var services = process.getServices(file);
        for(var j in services) {
            var image = process.getServiceImage(file, services[j]);
            var volumeList = process.getServiceVolumes(file, services[j]);
            var volumes = JSON.stringify(volumeList.map(function(v) {
                var parts = v.split("::");
                return { host: parts[0], container: parts[1] };
            }));
            var realitem = createModelItem(file, services[j], item.service, image, volumes);
            serviceModel.append(realitem);
        }
    }
}

function createModelItem(file, name, stack, image, volumes) {
    var tag = "";
    if (image) {
        var colonIndex = image.lastIndexOf(":");
        if (colonIndex !== -1) {
            tag = image.substring(colonIndex + 1);
        }
    }
    return {
        file: file,
        name: name,
        stack: stack,
        aVisible: false,
        online: false,
        port: "",
        imageTag: tag,
        volumes: volumes || "[]"
    };
}
