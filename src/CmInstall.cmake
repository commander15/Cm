set(CM_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "")

function(cm_install type)
    set(options EXCLUDE_FROM_ALL OPTIONAL)
    set(oneValueArgs DESTINATION COMPONENT RENAME)
    set(multiValueArgs PERMISSIONS CONFIGURATIONS)
    unset(INSTALL_ARGS)

    if (${type} STREQUAL TARGETS)
        list(REMOVE_ITEM oneValueArgs DESTINATION)

        list(APPEND options)
        list(APPEND oneValueArgs PACKAGE)
        list(APPEND multiValueArgs TARGETS ARCHIVE LIBRARY RUNTIME PUBLIC_HEADER PRIVATE_HEADER)
        cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${type} ${ARGN})

        foreach (target ${ARG_TARGETS})
            if (ARG_PACKAGE)
                get_target_property(EXPORT ${ARG_PACKAGE} EXPORT_NAME)
                string(APPEND INSTALL_ARGS EXPORT ${EXPORT})
            endif()

            if (ARG_PUBLIC_HEADER)
                get_target_property(PUBLIC_HEADERS ${target} PUBLIC_HEADER)
                if (PUBLIC_HEADERS)
                    cm_message(INFO "Installing public headers of ${target} target...")
                    list(REMOVE_ITEM ARG_PUBLIC_HEADER DESTINATION)
                    cm_generate_nested_headers(${CM_INSTALL_PREFIX}/${ARG_PUBLIC_HEADER} ${PUBLIC_HEADERS})
                endif()
            endif()

            if (ARG_PRIVATE_HEADER)
                get_target_property(PRIVATE_HEADERS ${target} PRIVATE_HEADER)
                if (PRIVATE_HEADERS)
                    cm_message(INFO "Installing private headers of ${target} target...")
                    list(REMOVE_ITEM ARG_PRIVATE_HEADER DESTINATION)
                    cm_generate_nested_headers(${CM_INSTALL_PREFIX}/${ARG_PRIVATE_HEADER} ${PRIVATE_HEADERS})
                endif()
            endif()

            target_include_directories(${target}
                PUBLIC
                    $<BUILD_INTERFACE:${CM_INSTALL_PREFIX}/include>
                    $<INSTALL_INTERFACE:include>
            )

            function(extract_destination destination)
                set(options)
                set(oneValueArgs DESTINATION)
                set(multiValueArgs)
                cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
                if (ARG_DESTINATION)
                    set(${destination} ${ARG_DESTINATION} PARENT_SCOPE)
                else()
                    unset(${destination} PARENT_SCOPE)
                endif()
            endfunction()

            extract_destination(ARCHIVE_DESTINATION ${ARG_ARCHIVE})
            extract_destination(LIBRARY_DESTINATION ${ARG_LIBRARY})
            extract_destination(RUNTIME_DESTINATION ${ARG_RUNTIME})

            get_target_property(QML ${target} QML_PLUGIN)
            if (NOT ARG_LIBRARY AND QML)
                set(LIBRARY_DESTINATION ${RUNTIME_DESTINATION})
                list(APPEND INSTALL_ARGS LIBRARY DESTINATION ${RUNTIME_DESTINATION})
            endif()

            set_target_properties(${target} PROPERTIES
                ARCHIVE_OUTPUT_DIRECTORY ${CM_INSTALL_PREFIX}/${ARCHIVE_DESTINATION}
                LIBRARY_OUTPUT_DIRECTORY ${CM_INSTALL_PREFIX}/${LIBRARY_DESTINATION}
                RUNTIME_OUTPUT_DIRECTORY ${CM_INSTALL_PREFIX}/${RUNTIME_DESTINATION}
            )

            get_target_property(SOURCES ${target} QML_SOURCES)
            if (QML AND SOURCES)
                cm_install(FILES ${SOURCES} DESTINATION ${CM_INSTALL_PREFIX}/${RUNTIME_DESTINATION})
            endif()

            #extract_destination(PUBLIC_DESTINATION  ${ARG_PUBLIC_HEADER})
            #extract_destination(PRIVATE_DESTINATION ${ARG_PRIVATE_HEADER})
        endforeach()
    elseif (${type} STREQUAL DIRECTORY OR ${type} STREQUAL FILES)
        list(APPEND options)
        list(APPEND oneValueArgs)
        list(APPEND multiValueArgs FILES PROGRAMS)
        cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${type} ${ARGN})

        file(COPY ${ARG_FILES} ${ARG_PROGRAMS} DESTINATION ${ARG_DESTINATION})
    endif()

    string(JOIN " " INSTALL ${type} ${ARGN} ${INSTALL_ARGS})
    cm_message(INFO "install(${INSTALL}")

    install(${type} ${ARGN} ${INSTALL_ARGS})
endfunction()

set(CMAKE_COPY_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH
    "Copy path prefix, prepended onto copy directories"
)

function(configure_install input output)
    set(output_file ${CMAKE_COPY_PREFIX}/${output})
    configure_file(${input} ${output_file} ${ARGN})

    get_filename_component(path ${output} DIRECTORY)
    install(FILES ${output_file} DESTINATION ${path})
endfunction()

function(copy_install type)
    install(${type} ${ARGN})
    return()

    cm_message(INFO "Copying/Installing ${type}...")
    set(options EXCLUDE_FROM_ALL OPTIONAL)
    set(oneValueArgs COMPONENT RENAME)
    set(multiValueArgs CONFIGURATIONS PERMISSIONS)

    if (NOT CMAKE_COPY_PREFIX)
        if (NOT _CMAKE_COPY_WARNING_DISPLAYED)
            cm_message(WARNING "CMAKE_COPY_PREFIX not set, copying disabled")
            set(_CMAKE_COPY_WARNING_DISPLAYED TRUE)
        endif()
    elseif (type STREQUAL "EXPORT")
        list(APPEND options)
        list(APPEND oneValueArgs EXPORT NAMESPACE FILE DESTINATION)
        list(APPEND multiValueArgs)
        cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" EXPORT ${ARGN})
        export(EXPORT ${ARG_EXPORT} NAMESPACE ${ARG_NAMESPACE}
            FILE ${CMAKE_COPY_PREFIX}/${ARG_DESTINATION}/${ARG_FILE}
        )
    elseif (${type} STREQUAL "TARGETS")
        list(APPEND options NAMELINK_ONLY NAMELINK_SKIP)
        list(APPEND oneValueArgs EXPORT NAMELINK_COMPONENT)
        list(APPEND multiValueArgs TARGETS ARCHIVE LIBRARY RUNTIME PUBLIC_HEADER PRIVATE_HEADER)
        cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" TARGETS ${ARGN})

        function(extract_destination destination)
            set(options)
            set(oneValueArgs DESTINATION)
            set(multiValueArgs)
            cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
            if (ARG_DESTINATION)
                set(${destination} ${ARG_DESTINATION} PARENT_SCOPE)
            else()
                unset(${destination} PARENT_SCOPE)
            endif()
        endfunction()

        extract_destination(ARCHIVE_DESTINATION ${ARG_ARCHIVE})
        extract_destination(LIBRARY_DESTINATION ${ARG_LIBRARY})
        extract_destination(RUNTIME_DESTINATION ${ARG_RUNTIME})
        extract_destination(PUBLIC_DESTINATION  ${ARG_PUBLIC_HEADER})
        extract_destination(PRIVATE_DESTINATION ${ARG_PRIVATE_HEADER})

        foreach(TARGET ${ARG_TARGETS})
            get_target_property(TYPE ${TARGET} TYPE)
            cm_message(INFO "Installing ${TARGET}(${TYPE}) target...")

            set_target_properties(${TARGET} PROPERTIES
                ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_COPY_PREFIX}/${ARCHIVE_DESTINATION}
                LIBRARY_OUTPUT_DIRECTORY ${CMAKE_COPY_PREFIX}/${LIBRARY_DESTINATION}
                RUNTIME_OUTPUT_DIRECTORY ${CMAKE_COPY_PREFIX}/${RUNTIME_DESTINATION}
            )

            get_target_property(PUBLIC_HEADERS ${TARGET} PUBLIC_HEADER)
            if (PUBLIC_HEADERS)
                cm_message(INFO "Installing public headers of ${TARGET} target...")
                cm_generate_nested_headers(${CMAKE_COPY_PREFIX}/${PUBLIC_DESTINATION} ${PUBLIC_HEADERS})
            endif()

            get_target_property(PRIVATE_HEADERS ${TARGET} PRIVATE_HEADER)
            if (PRIVATE_HEADERS)
                cm_message(INFO "Installing private headers of ${TARGET} target...")
                cm_generate_nested_headers(${CMAKE_COPY_PREFIX}/${PRIVATE_DESTINATION} ${PRIVATE_HEADERS})
            endif()

            target_include_directories(${TARGET}
                PUBLIC
                    $<BUILD_INTERFACE:${CMAKE_COPY_PREFIX}/${PUBLIC_DESTINATION}>
                    $<BUILD_INTERFACE:${CMAKE_COPY_PREFIX}/include>
                    $<INSTALL_INTERFACE:${PUBLIC_DESTINATION}>
                    $<INSTALL_INTERFACE:/include>
                PRIVATE
                    $<BUILD_INTERFACE:${CMAKE_COPY_PREFIX}/${PRIVATE_DESTINATION}>
                    $<INSTALL_INTERFACE:${PRIVATE_DESTINATION}>
            )

            get_target_property(NAME ${TARGET} OUTPUT_NAME)
            if (NOT NAME)
                get_target_property(NAME ${TARGET} $NAME)
            endif()
            if (NOT ${NAME} STREQUAL ${CMAKE_PROJECT_NAME})
                set(NAME ${CMAKE_PROJECT_NAME}_${NAME})
            endif()
            string(TOUPPER ${NAME} NAME)

            if (${TYPE} STREQUAL "STATIC_LIBRARY")
                set(BUILD "STATIC")
            elseif (${TYPE} STREQUAL "SHARED_LIBRARY")
                set(BUILD "SHARED")
            else()
                unset(BUILD)
            endif()

            if (BUILD)
                target_compile_definitions(${TARGET}
                    PUBLIC  ${NAME}_LIB ${NAME}_${BUILD}
                    PRIVATE ${NAME}_BUILD
                )
            endif()
        endforeach()
    elseif (type STREQUAL DIRECTORY OR type STREQUAL FILES)
        list(APPEND options)
        list(APPEND oneValueArgs DESTINATION)
        list(APPEND multiValueArgs ${type})
        cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${type} ${ARGN})
        copy_files(${CMAKE_COPY_PREFIX}/${ARG_DESTINATION} ${ARG_${type}})
    else()
        list(APPEND options)
        list(APPEND oneValueArgs)
        list(APPEND multiValueArgs ${type})
        cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${type} ${ARGN})
    endif()

    install(${type} ${ARGN})
endfunction()

function(copy_files destination)
    cm_message(INFO "Copying ${ARGN}...")
    file(COPY ${ARGN} DESTINATION ${destination})
endfunction()
