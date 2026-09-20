# plasma-podman

KDE Plasma 6 widget for controlling Podman Compose stacks from the system tray.

## Build & Install

```bash
./install.sh  # builds, installs, and restarts plasmashell
```

This runs cmake + make, installs with sudo, then restarts plasmashell via `kquitapp6 plasmashell && kstart plasmashell`.

This command should always be run by the user and not by Claude.

## Project Structure

- `plasmoid/` - QML widget package
  - `contents/ui/main.qml` - Entry point, `PlasmoidItem` with compact/full representations
  - `contents/ui/FullRepresentation.qml` - Main widget UI, loads services via `model.js`
  - `contents/ui/CompactRepresentation.qml` - Tray icon
  - `contents/ui/model.js` - Service loading logic, reads config and calls `process.getServices()`
  - `contents/ui/config/Config.qml` - Configuration dialog for adding compose file stacks
  - `contents/config/main.xml` - KConfig schema (defines `container` as `StringList`)
  - `contents/config/config.qml` - ConfigModel defining config categories
  - `metadata.json` - Plugin metadata (id: `eu.naraesk.podman-control`)
- `process/` - C++ backend plugin (`eu.naraesk.podman.process 1.2`)
  - `process.h` / `process.cpp` - QProcess wrapper for podman compose commands
  - Podman operations: start/stop stacks and services, get services, show logs, run shells

## Key Architecture Details

- Configuration stores compose stacks as a `StringList` of JSON objects: `{"service":"<name>","dir":"<path>"}`
- Config dialog uses `cfg_container` property for Plasma's auto-binding config mechanism
- `model.js:loadServices()` reads config, calls `process.getServices(file)` for each stack, populates the `serviceModel`
- `FullRepresentation.qml` listens for `plasmoid.configuration.onContainerChanged` to reload services

## Common Pitfalls

- **QML array property changes**: Mutating arrays in-place (`push`, `splice`) does NOT trigger QML property change signals. Always create a copy with `.slice()`, modify the copy, then reassign: `cfg_container = modifiedCopy`
- **Podman Compose behavior**: `podman compose config --services` lists all defined services. `podman compose ps --services` only lists services with existing containers.
- **Config dialog layout**: Avoid putting `ListView` (scrollable) inside `Kirigami.FormLayout` in Plasma 6 config pages — it causes layout sizing conflicts. Use `Repeater` inside a `ColumnLayout` instead, with `Kirigami.FormLayout` as a child for just the form fields.
- **Process commands**: `runPodmanCompose()` in process.cpp invokes `podman compose` (compose as a subcommand of podman). `Process` is a plain QObject, not a QProcess: every command gets its own child QProcess. Use `runPodman()`/`runPodmanCompose()` to fire and forget (completion is reported by the `commandFinished(exitCode)` signal — QML binds `onCommandFinished`, **not** `onFinished`), and `queryPodman()`/`queryPodmanCompose()` when the output is read back. Never share one QProcess across commands: `start()` on a running QProcess is a no-op that silently drops the command and hands back the previous one's output.
- **Startup latency**: `podman compose up -d` contacts the registry on every start, so a service can take ~60s to appear even when the image is local. The UI must not rely on polling alone to notice — `ServiceDelegate` refreshes on `commandFinished` and shows a `BusyIndicator` while a toggle is in flight.
- **`podman ps --format`**: `.Labels` is a flat list in the Go template context, so `{{index .Labels "..."}}` fails with `cannot index slice/array with type string`. Use `--format json` and parse it instead. (`podman inspect --format` is unaffected — there `.Config.Labels` is a real map.)
- **C++ plugin link libraries**: The `process/` plugin only uses Qt and KIO — do NOT add `Plasma::Plasma` to its `target_link_libraries`. The top-level `find_package(Plasma)` is needed for `plasma_install_package()`, but the plugin itself has no Plasma C++ dependency. Adding it causes a runtime `libPlasma.so.6` load failure.
