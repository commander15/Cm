find_program(qmlplugindump qmlplugindump)

function(cm_initialize_target target type)
endfunction()

function(cm_finalize_target target type)
    if (${type} STREQUAL PLUGIN)
        get_target_property(QML ${target} QML_PLUGIN)
        if (QML AND NOT ANDROID)
            get_target_property(NAME ${target} PLUGIN_NAME)
            get_target_property(VERSION ${target} PLUGIN_VERSION)
            get_target_property(DIR ${target} LIBRARY_OUTPUT_DIRECTORY)

            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND
                    ${qmlplugindump} ${NAME} ${VERSION} ${DIR}/..
                        -output ${DIR}/${NAME}.qmltypes -v
            )
        endif()
    elseif (${type} STREQUAL LIBRARY)
        get_target_property(NAME ${target} OUTPUT_NAME)
        if (NOT NAME)
            set(NAME ${target})
        endif()
        string(TOUPPER ${NAME} NAME)

        get_target_property(TYPE ${target} TYPE)
        if (${TYPE} STREQUAL "STATIC_LIBRARY")
            set(BUILD "STATIC")
        elseif (${TYPE} STREQUAL "SHARED_LIBRARY")
            set(BUILD "SHARED")
        else()
            unset(BUILD)
        endif()

        target_compile_definitions(${target}
            PUBLIC
                ${NAME}_LIB ${NAME}_${BUILD}
            PRIVATE
                ${NAME}_LIB_BUILD
        )
    endif()
endfunction()

function(cm_register_target target type)
    set_target_properties(${target} PROPERTIES CM_TYPE ${type})

    cm_initialize_target(${target} ${type})
    cmake_language(EVAL CODE "cmake_language(DEFER CALL cm_finalize_target ${target} ${type})")
endfunction()

function(cm_message type)
    if (CM_MESSAGES)
        message(${type} "Cm: ${ARGN}")
    endif()
endfunction()

include(CMakePackageConfigHelpers)

function(cm_generate_package_config_file file)
    set(options)
    set(oneValueArgs NAME)
    set(multiValueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(FILE ${CMAKE_BINARY_DIR}/package/template.cmake.in)

    if (NOT EXISTS ${FILE} OR TRUE)
        file(WRITE ${FILE}
            [=[# @ARG_NAME@
              if (@ARG_NAME@_FOUND)
                  return()
              endif()

              set(FILES Macros Targets)
              foreach(file ${FILES})
                  set(FILE ${CMAKE_CURRENT_LIST_DIR}/@ARG_NAME@${file}.cmake)
                  if (EXISTS ${FILE})
                      include(${FILE})
                  endif()
              endforeach()

              foreach (Component ${@ARG_NAME@}_FIND_COMPONENTS)
                  set(FILE ${CMAKE_CURRENT_LIST_DIR}/@ARG_NAME@${Component}.cmake)
                  if (EXISTS ${FILE})
                      include(${FILE})
                  elseif (@ARG_NAME@_FIND_REQUIRED_${Component})
                      message(FATAL_ERROR "")
                  else()
                      message(WARNING "Cm")
                  endif()
              endforeach()
            ]=]
        )
    endif()

    configure_file(${FILE} ${file} @ONLY)
endfunction()

function(cm_generate_package_version_file file)
    write_basic_package_version_file(${file}
        ${ARGN}
        COMPATIBILITY AnyNewerVersion
        ARCH_INDEPENDENT
    )
endfunction()

function(cm_generate_qmldir_file file)
    set(options)
    set(oneValueArgs PLUGIN_NAME)
    set(multiValueArgs QML_SOURCES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    file(WRITE ${file}
        "module ${ARG_PLUGIN_NAME}"
    )
endfunction()
