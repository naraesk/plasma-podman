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

#include "process.h"
#include <KIO/OpenUrlJob>
#include <KIO/JobUiDelegateFactory>
#include <QUrl>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QTextStream>
#include "docker.h"

static void debugLog(const QString &msg) {
    QFile file("/tmp/podman-debug.log");
    file.open(QIODevice::Append | QIODevice::Text);
    QTextStream out(&file);
    out << msg << "\n";
}


Process::Process(QObject *parent) : QProcess(parent) {
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
        // Re-add the file since some editors replace files (remove + create)
        if (!m_watcher.files().contains(path)) {
            m_watcher.addPath(path);
        }
        emit composeFileChanged(path);
    });
}

Process::~Process() {
}

void Process::watchFile(const QString &path) {
    if (!m_watcher.files().contains(path)) {
        m_watcher.addPath(path);
    }
}

void Process::startStack(const QString &file) {
    QStringList arguments;
    arguments << "up" << "-d";
    runPodmanCompose(file, arguments);
}

void Process::stopStack(const QString &file) {
    QStringList arguments;
    arguments << "stop";
    runPodmanCompose(file, arguments);
}

void Process::startService(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments  << "up" << "-d" << serviceName;
    runPodmanCompose(file, arguments);
}

void Process::stopService(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments << "stop" << serviceName;
    runPodmanCompose(file, arguments);
}

void Process::restartService(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments << "restart" << serviceName;
    runPodmanCompose(file, arguments);
}

QStringList Process::getServices(const QString &file) {
    QStringList arguments;
    arguments << "config" << "--services";
    runPodmanCompose(file, arguments);
    waitForFinished();
    QString composeOutput(readAllStandardOutput());
    return composeOutput.split("\n", Qt::SkipEmptyParts);
}

QStringList Process::getRunningServices(const QString &file) {
    debugLog("getRunningServices called for file: " + file);
    QStringList arguments;
    arguments << "ps"
              << "--filter" << "label=com.docker.compose.project.config_files=" + file
              << "--filter" << "status=running"
              << "--format" << "{{index .Labels \"com.docker.compose.service\"}}";
    runPodman(arguments);
    waitForFinished();
    QString podmanOutput(readAllStandardOutput());
    debugLog("running services: " + podmanOutput.trimmed());
    return podmanOutput.split("\n", Qt::SkipEmptyParts);
}

void Process::runPodmanCompose(const QString &file, const QStringList &arguments) {
    QStringList allArguments;
    allArguments << "compose" << "-f" << file << arguments;
    start("podman", allArguments);
}

void Process::runPodman(const QStringList &arguments) {
    start("podman", arguments);
}

void Process::showLog(const QString &file) {
    QStringList arguments;
    arguments << "--noclose"
              << "-e"
              << "podman"
              << "compose"
              << "-f" << file
              << "logs" << "-f";
    start("konsole", arguments);
}

void Process::showServiceLog(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments << "--noclose"
              << "-e"
              << "podman"
              << "compose"
              << "-f" << file
              << "logs" << "-f" << serviceName;
    start("konsole", arguments);
}

void Process::runShell(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments << "--noclose"
              << "-e"
              << "podman"
              << "compose"
              << "-f" << file
              << "exec"
              << serviceName
              << "sh";
    start("konsole", arguments);
}

void Process::startBrowser(const QString &file, const QString &serviceName) {
    QString ports = getPublicPorts(file, serviceName);
    QStringList portList = ports.split(", ", Qt::SkipEmptyParts);
    for (const QString &port : portList) {
        const QUrl url("http://localhost:" + port.trimmed());
        auto *job = new KIO::OpenUrlJob(url);
        job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
        job->start();
    }
}

QString Process::getContainerID(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments << "ps" << "-q"
              << "--filter" << "label=com.docker.compose.project.config_files=" + file
              << "--filter" << "label=com.docker.compose.service=" + serviceName
              << "--filter" << "status=running";
    runPodman(arguments);
    waitForFinished();
    QString podmanOutput(readAllStandardOutput());
    return podmanOutput.trimmed();
}

bool Process::isPublic(const QString &file, const QString serviceName) {
    QStringList arguments;
    arguments << "ps" << serviceName;
    runPodmanCompose(file, arguments);
    waitForFinished();
    QString composeOutput(readAllStandardOutput());
    return composeOutput.contains("->");
}

QString Process::getPublicPorts(const QString &file, const QString &serviceName) {
    debugLog("getPublicPorts called for " + serviceName + " file: " + file);

    // Try runtime port mappings first (works for bridge networking)
    QString containerID = getContainerID(file, serviceName);
    debugLog("containerID: " + containerID);
    if (!containerID.isEmpty()) {
        QStringList arguments;
        arguments << "port" << containerID;
        runPodman(arguments);
        waitForFinished();
        QString podmanOutput(readAllStandardOutput());
        debugLog("podman port output: " + podmanOutput);
        QStringList ports = podmanOutput.split("\n", Qt::SkipEmptyParts);
        QStringList hostPorts;
        for (const QString &port : ports) {
            QString hostPart = port.section("->", 1, 1).trimmed();
            QString hostPort = hostPart.section(":", -1);
            if (!hostPort.isEmpty()) {
                hostPorts << hostPort;
            }
        }
        if (!hostPorts.isEmpty()) {
            QString result = hostPorts.join(", ");
            debugLog("returning runtime ports: " + result);
            return result;
        }
    }

    // Fallback 1: parse compose config for declared ports
    debugLog("runtime ports empty, falling back to compose config");
    QStringList configArgs;
    configArgs << "config";
    runPodmanCompose(file, configArgs);
    waitForFinished();
    QString configOutput(readAllStandardOutput());
    debugLog("compose config output (first 500): " + configOutput.left(500));
    QString result = parsePublishedPorts(configOutput, serviceName);
    debugLog("parsed ports result: " + result);
    if (!result.isEmpty()) {
        return result;
    }

    // Fallback 2: inspect container for exposed ports (for network_mode: host with no ports: section)
    if (!containerID.isEmpty()) {
        debugLog("compose config had no ports, falling back to container inspect");
        QStringList inspectArgs;
        inspectArgs << "inspect" << "--format" << "{{json .Config.ExposedPorts}}" << containerID;
        runPodman(inspectArgs);
        waitForFinished();
        QString inspectOutput(readAllStandardOutput());
        debugLog("inspect ExposedPorts output: " + inspectOutput);
        result = parseExposedPorts(inspectOutput.trimmed());
        debugLog("parsed exposed ports: " + result);
    }
    return result;
}

QString Process::parsePublishedPorts(const QString &configOutput, const QString &serviceName) {
    QStringList lines = configOutput.split("\n");
    QStringList hostPorts;
    bool inService = false;
    bool inPorts = false;
    int serviceIndent = -1;
    int portsIndent = -1;

    for (const QString &line : lines) {
        if (line.trimmed().isEmpty()) continue;

        int indent = 0;
        while (indent < line.length() && line[indent] == ' ') indent++;

        if (inService && indent <= serviceIndent) {
            debugLog("left service section at line: " + line);
            break;
        }

        if (!inService && line.trimmed() == serviceName + ":") {
            inService = true;
            serviceIndent = indent;
            debugLog("found service " + serviceName + " at indent " + QString::number(indent));
            continue;
        }

        if (inService) {
            // Leave ports section when we hit a non-list-item at same or lower indent
            if (inPorts && indent <= portsIndent && !line.trimmed().startsWith("- ")) {
                debugLog("left ports section at line: " + line);
                inPorts = false;
            }

            if (!inPorts && line.trimmed() == "ports:") {
                inPorts = true;
                portsIndent = indent;
                debugLog("found ports: at indent " + QString::number(indent));
                continue;
            }

            if (inPorts) {
                QString trimmed = line.trimmed();
                debugLog("ports line: " + trimmed);

                // Long format: published: "8081"
                if (trimmed.startsWith("published:")) {
                    QString value = trimmed.mid(10).trimmed();
                    value.remove('"');
                    debugLog("found published port (long): " + value);
                    if (!value.isEmpty()) {
                        hostPorts << value;
                    }
                }
                // Short format: - 8081:8080 or - "8081:8080"
                else if (trimmed.startsWith("- ")) {
                    QString value = trimmed.mid(2).trimmed();
                    value.remove('"');
                    value.remove('\'');
                    // Extract host port (part before first colon)
                    QString hostPort = value.section(':', 0, 0);
                    debugLog("found published port (short): " + hostPort);
                    if (!hostPort.isEmpty()) {
                        hostPorts << hostPort;
                    }
                }
            }
        }
    }
    return hostPorts.join(", ");
}

QString Process::parseExposedPorts(const QString &inspectOutput) {
    // Parses JSON like {"8080/tcp":{},"9090/tcp":{}} from podman inspect
    QStringList ports;
    QString input = inspectOutput;
    input.remove('{').remove('}');
    QStringList entries = input.split(",", Qt::SkipEmptyParts);
    for (const QString &entry : entries) {
        // Each entry looks like "8080/tcp":{}
        QString key = entry.section(':', 0, 0).trimmed();
        key.remove('"');
        QString port = key.section('/', 0, 0);
        if (!port.isEmpty()) {
            ports << port;
        }
    }
    return ports.join(", ");
}

void Process::pullImages(const QString &file) {
    QStringList arguments;
    arguments << "pull";
    runPodmanCompose(file, arguments);
}

QString Process::getServiceImage(const QString &file, const QString &serviceName) {
    QStringList configArgs;
    configArgs << "config";
    runPodmanCompose(file, configArgs);
    waitForFinished();
    QString configOutput(readAllStandardOutput());

    QStringList lines = configOutput.split("\n");
    bool inService = false;
    int serviceIndent = -1;

    for (const QString &line : lines) {
        if (line.trimmed().isEmpty()) continue;

        int indent = 0;
        while (indent < line.length() && line[indent] == ' ') indent++;

        if (inService && indent <= serviceIndent) {
            break;
        }

        if (!inService && line.trimmed() == serviceName + ":") {
            inService = true;
            serviceIndent = indent;
            continue;
        }

        if (inService && line.trimmed().startsWith("image:")) {
            QString image = line.trimmed().mid(6).trimmed();
            image.remove('"');
            image.remove('\'');
            return image;
        }
    }
    return QString();
}

void Process::editFile(const QString &file) {
    auto *job = new KIO::OpenUrlJob(QUrl::fromLocalFile(file));
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->start();
}

void Process::openDirectory(const QString &path) {
    auto *job = new KIO::OpenUrlJob(QUrl::fromLocalFile(path));
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->start();
}

QStringList Process::getServiceVolumes(const QString &file, const QString &serviceName) {
    QStringList configArgs;
    configArgs << "config";
    runPodmanCompose(file, configArgs);
    waitForFinished();
    QString configOutput(readAllStandardOutput());

    QStringList lines = configOutput.split("\n");
    QStringList volumes;
    bool inService = false;
    bool inVolumes = false;
    bool inLongSyntax = false;
    int serviceIndent = -1;
    int volumesIndent = -1;
    int longSyntaxIndent = -1;
    QString longSource;
    QString longTarget;
    QString longType;
    QDir composeDir = QFileInfo(file).absoluteDir();

    for (const QString &line : lines) {
        if (line.trimmed().isEmpty()) continue;

        int indent = 0;
        while (indent < line.length() && line[indent] == ' ') indent++;

        if (inService && indent <= serviceIndent) {
            break;
        }

        if (!inService && line.trimmed() == serviceName + ":") {
            inService = true;
            serviceIndent = indent;
            continue;
        }

        if (inService) {
            if (inVolumes && indent <= volumesIndent && !line.trimmed().startsWith("- ")) {
                inVolumes = false;
                inLongSyntax = false;
            }

            if (!inVolumes && line.trimmed() == "volumes:") {
                inVolumes = true;
                volumesIndent = indent;
                continue;
            }

            if (inVolumes) {
                QString trimmed = line.trimmed();

                // Detect start of a new list item in long syntax
                if (trimmed.startsWith("- ") && !trimmed.contains(":")) {
                    // Flush previous long syntax entry
                    if (inLongSyntax && !longSource.isEmpty() && !longTarget.isEmpty()) {
                        if (longType.isEmpty() || longType == "bind") {
                            if (longSource.startsWith("/") || longSource.startsWith(".")) {
                                QString resolved = longSource.startsWith(".")
                                    ? QDir::cleanPath(composeDir.absoluteFilePath(longSource))
                                    : longSource;
                                volumes << resolved + "::" + longTarget;
                            }
                        }
                    }
                    inLongSyntax = true;
                    longSyntaxIndent = indent;
                    longSource.clear();
                    longTarget.clear();
                    longType.clear();
                    // The "- " line itself might have a key, e.g. "- source: ..."
                    QString after = trimmed.mid(2).trimmed();
                    if (after.startsWith("source:")) {
                        longSource = after.mid(7).trimmed();
                        longSource.remove('"').remove('\'');
                    } else if (after.startsWith("target:")) {
                        longTarget = after.mid(7).trimmed();
                        longTarget.remove('"').remove('\'');
                    } else if (after.startsWith("type:")) {
                        longType = after.mid(5).trimmed();
                        longType.remove('"').remove('\'');
                    }
                    continue;
                }

                // Long syntax continuation keys
                if (inLongSyntax && indent > longSyntaxIndent) {
                    if (trimmed.startsWith("source:")) {
                        longSource = trimmed.mid(7).trimmed();
                        longSource.remove('"').remove('\'');
                    } else if (trimmed.startsWith("target:")) {
                        longTarget = trimmed.mid(7).trimmed();
                        longTarget.remove('"').remove('\'');
                    } else if (trimmed.startsWith("type:")) {
                        longType = trimmed.mid(5).trimmed();
                        longType.remove('"').remove('\'');
                    }
                    continue;
                }

                // Short syntax: - ./data:/app/data or - /host/path:/container/path
                if (trimmed.startsWith("- ")) {
                    // Flush previous long syntax entry if any
                    if (inLongSyntax && !longSource.isEmpty() && !longTarget.isEmpty()) {
                        if (longType.isEmpty() || longType == "bind") {
                            if (longSource.startsWith("/") || longSource.startsWith(".")) {
                                QString resolved = longSource.startsWith(".")
                                    ? QDir::cleanPath(composeDir.absoluteFilePath(longSource))
                                    : longSource;
                                volumes << resolved + "::" + longTarget;
                            }
                        }
                    }
                    inLongSyntax = false;

                    QString value = trimmed.mid(2).trimmed();
                    value.remove('"').remove('\'');

                    int colonPos = value.indexOf(':');
                    if (colonPos > 0) {
                        QString hostPath = value.left(colonPos);
                        // Remaining part after first colon may have :ro or :rw suffix
                        QString rest = value.mid(colonPos + 1);
                        QString containerPath = rest.section(':', 0, 0);

                        if (hostPath.startsWith("/") || hostPath.startsWith(".")) {
                            QString resolved = hostPath.startsWith(".")
                                ? QDir::cleanPath(composeDir.absoluteFilePath(hostPath))
                                : hostPath;
                            volumes << resolved + "::" + containerPath;
                        }
                    }
                }
            }
        }
    }

    // Flush final long syntax entry
    if (inLongSyntax && !longSource.isEmpty() && !longTarget.isEmpty()) {
        if (longType.isEmpty() || longType == "bind") {
            if (longSource.startsWith("/") || longSource.startsWith(".")) {
                QString resolved = longSource.startsWith(".")
                    ? QDir::cleanPath(composeDir.absoluteFilePath(longSource))
                    : longSource;
                volumes << resolved + "::" + longTarget;
            }
        }
    }

    return volumes;
}

// show all public avaible containers
// podman ps --format "{{.ID}}@@{{.Ports}}"
