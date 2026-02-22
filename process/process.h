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

#ifndef PROCESS_H
#define PROCESS_H

#include <QProcess>
#include <QString>

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

public Q_SLOTS:
    void startStack(const QString &file);
    void stopStack(const QString &file);
    void startService(const QString &file, const QString &serviceName);
    void stopService(const QString &file, const QString &serviceName);
    QStringList getServices(const QString &file);
    QStringList getRunningServices(const QString &file);
    void showLog(const QString& file);
    void runShell(const QString &file, const QString &serviceName);
    void startBrowser(const QString &file, const QString &serviceName);
    bool isPublic(const QString &file, const QString serviceName);
    void editFile(const QString &file);
};

#endif // PROCESS_H
