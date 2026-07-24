include_guard(GLOBAL)

function(cppcmake_module_deploy module_path)
    # =========================================================
    # Summary
    #
    # Deploys the CppCMake module template by:
    #   - Validating the requested module path.
    #   - Creating the module directory structure.
    #   - Generating the default CppCMake module files.
    #
    # If the module already exists, no changes are made.
    #
    # Parameters:
    #   [in] module_path - Module path relative to the current source directory.
    # =========================================================

    if("${module_path}" STREQUAL "")
        message(FATAL_ERROR
            "cppcmake_module_touch(): module_path may not be empty."
        )
    endif()

    if(IS_ABSOLUTE "${module_path}")
        message(FATAL_ERROR
            "cppcmake_module_touch(): module_path must be relative."
        )
    endif()

    cmake_path(NORMAL_PATH module_path OUTPUT_VARIABLE normalized_module_path)

    if(normalized_module_path MATCHES "(^|/)\\.\\.(/|$)")
        message(FATAL_ERROR
            "cppcmake_module_touch(): module_path may not leave the current source directory."
        )
    endif()

    set(module_dir
        "${CMAKE_CURRENT_SOURCE_DIR}/${normalized_module_path}"
    )

    if(EXISTS "${module_dir}")
        return()
    endif()

    cmake_path(GET normalized_module_path FILENAME module_name)

    set(CPPCMAKE_MODULE_NAME "${module_name}")
    set(CPPCMAKE_MODULE_PATH "${normalized_module_path}")

    string(SUBSTRING "${CPPCMAKE_MODULE_NAME}" 0 1 first)
    string(TOUPPER "${first}" first)
    string(SUBSTRING "${CPPCMAKE_MODULE_NAME}" 1 -1 rest)

    set(CPPCMAKE_MODULE_CLASS "${first}${rest}")

    set(CPPCMAKE_MODULE_NAMESPACE "")

    string(REPLACE "/" ";" namespace_parts "${normalized_module_path}")

    foreach(namespace_part IN LISTS namespace_parts)
        string(SUBSTRING "${namespace_part}" 0 1 first)
        string(TOUPPER "${first}" first)
        string(SUBSTRING "${namespace_part}" 1 -1 rest)

        if(CPPCMAKE_MODULE_NAMESPACE)
            string(APPEND CPPCMAKE_MODULE_NAMESPACE "::")
        endif()

        string(APPEND CPPCMAKE_MODULE_NAMESPACE "${first}${rest}")
    endforeach()

    file(MAKE_DIRECTORY
        "${module_dir}/include/${PROJECT_NAME}/${normalized_module_path}"
        "${module_dir}/src"
        "${module_dir}/tests"
    )

    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/module/CMakeLists.txt.in"
        "${module_dir}/CMakeLists.txt"
        @ONLY
    )

    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/module/Module.h.in"
        "${module_dir}/include/${PROJECT_NAME}/${normalized_module_path}/${CPPCMAKE_MODULE_CLASS}.h"
        @ONLY
    )

    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/module/Module.cpp.in"
        "${module_dir}/src/${CPPCMAKE_MODULE_CLASS}.cpp"
        @ONLY
    )

    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/module/ModulePrivate.h.in"
        "${module_dir}/src/${CPPCMAKE_MODULE_CLASS}.h"
        @ONLY
    )

    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/module/CTest.cpp.in"
        "${module_dir}/tests/Test_${CPPCMAKE_MODULE_CLASS}.cpp"
        @ONLY
    )
endfunction()

function(cppcmake_module_add module_path)
    # =========================================================
    # Summary
    #
    # Adds a CppCMake module to the current project by:
    #   - Deploying the module template if it does not exist.
    #   - Registering the module once per project.
    #   - Adding the module to the CMake build.
    #
    # Parameters:
    #   [in] module_path - Module path relative to the current source directory.
    #
    # Example:
    #   cppcmake_module_add(core)
    #   cppcmake_module_add(graphics/renderer)
    # =========================================================

    cppcmake_module_deploy("${module_path}")

    cmake_path(NORMAL_PATH module_path OUTPUT_VARIABLE normalized_module_path)
    set(module_key "${PROJECT_NAME}/${normalized_module_path}")

    get_property(registered_modules
        GLOBAL
        PROPERTY CPPCMAKE_REGISTERED_MODULES
    )

    if(module_key IN_LIST registered_modules)
        return()
    endif()

    list(APPEND registered_modules "${module_key}")
    set_property(
        GLOBAL
        PROPERTY CPPCMAKE_REGISTERED_MODULES
        "${registered_modules}"
    )

    add_subdirectory("${normalized_module_path}")
endfunction()
