set(CM_BUILD_AAB OFF CACHE BOOL "Enable Android App Bundle Build")

if(NOT ANDROID_SDK)
  get_filename_component(ANDROID_SDK ${ANDROID_NDK}/../ ABSOLUTE)
endif()

find_program(ANDROID_DEPLOY_QT androiddeployqt)
get_filename_component(QT_DIR ${ANDROID_DEPLOY_QT}/../../ ABSOLUTE)

if (DEFINED ENV{JAVA_HOME})
  set(JAVA_HOME $ENV{JAVA_HOME} CACHE INTERNAL "Saved JAVA_HOME variable")
endif()
if (JAVA_HOME)
  set(android_deploy_qt_jdk "--jdk ${JAVA_HOME}")
endif()

if (ANDROID_SDK_PLATFORM)
  set(android_deploy_qt_platform "--android-platform ${ANDROID_SDK_PLATFORM}")
endif()

function(cm_initialize_target target type)
    _cm_initialize_target(${target} ${type})
    if (${type} STREQUAL EXECUTABLE)
        set(BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/${target}_android)

        set_target_properties(${target} PROPERTIES
            ANDROID_PACKAGE_SOURCE_DIR   "${CMAKE_BINARY_DIR}/android/package"
            ANDROID_PACKAGE_BINARY_DIR   "${BUILD_DIR}"
            APK_OUTPUT_DIRECTORY         "${CMAKE_CURRENT_BINARY_DIR}"
            LIBRARY_OUTPUT_DIRECTORY     "${BUILD_DIR}/package/libs/${ANDROID_ABI}"
        )

        if (NOT EXISTS ${CMAKE_BINARY_DIR}/android/package)
            file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/android/package)
            file(COPY ${Qt5_DIR}/../../../src/android/templates/
                DESTINATION ${CMAKE_BINARY_DIR}/android/package
            )
        endif()
    endif()
endfunction()

function(cm_finalize_target target type)
    _cm_finalize_target(${target} ${type})
    get_target_property(APK_DIR ${target} APK_OUTPUT_DIRECTORY)

    if (${type} STREQUAL EXECUTABLE)
        get_target_property(BUILD_DIR ${target} ANDROID_PACKAGE_BINARY_DIR)
        if (NOT BUILD_DIR)
            set(BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/${target}_android)
        endif()

        set(OUT_DIR ${BUILD_DIR}/package/libs/${ANDROID_ABI})
        set_target_properties(${target} PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY ${OUT_DIR}
            LIBRARY_OUTPUT_DIRECTORY ${OUT_DIR}
            RUNTIME_OUTPUT_DIRECTORY ${OUT_DIR}
        )

        get_target_property(PACKAGE_DIR ${target} ANDROID_PACKAGE_SOURCE_DIR)
        if (NOT PACKAGE_DIR)
            file(MAKE_DIRECTORY ${BUILD_DIR})
            file(COPY ${Qt5_DIR}/../../../src/android/templates/
                DESTINATION ${BUILD_DIR}/package
            )
            set(PACKAGE_DIR ${BUILD_DIR}/package)
        endif()

        get_target_property(BINARY ${target} OUTPUT_NAME)
        if (NOT BINARY)
            set(BINARY ${target})
        endif()

        get_target_property(BINARY_DIR ${target} LIBRARY_OUTPUT_DIRECTORY)

        get_target_property(EXTRA_LIBS ${target} ANDROID_EXTRA_LIBS)

        get_target_property(VERSION_NAME ${target} ANDROID_VERSION_NAME)
        get_target_property(VERSION_CODE ${target} ANDROID_VERSION_CODE)

        get_target_property(QML_ROOT ${target} QML_ROOT_PATH)
        if (NOT QML_ROOT)
            if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/qml)
                set(QML_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/qml)
            else()
                set(QML_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
            endif()
        endif()

        set(DEPLOYMENT_PARAMETERS
            PACKAGE_SOURCE_DIR "${PACKAGE_DIR}"
            BINARY             "${BINARY}"
            EXTRA_LIBS         "${EXTRA_LIBS}"
            VERSION_CODE       "${VERSION_CODE}"
            VERSION_NAME       "${VERSION_NAME}"
            QML_ROOT_PATH      "${QML_ROOT}"
        )

        cm_generate_android_deployment_file(
            ${BUILD_DIR}/android_deployment_settings.json
            ${DEPLOYMENT_PARAMETERS}
        )

        cm_add_apk(${target}-apk ${target}
            DEPLOYMENT_FILE ${BUILD_DIR}/android_deployment_settings.json
            SOURCES
                ${PACKAGE_DIR}/AndroidManifest.xml
                ${PACKAGE_DIR}/build.gradle
        )
    endif()
endfunction()

function(cm_add_apk name target)
    set(options)
    set(oneValueArgs DEPLOYMENT_FILE)
    set(multiValueArgs SOURCES ARGUMENTS)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    macro(extract_property name destination target)
        get_target_property(${destination} ${target} ${name})
    endmacro()

    extract_property(ANDROID_PACKAGE_SOURCE_DIR ANDROID_PACKAGE_SOURCE_DIR ${target})

    get_target_property(APK_DIR ${target} APK_OUTPUT_DIRECTORY)

    get_target_property(APK_NAME ${target} OUTPUT_NAME)
    if (NOT APK_NAME)
        set(APK_NAME ${target})
    endif()

    get_target_property(BINARY_DIR ${target} ANDROID_PACKAGE_BINARY_DIR)
    set(BINARY_DIR ${BINARY_DIR}/package)

    get_target_property(VERSION_NAME ${target} ANDROID_VERSION_NAME)
    if (VERSION_NAME)
    endif()

    set(RELEASES Release MinSizeRel)
    if (${CMAKE_BUILD_TYPE} IN_LIST RELEASES)
        set(android_deploy_qt_release --release)
    else()
        unset(android_deploy_qt_release)
    endif()

    get_target_property(keystore ${target} ANDROID_KEYSTORE_PATH)
    get_target_property(alias    ${target} ANDROID_KEYSTORE_ALIAS)
    get_target_property(password ${target} ANDROID_KEYSTORE_PASSWORD)

    if (keystore AND password AND alias)
        set(android_deploy_qt_signing "--sign file:///${keystore} ${alias} --storepass ${password}")
    else()
        unset(android_deploy_qt_signing)
    endif()

    get_target_property(BUILD_AAB ${target} ANDROID_BUILD_AAB)
    if (BUILD_AAB)
        set(android_deploy_qt_aab "--aab")
    else()
        unset(android_deploy_qt_aab)
    endif()

    set(android_deploy_qt_extras ${ARG_ARGUMENTS})

    add_custom_target(${name}
        COMMAND
            ${CMAKE_COMMAND} -E env JAVA_HOME=${JAVA_HOME}
                ${ANDROID_DEPLOY_QT}
                   --input "${ARG_DEPLOYMENT_FILE}"
                   --output "${BINARY_DIR}"
                   --apk "${APK_DIR}/${APK_NAME}.apk"
                   ${android_deploy_qt_platform}
                   ${android_deploy_qt_jdk}
                   ${android_deploy_qt_release}
                   ${android_deploy_qt_signing}
                   ${android_deploy_qt_aab}
                   ${android_deploy_qt_extras}
        SOURCES
            ${ARG_SOURCES}

        DEPENDS
            ${target}
        VERBATIM
    )
endfunction()

function(cm_generate_android_deployment_file file)
    set(options)
    set(oneValueArgs BINARY PACKAGE_SOURCE_DIR VERSION_CODE VERSION_NAME)
    set(multiValueArgs DEPLOYMENT_DEPENDENCIES EXTRA_PLUGINS EXTRA_LIBS QML_ROOT_PATH QML_IMPORT_PATH)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(QT_ANDROID_APPLICATION_BINARY ${ARG_BINARY})
    set(ANDROID_DEPLOYMENT_DEPENDENCIES ${ARG_DEPLOYMENT_DEPENDENCY})
    set(ANDROID_EXTRA_PLUGINS ${ARG_EXTRA_PLUGINS})
    set(ANDROID_PACKAGE_SOURCE_DIR ${ARG_PACKAGE_SOURCE_DIR})
    set(ANDROID_VERSION_CODE ${ARG_VERSION_CODE})
    set(ANDROID_VERSION_NAME ${ARG_VERSION_NAME})
    set(ANDROID_EXTRA_LIBS ${ARG_EXTRA_LIBS})
    set(QML_IMPORT_PATH ${ARG_QML_IMPORT_PATH})
    set(CMAKE_CURRENT_SOURCE_DIR ${ARG_QML_ROOT_PATH})

    set(template ${CMAKE_BINARY_DIR}/android_deployment_settings.json.in)
    if (NOT EXISTS ${template})
        file(WRITE ${template}
            [=[{
              "_description": "This file is created by CMake to be read by androiddeployqt and should not be modified by hand.",
              "application-binary": "@QT_ANDROID_APPLICATION_BINARY@",
              "architectures": {
                @QT_ANDROID_ARCHITECTURES@
              },
              @QT_ANDROID_DEPLOYMENT_DEPENDENCIES@
              @QT_ANDROID_EXTRA_PLUGINS@
              @QT_ANDROID_PACKAGE_SOURCE_DIR@
              @QT_ANDROID_VERSION_CODE@
              @QT_ANDROID_VERSION_NAME@
              @QT_ANDROID_EXTRA_LIBS@
              @QT_QML_IMPORT_PATH@
              "ndk": "@ANDROID_NDK@",
              "ndk-host": "@ANDROID_HOST_TAG@",
              "qml-root-path": "@CMAKE_CURRENT_SOURCE_DIR@",
              "qt": "@QT_DIR@",
              "sdk": "@ANDROID_SDK@",
              "stdcpp-path": "@ANDROID_TOOLCHAIN_ROOT@/sysroot/usr/lib/",
              "tool-prefix": "llvm",
              "toolchain-prefix": "llvm",
              "useLLVM": true
            }]=]
        )
    endif()

    unset(QT_ANDROID_ARCHITECTURES)
    foreach(abi IN LISTS ANDROID_ABIS)
      if (ANDROID_BUILD_ABI_${abi})
        list(APPEND QT_ANDROID_ARCHITECTURES "\"${abi}\" : \"${ANDROID_SYSROOT_${abi}}\"")
      endif()
    endforeach()
    string(REPLACE ";" ",\n" QT_ANDROID_ARCHITECTURES "${QT_ANDROID_ARCHITECTURES}")

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

    generate_json_variable_list(ANDROID_DEPLOYMENT_DEPENDENCIES "deployment-dependencies")
    generate_json_variable_list(ANDROID_EXTRA_PLUGINS "android-extra-plugins")
    generate_json_variable(ANDROID_PACKAGE_SOURCE_DIR "android-package-source-directory")
    generate_json_variable(ANDROID_VERSION_CODE "android-version-code")
    generate_json_variable(ANDROID_VERSION_NAME "android-version-name")
    generate_json_variable_list(ANDROID_EXTRA_LIBS "android-extra-libs")
    generate_json_variable_list(QML_IMPORT_PATH "qml-import-paths")
    generate_json_variable_list(ANDROID_MIN_SDK_VERSION "android-min-sdk-version")
    generate_json_variable_list(ANDROID_TARGET_SDK_VERSION "android-target-sdk-version")

    configure_file(${template} ${file} @ONLY)
endfunction()
