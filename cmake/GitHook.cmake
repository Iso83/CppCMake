include_guard(GLOBAL)

# =========================================================
# Internal helper
# =========================================================

function(_cppcmake_githook_install)
    cmake_parse_arguments(
        ARG
        "FORCE"
        ""
        "HOOKS"
        ${ARGN}
    )

    if(NOT PROJECT_IS_TOP_LEVEL)
        message(STATUS
            "CppCMake: Git hooks skipped for nested project ${PROJECT_NAME}.")
        return()
    endif()

    find_package(Git QUIET)

    if(NOT Git_FOUND)
        message(WARNING
            "CppCMake: Git was not found; Git hooks were not installed.")
        return()
    endif()

    execute_process(
        COMMAND
            "${GIT_EXECUTABLE}" rev-parse --show-toplevel
        WORKING_DIRECTORY
            "${PROJECT_SOURCE_DIR}"
        RESULT_VARIABLE
            git_root_result
        OUTPUT_VARIABLE
            git_root
        ERROR_VARIABLE
            git_root_error
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(NOT git_root_result EQUAL 0)
        message(WARNING
            "CppCMake: '${PROJECT_SOURCE_DIR}' is not inside a Git repository. "
            "Git hooks were not installed.\n"
            "${git_root_error}"
        )
        return()
    endif()

    execute_process(
        COMMAND
            "${GIT_EXECUTABLE}" rev-parse --path-format=absolute --git-path hooks
        WORKING_DIRECTORY
            "${git_root}"
        RESULT_VARIABLE
            git_hook_directory_result
        OUTPUT_VARIABLE
            git_hook_directory
        ERROR_VARIABLE
            git_hook_directory_error
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(NOT git_hook_directory_result EQUAL 0)
        message(WARNING
            "CppCMake: Could not determine the Git hook directory.\n"
            "${git_hook_directory_error}"
        )
        return()
    endif()

    set(cppcmake_hook_directory
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hooks"
    )

    cmake_path(
        NORMAL_PATH cppcmake_hook_directory
        OUTPUT_VARIABLE cppcmake_hook_directory
    )

    set(supported_hooks
        pre-commit
    )

    file(MAKE_DIRECTORY "${git_hook_directory}")

    foreach(hook_name IN LISTS ARG_HOOKS)

        if(NOT hook_name IN_LIST supported_hooks)
            message(FATAL_ERROR
                "CppCMake: Unsupported Git hook '${hook_name}'."
            )
        endif()

        set(source_hook
            "${cppcmake_hook_directory}/${hook_name}"
        )

        set(destination_hook
            "${git_hook_directory}/${hook_name}"
        )

        if(NOT EXISTS "${source_hook}")
            message(FATAL_ERROR
                "CppCMake: Hook source does not exist: '${source_hook}'"
            )
        endif()

        if(EXISTS "${destination_hook}" AND NOT ARG_FORCE)
            file(SHA256 "${source_hook}" source_hash)
            file(SHA256 "${destination_hook}" destination_hash)

            if(source_hash STREQUAL destination_hash)
                message(STATUS
                    "CppCMake: Git hook '${hook_name}' is already installed."
                )
            else()
                message(WARNING
                    "CppCMake: Git hook '${destination_hook}' already exists "
                    "and differs from the CppCMake hook. It was not overwritten. "
                    "Use FORCE to replace it."
                )
            endif()

            continue()
        endif()

        configure_file(
            "${source_hook}"
            "${destination_hook}"
            COPYONLY
        )

        if(UNIX)
            file(CHMOD "${destination_hook}"
                PERMISSIONS
                    OWNER_READ
                    OWNER_WRITE
                    OWNER_EXECUTE
                    GROUP_READ
                    GROUP_EXECUTE
                    WORLD_READ
                    WORLD_EXECUTE
            )
        endif()

        message(STATUS
            "CppCMake: Installed Git hook '${hook_name}'."
        )

    endforeach()
endfunction()

# =========================================================
# Public API
# =========================================================

function(cppcmake_githook_precommit)
    # =========================================================
    # Summary
    #
    # Sets up the CppCMake pre-commit Git hook by:
    #   - Detecting the active Git hook directory.
    #   - Installing the CppCMake pre-commit hook.
    #   - Preserving an existing hook unless FORCE is specified.
    #
    # Parameters:
    #   [in] FORCE - Overwrites an existing pre-commit hook.
    #
    # Usage:
    #   cppcmake_githook_precommit()
    #   cppcmake_githook_precommit(FORCE)
    # =========================================================

    cmake_parse_arguments(
        ARG
        "FORCE"
        ""
        ""
        ${ARGN}
    )

    set(force_argument)

    if(ARG_FORCE)
        set(force_argument FORCE)
    endif()

    _cppcmake_githook_install(
        HOOKS
            pre-commit
        ${force_argument}
    )
endfunction()