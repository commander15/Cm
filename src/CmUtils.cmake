function(cm_generate_nested_headers destination)
    foreach (header ${ARGN})
        if (EXISTS ${header})
            file(RELATIVE_PATH path ${destination} ${header})
        elseif (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${header})
            file(RELATIVE_PATH path ${destination} ${CMAKE_CURRENT_SOURCE_DIR}/${header})
        else()
            message(FATAL_ERROR "Can't find header file ${header}")
        endif()

        get_filename_component(header ${header} NAME)
        file(WRITE ${destination}/${header} "#include \"${path}\"")
    endforeach()
endfunction()

macro(cm_get_target_name name target)
    get_target_property(${name} ${target} OUTPUT_NAME)
    if (NOT ${name})
        set(${name} ${target})
    endif()
endmacro()

macro(cm_get_target_output_location location target)
    get_target_property(type ${target} TYPE)
    if (type STREQUAL EXECUTABLE)
        cm_get_target_property(${location} ${target})
    endif()
endmacro()

macro(cm_get_target_property var target prop def)
    get_target_property(${var} ${target} ${prop})
    if (NOT ${var})
        set(${var} ${def})
    endif()
endmacro()