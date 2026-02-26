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

function updateSection(file) {
    console.log("updateSection called for file:", file);
    var ids = process.getRunningServices(file);
    console.log("running services:", JSON.stringify(ids));
    for(var i=0; i< serviceModel.count; i++){
        var service = serviceModel.get(i);
        if(service.file === file) {
            service.online = ids.includes(service.name);
            console.log("service:", service.name, "online:", service.online);
            if (service.online) {
                console.log("calling getPublicPorts for", service.name);
                var ports = process.getPublicPorts(file, service.name);
                console.log("getPublicPorts returned:", ports, "type:", typeof ports);
                service.port = ports;
            } else {
                service.port = "";
            }
            console.log("service.port is now:", service.port);
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

