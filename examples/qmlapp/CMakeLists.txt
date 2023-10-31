cm_add_executable(qmlapp main.cpp qml.qrc)

set_target_properties(qmlapp PROPERTIES
    ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
    ANDROID_BUILD_AAB          FALSE
    ANDROID_VERSION_NAME "2.3"
    ANDROID_VERSION 17
)

target_link_libraries(qmlapp PRIVATE Qt5::Quick)

copy_install(TARGETS qmlapp RUNTIME DESTINATION bin)
