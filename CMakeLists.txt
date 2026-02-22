cmake_minimum_required(VERSION 3.16)

project(podman-control)

# Use Extra CMake Modules (ECM) for common functionality.
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_MODULE_PATH})

set(QT_MAJOR_VERSION 6)
set(QT_DEFAULT_MAJOR_VERSION 6)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
find_package(Qt6 REQUIRED COMPONENTS Quick Qml)
find_package(KF6 REQUIRED COMPONENTS KIO)
find_package(Plasma REQUIRED)

add_subdirectory(process)

# Add installation target ("make install").
plasma_install_package(plasmoid eu.naraesk.podman-control)
