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

function updateSection(file) {
    var ids = process.getRunningServices(file);
    for(var i=0; i< serviceModel.count; i++){
        var service = serviceModel.get(i);
        if(service.file === file) {
            service.online = ids.includes(service.name);
            if (service.online) {
                var ports = process.getPublicPorts(file, service.name);
                service.port = ports;
            } else {
                service.port = "";
            }
        }
    }
}

function updateVisibility(stack, visibility) {
    for(var i=0; i<serviceModel.count; i++) {
        var service = serviceModel.get(i);
        if(stack === service.stack) {
            service.aVisible = visibility;
        }
    }
}

function getComposeFile(stack) {
    for(var i=0; i<serviceModel.count; i++) {
        var service = serviceModel.get(i);
        if(stack === service.stack) {
           return service.file;
        }
    }
}

