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

#ifndef PROCESS_H
#define PROCESS_H

#include <QProcess>
#include <QString>
#include <QStringList>
#include <QFileSystemWatcher>

class Process : public QProcess
{
    Q_OBJECT
public:
    Process( QObject *parent = nullptr);
    ~Process();

private:
    void runPodmanCompose(const QString &file, const QStringList &arguments);
    void runPodman(const QStringList &arguments);
    QString getContainerID(const QString &file, const QString &serviceName);
    QString parsePublishedPorts(const QString &configOutput, const QString &serviceName);
    QString parseExposedPorts(const QString &inspectOutput);
    QStringList getServiceNamedVolumes(const QString &file, const QString &serviceName);
    QString getComposeProjectName(const QString &file);
    QFileSystemWatcher m_watcher;

Q_SIGNALS:
    void composeFileChanged(const QString &path);

public Q_SLOTS:
    void watchFile(const QString &path);
    void startService(const QString &file, const QString &serviceName);
    void stopService(const QString &file, const QString &serviceName);
    void restartService(const QString &file, const QString &serviceName);
    QStringList getServices(const QString &file);
    QStringList getRunningServices(const QString &file);
    void showLog(const QString& file);
    void showServiceLog(const QString &file, const QString &serviceName);
    void runShell(const QString &file, const QString &serviceName);
    void startBrowser(const QString &file, const QString &serviceName);
    QString getPublicPorts(const QString &file, const QString &serviceName);
    void editFile(const QString &file);
    void openDirectory(const QString &path);
    void pullImages(const QString &file);
    void recreateStack(const QString &file);
    QString getServiceImage(const QString &file, const QString &serviceName);
    QStringList getServiceVolumes(const QString &file, const QString &serviceName);
    void deleteServiceVolumes(const QString &file, const QString &serviceName);
};

#endif // PROCESS_H
