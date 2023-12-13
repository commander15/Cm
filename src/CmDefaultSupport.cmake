### Executables support

function(cm_add_default_executable name)
    add_executable(${name} ${ARGN})
endfunction()

function(cm_initialize_default_executable target)
endfunction()

function(cm_finalize_default_executable target)
endfunction()

### Plugins support

function(cm_add_default_plugin name)
    add_library(${name} MODULE ${ARGN})
endfunction()

function(cm_initialize_default_plugin target)
endfunction()

function(cm_finalize_default_plugin target)
endfunction()

### Libraries support

function(cm_add_default_library name)
    add_library(${name} ${ARGN})
endfunction()

function(cm_initialize_default_library target)
endfunction()

function(cm_finalize_default_library target)
endfunction()
