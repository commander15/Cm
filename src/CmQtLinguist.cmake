set(CmModule QtLinguist)
set(CmModuleGroup Qt)
list(APPEND CmQtModules LinguistTools)

function(cm_add_translation name)
    add_custom_target(${name} ALL SOURCES ${ARGN})

    cm_register_target(${name} TRANSLATION)
endfunction()
