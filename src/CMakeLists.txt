include(CMakePackageConfigHelpers)

set(ROOT ".")

configure_package_config_file(CmConfig.cmake.in
    ${CMAKE_CURRENT_SOURCE_DIR}/CmConfig.cmake
    INSTALL_DESTINATION ${CM_INSTALL_PATH}
    PATH_VARS ROOT
)

#write_basic_package_version_file(
#    ${CMAKE_CURRENT_SOURCE_DIR}/CmConfigVersion.cmake
#    VERSION       ${Cm_VERSION}
#    COMPATIBILITY AnyNewerVersion
#    ARCH_INDEPENDENT
#)

add_custom_target(cm
    SOURCES
        CmConfig.cmake
        CmConfigVersion.cmake
        CmMacros.cmake
        CmTargetsMacros.cmake
        CmUtils.cmake
        CmInternals.cmake
)

get_target_property(SOURCES cm SOURCES)
file(COPY ${SOURCES} DESTINATION ${CM_ROOT_PATH})
install(FILES ${SOURCES} DESTINATION ${CM_INSTALL_PATH})
