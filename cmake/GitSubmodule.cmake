include_guard(GLOBAL)

include(CMakeParseArguments)

function(cppcmake_gitsubmodule_init)
    # =========================================================
    # Summary
    #
    # Initializes one or more Git submodules when they are not
    # yet available.
    #
    # The owning Git repository is resolved automatically from
    # the supplied working directory, allowing the function to
    # operate correctly inside nested Git repositories.
    #
    # Options:
    #   QUIET - Suppresses status messages.
    #
    # Parameters:
    #   WORKING_DIRECTORY - Any directory located inside the
    #                       Git repository.
    #
    #   PATH - One or more relative submodule paths.
    # =========================================================

    set(options
        QUIET
    )

    set(oneValueArgs
        WORKING_DIRECTORY
    )

    set(multiValueArgs
        PATH
    )

    cmake_parse_arguments(ARG
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if(NOT ARG_WORKING_DIRECTORY)
        message(FATAL_ERROR
            "CPPCMAKE_GITSUBMODULE_WORKING_DIRECTORY_MISSING: WORKING_DIRECTORY is required."
        )
    endif()

    if(NOT ARG_PATH)
        message(FATAL_ERROR
            "CPPCMAKE_GITSUBMODULE_PATH_MISSING: PATH is required."
        )
    endif()

    find_package(Git REQUIRED)

    execute_process(
        COMMAND
            "${GIT_EXECUTABLE}"
            -C
            "${ARG_WORKING_DIRECTORY}"
            rev-parse
            --show-toplevel
        OUTPUT_VARIABLE GITSUBMODULE_GIT_ROOT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE GITSUBMODULE_RESULT
    )

    if(NOT GITSUBMODULE_RESULT EQUAL 0)

        if(NOT ARG_QUIET)
            message(STATUS
                "CppCMake: '${ARG_WORKING_DIRECTORY}' is not inside a Git repository. Git submodule initialization was skipped."
            )
        endif()

        return()

    endif()

    if(NOT EXISTS "${GITSUBMODULE_GIT_ROOT}/.gitmodules")

        if(NOT ARG_QUIET)
            message(STATUS
                "CppCMake: '${GITSUBMODULE_GIT_ROOT}' does not contain a .gitmodules file. Git submodule initialization was skipped."
            )
        endif()

        return()

    endif()

    file(
        READ
        "${GITSUBMODULE_GIT_ROOT}/.gitmodules"
        GITSUBMODULE_GITMODULES_CONTENT
    )

    set(GITSUBMODULE_SUBMODULES_TO_INITIALIZE)

    foreach(submodule IN LISTS ARG_PATH)

        string(
            FIND
            "${GITSUBMODULE_GITMODULES_CONTENT}"
            "path = ${submodule}"
            GITSUBMODULE_INDEX
        )

        if(GITSUBMODULE_INDEX EQUAL -1)
            message(FATAL_ERROR
                "CPPCMAKE_GITSUBMODULE_NOT_FOUND: '${submodule}' is not registered in .gitmodules."
            )
        endif()

        if(EXISTS "${GITSUBMODULE_GIT_ROOT}/${submodule}/.git")
            continue()
        endif()

        if(EXISTS "${GITSUBMODULE_GIT_ROOT}/${submodule}")

            file(
                GLOB
                GITSUBMODULE_CONTENT
                "${GITSUBMODULE_GIT_ROOT}/${submodule}/*"
            )

            list(
                LENGTH
                GITSUBMODULE_CONTENT
                GITSUBMODULE_CONTENT_COUNT
            )

            if(GITSUBMODULE_CONTENT_COUNT GREATER 0)
                continue()
            endif()

        endif()

        list(
            APPEND
            GITSUBMODULE_SUBMODULES_TO_INITIALIZE
            "${submodule}"
        )

    endforeach()

    foreach(submodule IN LISTS GITSUBMODULE_SUBMODULES_TO_INITIALIZE)

        if(NOT ARG_QUIET)
            message(STATUS
                "Initializing Git submodule '${submodule}'."
            )
        endif()

        execute_process(
            COMMAND
                "${GIT_EXECUTABLE}"
                -C
                "${GITSUBMODULE_GIT_ROOT}"
                submodule
                update
                --init
                --
                "${submodule}"
            RESULT_VARIABLE GITSUBMODULE_RESULT
        )

        if(NOT GITSUBMODULE_RESULT EQUAL 0)
            message(FATAL_ERROR
                "CPPCMAKE_GITSUBMODULE_INITIALIZE_FAILED: Failed to initialize '${submodule}'."
            )
        endif()

    endforeach()

endfunction()

function(cppcmake_gitsubmodule_init_missing_targets)
    # =========================================================
    # Summary
    #
    # Initializes Git submodules conditionally based on whether
    # their associated CMake target already exists.
    #
    # Each PATH starts a new submodule entry. An optional TARGET
    # may follow it. When TARGET exists, that submodule is skipped.
    # A PATH without TARGET is always considered for initialization.
    #
    # Usage:
    #
    #   cppcmake_gitsubmodule_init_missing_targets(
    #       WORKING_DIRECTORY
    #           "${CMAKE_CURRENT_SOURCE_DIR}"
    #
    #       PATH
    #           "extern/ScopeCanvas"
    #       TARGET
    #           "ScopeCanvas_engine_core"
    #
    #       PATH
    #           "extern/CppDependencies"
    #
    #       PATH
    #           "extern/ScopeCanvas.Editor"
    #       TARGET
    #           "SC_editor_text"
    #   )
    #
    # Parameters:
    #   WORKING_DIRECTORY - Any directory inside the owning Git
    #                       repository.
    #
    #   PATH              - Starts a submodule entry.
    #
    #   TARGET            - Optional CMake target associated with
    #                       the preceding PATH. When already present,
    #                       the submodule is not initialized.
    # =========================================================

    set(_working_directory)
    set(_submodules)
    set(_path)
    set(_target)
    set(_mode)

    foreach(_arg IN LISTS ARGN)
        if(_arg STREQUAL "WORKING_DIRECTORY")
            set(_mode WORKING_DIRECTORY)

        elseif(_arg STREQUAL "PATH")
            if(_path)
                if(NOT _target OR NOT TARGET "${_target}")
                    list(APPEND _submodules "${_path}")
                endif()
            endif()

            set(_path)
            set(_target)
            set(_mode PATH)

        elseif(_arg STREQUAL "TARGET")
            if(NOT _path)
                message(FATAL_ERROR
                    "CPPCMAKE_GITSUBMODULE_TARGET_WITHOUT_PATH: TARGET requires a preceding PATH."
                )
            endif()

            set(_mode TARGET)

        elseif(_mode STREQUAL "WORKING_DIRECTORY")
            set(_working_directory "${_arg}")
            set(_mode)

        elseif(_mode STREQUAL "PATH")
            set(_path "${_arg}")
            set(_mode)

        elseif(_mode STREQUAL "TARGET")
            set(_target "${_arg}")
            set(_mode)

        else()
            message(FATAL_ERROR
                "CPPCMAKE_GITSUBMODULE_ARGUMENT_INVALID: Unexpected argument '${_arg}'."
            )
        endif()
    endforeach()

    if(_path)
        if(NOT _target OR NOT TARGET "${_target}")
            list(APPEND _submodules "${_path}")
        endif()
    endif()

    if(NOT _working_directory)
        message(FATAL_ERROR
            "CPPCMAKE_GITSUBMODULE_WORKING_DIRECTORY_MISSING: WORKING_DIRECTORY is required."
        )
    endif()

    if(NOT _submodules)
        return()
    endif()

    cppcmake_gitsubmodule_init(
        QUIET
        WORKING_DIRECTORY
            "${_working_directory}"
        PATH
            ${_submodules}
    )
endfunction()