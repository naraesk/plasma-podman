set(plasmoidplugin_SRCS
    plugin.cpp
    process.cpp
    )

find_package(KF6 REQUIRED COMPONENTS KIO)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_link_libraries(plasmoidplugin Qt6::Quick KF6::KIOCore KF6::KIOWidgets)

install(TARGETS plasmoidplugin DESTINATION ${KDE_INSTALL_QMLDIR}/eu/naraesk/podman/process)

install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/eu/naraesk/podman/process)
