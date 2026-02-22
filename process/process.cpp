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
#include "docker.h"


Process::Process(QObject *parent) : QProcess(parent) {
}

Process::~Process() {
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

QStringList Process::getServices(const QString &file) {
    QStringList arguments;
    arguments << "config" << "--services";
    runPodmanCompose(file, arguments);
    waitForFinished();
    QString composeOutput(readAllStandardOutput());
    return composeOutput.split("\n", Qt::SkipEmptyParts);
}

QStringList Process::getRunningServices(const QString &file) {
    QStringList arguments;
    arguments << "ps" << "--services" << "--filter" << "status=running";
    runPodmanCompose(file, arguments);
    waitForFinished();
    QString composeOutput(readAllStandardOutput());
    return composeOutput.split("\n", Qt::SkipEmptyParts);
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
    QString containerID = getContainerID(file, serviceName);
    QStringList arguments;
    arguments << "port" << containerID;
    runPodman(arguments);
    waitForFinished();
    QString podmanOutput(readAllStandardOutput());
    QStringList ports = podmanOutput.split("\n", Qt::SkipEmptyParts);
    for (const QString &port : ports) {
        const QString f = port.section("->", 1, 1);
        const QUrl url("http://" + f.trimmed());
        auto *job = new KIO::OpenUrlJob(url);
        job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
        job->start();
    }

    QString go = List();
    qDebug() << "go:" << go;
}

QString Process::getContainerID(const QString &file, const QString &serviceName) {
    QStringList arguments;
    arguments << "ps" << "-q" << serviceName;
    runPodmanCompose(file, arguments);
    waitForFinished();
    QString composeOutput(readAllStandardOutput());
    return composeOutput.trimmed();
}

bool Process::isPublic(const QString &file, const QString serviceName) {
    QStringList arguments;
    arguments << "ps" << serviceName;
    runPodmanCompose(file, arguments);
    waitForFinished();
    QString composeOutput(readAllStandardOutput());
    return composeOutput.contains("->");
}

void Process::editFile(const QString &file) {
    auto *job = new KIO::OpenUrlJob(QUrl::fromLocalFile(file));
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->start();
}

// show all public avaible containers
// podman ps --format "{{.ID}}@@{{.Ports}}"
