### Package

function(cm_add_package name)
    set(options)
    set(oneValueArgs NAME VERSION CONFIG_FILE)
    set(multiValueArgs EXPORTS SOURCES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARG_NAME)
        set(ARG_NAME ${name})
    endif()

    if (NOT ARG_VERSION)
        set(ARG_VERSION ${${PROJECT_NAME}_VERSION})
    endif()

    if (NOT ARG_CONFIG_FILE)
        if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${ARG_NAME}Config.cmake)
            file(WRITE ${ARG_NAME}Config.cmake "# Let's build an awesome CMake Package !")
        endif()
        set(ARG_CONFIG_FILE ${ARG_NAME}Config.cmake)
    endif()

    add_custom_target(${name}
        SOURCES
            ${ARG_CONFIG_FILE}
            ${ARG_SOURCES}
    )

    set_target_properties(${name} PROPERTIES
        PACKAGE_NAME "${ARG_NAME}"
        VERSION      "${ARG_VERSION}"
        CONFIG_FILE  "${ARG_CONFIG_FILE}"
        EXPORTS      "${ARG_EXPORTS}"
    )

    cm_register_target(${name} PACKAGE)
endfunction()

function(cm_make_package package)
    set(options)
    set(oneValueArgs DIRECTORY DESTINATION FILES_VAR EXPORTS_VAR)
    set(multivalueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_target_property(NAME    ${package} PACKAGE_NAME)
    get_target_property(VERSION ${package} VERSION)
    get_target_property(CONFIG  ${package} CONFIG_FILE)

    set(ROOT ".")

    set(PKG_CONFIG_FILE_TEMPLATE ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_pkg/${NAME}Config.cmake.in)

    set(PKG_DIR         ${ARG_DIRECTORY})
    set(PKG_CONFIG_FILE ${PKG_DIR}/${NAME}Config.cmake)
    set(PKG_VER_FILE    ${PKG_DIR}/${NAME}ConfigVersion.cmake)
    file(READ ${CONFIG} PKG_CONFIG_CONTENT)
    file(WRITE ${PKG_CONFIG_FILE_TEMPLATE} "@PACKAGE_INIT@\nset(${NAME}_ROOT \"@PACKAGE_ROOT@\")\n\n@PKG_CONFIG_CONTENT@")

    include(CMakePackageConfigHelpers)

    configure_package_config_file(
        ${PKG_CONFIG_FILE_TEMPLATE} ${PKG_CONFIG_FILE}
        INSTALL_DESTINATION ${ARG_DESTINATION}
        PATH_VARS           ROOT
    )

    write_basic_package_version_file(
        ${PKG_VER_FILE}
        VERSION       ${VERSION}
        COMPATIBILITY AnyNewerVersion
        ARCH_INDEPENDENT
    )

    get_target_property(SOURCES ${package} SOURCES)
    list(REMOVE_AT SOURCES 0)
    set(${ARG_FILES_VAR} "${PKG_CONFIG_FILE};${PKG_VER_FILE};${SOURCES}" PARENT_SCOPE)

    get_target_property(EXPORTS ${package} EXPORTS)
    set(${ARG_EXPORTS_VAR} ${EXPORTS} PARENT_SCOPE)
endfunction()

function(cm_generate_package package)
    set(options)
    set(oneValueArgs DESTINATION)
    set(multivalueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_target_property(NAME ${package} PACKAGE_NAME)

    cm_make_package(${package}
        DIRECTORY   "${CMAKE_BINARY_DIR}/lib/cmake/${NAME}"
        DESTINATION "${ARG_DESTINATION}"
        FILES_VAR   FILES
        EXPORTS_VAR EXPORTS
    )

    set(DESTINATION ${CMAKE_BINARY_DIR}/${ARG_DESTINATION}/${NAME})

    file(COPY ${FILES} DESTINATION ${DESTINATION})

    foreach (export ${EXPORTS})
        export(EXPORT ${export} NAMESPACE ${NAME}:: FILE ${DESTINATION}/${export}.cmake)
    endforeach()
endfunction()

function(cm_install_package package)
    set(options)
    set(oneValueArgs DESTINATION)
    set(multivalueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_target_property(NAME ${package} PACKAGE_NAME)

    cm_make_package(${package}
        DIRECTORY   "${CMAKE_CURRENT_BINARY_DIR}/${NAME}_pkg"
        DESTINATION "${ARG_DESTINATION}/${NAME}"
        FILES_VAR   FILES
        EXPORTS_VAR EXPORTS
    )

    set(DESTINATION ${ARG_DESTINATION}/${NAME})

    install(FILES ${FILES} DESTINATION ${DESTINATION})

    foreach (export ${EXPORTS})
        install(EXPORT ${export} NAMESPACE ${NAME}:: DESTINATION ${DESTINATION})
    endforeach()
endfunction()

### Executable

function(cm_add_executable name)
    qt_add_executable(${name} ${ARGN})
    cm_register_target(${name} EXECUTABLE)
endfunction()

function(cm_generate_executable executable)
    cm_generate_target(${executable} ${ARGN})
endfunction()

function(cm_install_executable executable)
    install(TARGETS ${executable} ${ARGN})
endfunction()

### Library

function(cm_add_library name)
    qt_add_library(${name} ${ARGN})
    cm_register_target(${name} LIBRARY)
endfunction()

function(cm_generate_library library)
    cm_generate_target(${library} ${ARGN})
    cm_message(WARNING "library generation is in tech preview and may not work properly.")
endfunction()

function(cm_install_library library)
    install(TARGETS ${library} ${ARGN})
endfunction()

### Plugin

function(cm_add_plugin name)
    qt_add_plugin(${name} ${ARGN})
    cm_register_target(${name} PLUGIN)
endfunction()

function(cm_generate_plugin plugin)
    cm_message(WARNING "plugin generation is in tech preview and may not work properly")
endfunction()

function(cm_install_plugin plugin)
    set(options)
    set(oneValueArgs DESTINATION)
    set(multivalueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    install(TARGETS ${plugin}
        ${ARG_UNPARSED_ARGUMENTS}
        ARCHIVE DESTINATION ${ARG_DESTINATION}
        LIBRARY DESTINATION ${ARG_DESTINATION}
        RUNTIME DESTINATION ${ARG_DESTINATION}
    )
endfunction()

### Module (QML)

function(cm_add_module name)
    qt_add_qml_module(${name} ${ARGN})
    set_target_properties(${name} PROPERTIES AUTORCC OFF)
    cm_register_target(${name} MODULE)
endfunction()

function(cm_generate_module module)
    cm_message(WARNING "module generation is in tech preview and may not work")
endfunction()

function(cm_install_module module)
    set(options)
    set(oneValueArgs DESTINATION)
    set(multivalueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    install(TARGETS ${module}
        ${ARG_UNPARSED_ARGUMENTS}
        ARCHIVE DESTINATION ${ARG_DESTINATION}
        LIBRARY DESTINATION ${ARG_DESTINATION}
        RUNTIME DESTINATION ${ARG_DESTINATION}
    )

    qt_query_qml_module(${module}
        QMLDIR    QMLDIR_FILE
        TYPEINFO  TYPEINFO_FILE
        QML_FILES QML_SOURCES
    )

    install(FILES
        ${QMLDIR_FILE} ${TYPEINFO_FILE} ${QML_SOURCES}
        DESTINATION ${ARG_DESTINATION}
    )
endfunction()

### Headers Management

function(target_headers target)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs PUBLIC PRIVATE)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Adding public headers to the target
    if (ARG_PUBLIC)
        list(TRANSFORM ARG_PUBLIC PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)
        set_property(TARGET ${target} APPEND PROPERTY PUBLIC_HEADER ${ARG_PUBLIC})
    endif()

    # Adding private headers to the target
    if (ARG_PRIVATE)
        list(TRANSFORM ARG_PRIVATE PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)
        set_property(TARGET ${target} APPEND PROPERTY PRIVATE_HEADER ${ARG_PRIVATE})
    endif()
endfunction()

function(generate_target_headers target)
    set(options)
    set(oneValueArgs DESTINATION FOLDER)
    set(multiValueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARG_DESTINATION)
        set(ARG_DESTINATION ${CMAKE_BINARY_DIR}/include)
    endif()

    if (NOT ARG_FOLDER)
        set(destination ${ARG_DESTINATION})
    else()
        set(destination ${ARG_DESTINATION}/${ARG_FOLDER})
    endif()

    # Generating public headers on destination
    get_target_property(PUBLIC_HEADERS ${target} PUBLIC_HEADER)
    if (PUBLIC_HEADERS)
        cm_generate_nested_headers(${destination} ${PUBLIC_HEADERS})
    endif()

    # Generating private headers on destination
    get_target_property(PRIVATE_HEADERS ${target} PRIVATE_HEADER)
    if (PRIVATE_HEADERS)
        cm_generate_nested_headers(${destination}/private ${PRIVATE_HEADERS})
    endif()

    # Adding destination to target's include path
    target_include_directories(${target} PUBLIC $<BUILD_INTERFACE:${ARG_DESTINATION}>)
endfunction()

### Source Management

function(target_sources target)
    set(options NO_LINT NO_CACHEGEN NO_QMLDIR_TYPES)
    set(oneValueArgs PREFIX)
    set(multiValueArgs PUBLIC PRIVATE INTERFACE QML_FILES RESOURCES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (ARG_PUBLIC OR ARG_PRIVATE OR ARG_INTERFACE)
        set(SOURCES)
        set(INPUTS PUBLIC PRIVATE INTERFACE)

        foreach (source ${INPUTS})
            if (ARG_${source})
                list(APPEND SOURCES ${source} ${ARG_${source}})
            endif()
        endforeach()

        _target_sources(${target} ${SOURCES})
    endif()

    if (ARG_QML_FILES OR ARG_RESOURCES)
        set(QML_OPTIONS)
        set(QML_INPUTS QML_FILES RESOURCES PREFIX)

        foreach (name ${QML_INPUTS})
            if (ARG_${name})
                list(APPEND QML_OPTIONS ${name} ${ARG_${name}})
            endif()
        endforeach()

        foreach (option ${options})
            if (ARG_${option})
                list(APPEND QML_OPTIONS ${option})
            endif()
        endforeach()

        qt_target_qml_sources(${target} ${QML_OPTIONS})
    endif()
endfunction()

### Common

function(cm_generate_target target)
    list(REMOVE_ITEM ARGN DESTINATION EXPORT COMPONENT)

    set(options)
    set(oneValueArgs ARCHIVE LIBRARY RUNTIME PUBLIC_HEADER PRIVATE_HEADER)
    set(multiValueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set_target_properties(${target} PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${ARG_ARCHIVE}
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${ARG_LIBRARY}
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${ARG_RUNTIME}
    )
endfunction()

function(cm_install type)
    macro(extract_targets)
        unset(TARGETS)
        cm_log(INFO "${ARGN}")
        foreach (target ${ARGN})
            if (TARGET ${target})
                list(APPEND TARGETS ${target})
            else()
                break()
            endif()
        endforeach()
        cm_log(INFO "${ARGN}")
    endmacro()

    if (${type} STREQUAL PACKAGES)
        extract_targets(${ARGN})
        list(REMOVE_ITEM ARGN ${TARGETS})

        foreach (package ${TARGETS})
            if (CM_GENERATION)
                cm_generate_package(${package} ${ARGN})
            endif()
            cm_install_package(${package} ${ARGN})
        endforeach()
    elseif (${type} STREQUAL TARGETS)
        extract_targets(${ARGN})
        list(REMOVE_ITEM ARGN ${TARGETS})

        foreach (target ${TARGETS})
            get_target_property(TYPE ${target} CM_TYPE)
            string(TOLOWER ${TYPE} type)

            if (CM_GENERATION)
                cmake_language(CALL cm_generate_${type} ${target} ${ARGN})
            endif()
            cmake_language(CALL cm_install_${type} ${target} ${ARGN})
        endforeach()
    else()
        install(${type} ${ARGN})
    endif()
endfunction()
