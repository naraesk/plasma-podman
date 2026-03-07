# Plasma Podman Control

A KDE Plasma 6 widget for controlling Podman Compose stacks from the system tray.

![Screenshot](../../wiki/screenshots/ui%20v2.2.0.png)

### Features
* show status of container (with some delay)
* start and stop services (`podman compose up SERVICE` and `podman compose stop SERVICE`)
* start shell for services (`podman compose exec SERVICE sh`)
* open public port in browser
* edit compose file in default text editor
* show log files (`podman compose logs`)

## Installation

Please install Podman and podman-compose. Most distributions should provide packages for them. Then, run `install.sh` to install the plasmoid or run the following commands manually.

1. `mkdir build && cd build`
2. ``cmake -DCMAKE_INSTALL_PREFIX=`qmake6 -query QT_INSTALL_PREFIX` -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib ../``
3. `make`
4. `sudo make install`
5. `kquitapp6 plasmashell`
6. `kstart plasmashell`
