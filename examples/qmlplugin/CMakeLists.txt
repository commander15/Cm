cm_add_plugin(qmlplugin
    NAME    QmlPlugin
    VERSION 1.0
    CPP_SOURCES
        cmplugin.cpp
    QML_SOURCES
        CmLabel.qml
        CmText.qml
)

target_link_libraries(qmlplugin PRIVATE Qt5::Qml)

cm_install(TARGETS qmlplugin
    RUNTIME DESTINATION qml/QmlPlugin
)
