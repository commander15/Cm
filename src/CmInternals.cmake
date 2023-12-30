function(cm_register_target target type)
    set_target_properties(${target} PROPERTIES
        CM_TYPE ${type}
    )

    string(TOLOWER ${type} type)
    cm_log(INFO "${target} ${type} registered")
endfunction()
