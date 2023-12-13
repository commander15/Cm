### Bootstrap

function(cm_init_android)
    # Match Android's sysroots
    set(ANDROID_SYSROOT_armeabi-v7a arm-linux-androideabi)
    set(ANDROID_SYSROOT_arm64-v8a aarch64-linux-android)
    set(ANDROID_SYSROOT_x86 i686-linux-android)
    set(ANDROID_SYSROOT_x86_64 x86_64-linux-android)

    set(ANDROID_ABIS armeabi-v7a arm64-v8a x86 x86_64)
    foreach(abi IN LISTS ANDROID_ABIS)
        if (abi STREQUAL ${ANDROID_ABI})
            set(abi_initial_value ON)
        else()
            set(abi_initial_value OFF)
        endif()

        find_library(Qt5Core_${abi}_Probe Qt5Core_${abi})
        if (Qt5Core_${abi}_Probe)
            option(ANDROID_BUILD_ABI_${abi} "Enable the build for Android ${abi}" ${abi_initial_value})
        endif()
    endforeach()

    # SDK
    if(NOT ANDROID_SDK)
      get_filename_component(ANDROID_SDK ${ANDROID_NDK}/../ ABSOLUTE)
    endif()

    # Deployment tool
    find_program(ANDROID_DEPLOY_QT androiddeployqt)
    get_filename_component(QT_DIR ${ANDROID_DEPLOY_QT}/../../ ABSOLUTE)
endfunction()

### Executables support

function(cm_add_android_executable name)
    list(REMOVE_ITEM ARGN WIN32 MACOSX_BUNDLE)

    add_library(${name} SHARED ${ARGN})

    set(BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/${name}_android)

    set_target_properties(${name} PROPERTIES
        ANDROID_PACKAGE_BINARY_DIR ${BIN_DIR}/package
        LIBRARY_OUTPUT_DIRECTORY   ${BIN_DIR}/package/libs/${ANDROID_ABI}
    )

    set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        APPEND
            PROPERTY ADDITIONAL_CLEAN_FILES ${BIN_DIR}
    )
endfunction()

function(cm_initialize_android_executable target)
    set(WD ${CMAKE_CURRENT_SOURCE_DIR})
    unset(PROPERTIES)

    # Android package detection
    if (EXISTS ${WD}/android/AndroidManifest.xml)
        list(APPEND PROPERTIES ANDROID_PACKAGE_SOURCE_DIR "${WD}/android")
    endif()

    # App version detection
    get_target_property(VERSION ${target} VERSION)
    if (VERSION)
    endif()

    # QML root detection
    get_target_property(QML_ROOT ${target} QML_ROOT_PATH)
    if (QML_ROOT)
    elseif (EXISTS ${WD}/main.qml)
        list(APPEND PROPERTIES QML_ROOT_PATH "${WD}")
    elseif (EXISTS ${WD}/qml/main.qml)
        list(APPEND PROPERTIES QML_ROOT_PATH "${WD}/main")
    endif()

    # QML import path detection
    if (QML_IMPORT_PATH)
        list(APPEND QML_IMPORT_PATH "${QML_IMPORT_PATH}")
    endif()

    set_target_properties(${target} PROPERTIES ${PROPERTIES})
endfunction()

function(cm_finalize_android_executable target)
    ### Getting data
    get_target_property(PACKAGE_DIR ${target} ANDROID_PACKAGE_BINARY_DIR)

    ### Generate deployment file
    get_target_property(DEPLOYMENT_FILE ${target} ANDROID_DEPLOYMENT_FILE)
    if (NOT DEPLOYMENT_FILE)
        set(DEPLOYMENT_FILE ${PACKAGE_DIR}/../android_deployment_settings.json)
        cm_generate_android_deployment_settings(${DEPLOYMENT_FILE} ${target})
    endif()

    ### Signing
    get_target_property(KEYSTORE_URL ${target} ANDROID_KEYSTORE_URL)
    if (KEYSTORE_URL)
        get_target_property(KEYSTORE_PASS ${target} ANDROID_KEYSTORE_PASS)
        get_target_property(KEYSTORE_TYPE ${target} ANDROID_KEYSTORE_TYPE)

        set(sign
            --sign ${KEYSTORE_URL}
            --storepass ${KEYSTORE_PASS}
            --storetype ${KEYSTORE_TYPE}
        )
    else()
        unset(sign)
    endif()

    ### APK output
    get_target_property(APK_DIR ${target} APK_OUTPUT_DIRECTORY)
    if (APK_DIR)
        get_target_property(APK_NAME ${target} OUTPUT_NAME)
        if (NOT APK_NAME)
            set(APK_NAME ${target})
        endif()

        set(apk --apk ${APK_DIR}/${APK_NAME}.apk)
    endif()

    ### AAB Build
    get_target_property(AAB_BUILD ${target} BUILD_AAB)
    if (AAB_BUILD)
        set(aab --aab)
    else()
        unset(aab)
    endif()

    ### Release build
    set(RELEASES Release RelWithDebInfo MinSizeRel)
    if (${CMAKE_BUILD_TYPE} IN_LIST RELEASES)
        set(release --release)
    else()
        unset(release)
    endif()

    ### Java detection
    if (JAVA_HOME)
      set(jdk "--jdk ${JAVA_HOME}")
    else()
        unset(jdk)
    endif()

    ### Android SDK platform
    if (ANDROID_SDK_PLATFORM)
      set(android-platform "--android-platform ${ANDROID_SDK_PLATFORM}")
    else()
        unset(android-platform)
    endif()

    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND
            ${CMAKE_COMMAND} -E env JAVA_HOME=${JAVA_HOME}
                ${androiddeployqt}
                    --input ${DEPLOYMENT_FILE}
                    --output ${PACKAGE_DIR}
                    --verbose
                    ${sign}
                    ${apk}
                    ${aab}
                    ${release}
                    ${jdk}
                    ${android-platform}
    )
endfunction()

### Plugins support

function(cm_add_android_plugin name)
    add_library(${name} MODULE ${ARGN})
endfunction()

function(cm_initialize_android_plugin target)
endfunction()

function(cm_finalize_android_plugin target)
endfunction()

### Libraries support

function(cm_add_android_library name)
    add_library(${name} ${ARGN})
endfunction()

function(cm_initialize_android_library target)
endfunction()

function(cm_finalize_android_library target)
endfunction()

### Helpers

function(cm_generate_android_deployment_settings file target)
    get_target_property(QT_APPLICATION_BINARY ${target} OUTPUT_NAME)
    get_target_property(ANDROID_DEPLOYMENT_DEPENDENCIES ${target} ANDROID_DEPLOYMENT_DEPENDENCIES)
    get_target_property(ANDROID_EXTRA_PLUGINS ${target} ANDROID_EXTRA_PLUGINS)
    get_target_property(ANDROID_PACKAGE_SOURCE_DIR ${target} ANDROID_PACKAGE_SOURCE_DIR)
    get_target_property(ANDROID_VERSION_CODE ${target} ANDROID_VERSION_CODE)
    get_target_property(ANDROID_VERSION_NAME ${target} ANDROID_VERSION_NAME)
    get_target_property(ANDROID_EXTRA_LIBS ${target} ANDROID_EXTRA_LIBS)
    get_target_property(QML_ROOT_PATH ${target} QML_ROOT_PATH)
    get_target_property(QML_IMPORT_PATH ${target} QML_IMPORT_PATH)
    get_target_property(ANDROID_MIN_SDK_VERSION ${target} ANDROID_MIN_SDK_VERSION)
    get_target_property(ANDROID_TARGET_SDK_VERSION ${target} ANDROID_TARGET_SDK_VERSION)

    macro(generate_json_variable_list var_list json_key)
      if (${var_list})
        set(QT_${var_list} "\"${json_key}\": \"")
        string(REPLACE ";" "," joined_var_list "${${var_list}}")
        string(APPEND QT_${var_list} "${joined_var_list}\",")
      endif()
    endmacro()

    macro(generate_json_variable var json_key)
      if (${var})
        set(QT_${var} "\"${json_key}\": \"${${var}}\",")
      endif()
    endmacro()

    if (NOT QT_APPLICATION_BINARY)
        set(QT_APPLICATION_BINARY ${target})
    endif()

    generate_json_variable_list(ANDROID_DEPLOYMENT_DEPENDENCIES "deployment-dependencies")
    generate_json_variable_list(ANDROID_EXTRA_PLUGINS "android-extra-plugins")
    generate_json_variable(ANDROID_PACKAGE_SOURCE_DIR "android-package-source-directory")
    generate_json_variable(ANDROID_VERSION_CODE "android-version-code")
    generate_json_variable(ANDROID_VERSION_NAME "android-version-name")
    generate_json_variable_list(ANDROID_EXTRA_LIBS "android-extra-libs")
    generate_json_variable_list(QML_IMPORT_PATH "qml-import-paths")
    generate_json_variable_list(ANDROID_MIN_SDK_VERSION "android-min-sdk-version")
    generate_json_variable_list(ANDROID_TARGET_SDK_VERSION "android-target-sdk-version")

    configure_file(
        ${Cm_ROOT}/share/Cm/android_deployment_settings.json.in
        ${file} @ONLY
    )
endfunction()
