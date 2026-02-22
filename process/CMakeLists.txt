add_subdirectory(go)

set(plasmoidplugin_SRCS
    plugin.cpp
    process.cpp
    docker.h
    )

add_library(testlib SHARED)
set_property(TARGET testlib PROPERTY IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/docker.so")

find_package(KF6 REQUIRED COMPONENTS KIO)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

add_dependencies(plasmoidplugin goshim)

target_link_libraries(plasmoidplugin Qt6::Quick Plasma::Plasma KF6::KIOCore KF6::KIOWidgets goshim pthread)

install(TARGETS plasmoidplugin DESTINATION ${KDE_INSTALL_QMLDIR}/eu/naraesk/podman/process)

install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/eu/naraesk/podman/process)
