add_custom_target(Cm
    SOURCES
        CmConfig.cmake
        CmMacros.cmake
        CmInstall.cmake
        CmUtils.cmake
        CmInternals.cmake
        CmQt.cmake
        CmQtCore.cmake
        CmQtGui.cmake
        CmQtQuick.cmake
        CmQtWidgets.cmake
        CmQtLinguist.cmake
)

set(VERSION_FILE ${CMAKE_BINARY_DIR}/lib/cmake/Cm/CmConfigVersion.cmake)
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${VERSION_FILE}
    VERSION       ${Cm_VERSION}
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

if (ANDROID)
    target_sources(Cm PRIVATE CmAndroidSupport.cmake)
elseif (EMSCIPTEN)
    target_sources(Cm PRIVATE CmWasmSupport.cmake)
endif()

get_target_property(SOURCES Cm SOURCES)
list(APPEND SOURCES ${VERSION_FILE})

set(DESTINATION lib/cmake/Cm)
file(COPY ${SOURCES} DESTINATION ${CMAKE_BINARY_DIR}/${DESTINATION})
install(FILES ${SOURCES} DESTINATION ${DESTINATION})
