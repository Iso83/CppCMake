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
        message(FATAL_ERROR
            "CPPCMAKE_GITSUBMODULE_REPOSITORY_INVALID: '${ARG_WORKING_DIRECTORY}' is not inside a Git repository."
        )
    endif()

    if(NOT EXISTS "${GITSUBMODULE_GIT_ROOT}/.gitmodules")
        message(FATAL_ERROR
            "CPPCMAKE_GITSUBMODULE_GITMODULES_MISSING: '${GITSUBMODULE_GIT_ROOT}' does not contain a .gitmodules file."
        )
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