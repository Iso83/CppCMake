include_guard(GLOBAL)

function(cppcmake_version_git_hash output_variable)
    # =========================================================
    # Summary
    #
    # Resolves the current Git commit hash by:
    #   - Using the CPPCMAKE_GIT_HASH environment variable when available.
    #   - Reading the current Git repository when required.
    #   - Falling back to "unknown" when no hash can be determined.
    #
    # Parameters:
    #   [out] output_variable - Receives the resolved Git commit hash.
    # =========================================================

    set(git_hash "$ENV{CPPCMAKE_GIT_HASH}")

    if(NOT git_hash)

        find_package(Git QUIET)

        if(Git_FOUND)
            execute_process(
                COMMAND
                    "${GIT_EXECUTABLE}" rev-parse --short HEAD
                WORKING_DIRECTORY
                    "${PROJECT_SOURCE_DIR}"
                RESULT_VARIABLE
                    git_result
                OUTPUT_VARIABLE
                    git_hash
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
        endif()

    endif()

    if(NOT git_hash)
        set(git_hash "unknown")
    endif()

    set(${output_variable}
        "${git_hash}"
        PARENT_SCOPE
    )
endfunction()

function(cppcmake_version_git_branch output_variable)
    # =========================================================
    # Summary
    #
    # Resolves the current Git branch by:
    #   - Using the CPPCMAKE_GIT_BRANCH environment variable when available.
    #   - Reading the current Git repository when required.
    #   - Falling back to "unknown" when no branch can be determined.
    #
    # Parameters:
    #   [out] output_variable - Receives the resolved Git branch.
    # =========================================================

    set(git_branch "$ENV{CPPCMAKE_GIT_BRANCH}")

    if(NOT git_branch)

        find_package(Git QUIET)

        if(Git_FOUND)
            execute_process(
                COMMAND
                    "${GIT_EXECUTABLE}" rev-parse --abbrev-ref HEAD
                WORKING_DIRECTORY
                    "${PROJECT_SOURCE_DIR}"
                RESULT_VARIABLE
                    git_result
                OUTPUT_VARIABLE
                    git_branch
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
        endif()

    endif()

    if(NOT git_branch)
        set(git_branch "unknown")
    endif()

    set(${output_variable}
        "${git_branch}"
        PARENT_SCOPE
    )
endfunction()

function(cppcmake_version_generate)
    # =========================================================
    # Summary
    #
    # Generates the CppCMake version header by:
    #   - Using the current project version information.
    #   - Resolving the current Git branch.
    #   - Resolving the current Git commit hash.
    #   - Creating the generated Version.h header.
    #   - Writing the header to the project's generated include directory.
    #
    # Requires:
    #   cppcmake_project_initialize()
    # =========================================================

    if(NOT DEFINED CPPCMAKE_PROJECT_GENERATED_INCLUDE_DIR)
        message(FATAL_ERROR
            "cppcmake_version_generate() requires cppcmake_project_initialize()."
        )
    endif()

    set(CPPCMAKE_NAMESPACE "${PROJECT_NAME}")
    string(MAKE_C_IDENTIFIER "${CPPCMAKE_NAMESPACE}" CPPCMAKE_NAMESPACE)

    cppcmake_version_git_branch(CPPCMAKE_GIT_BRANCH)
    cppcmake_version_git_hash(CPPCMAKE_GIT_HASH)

    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../templates/Version.h.in"
        "${CPPCMAKE_PROJECT_GENERATED_INCLUDE_DIR}/${PROJECT_NAME}/Version.h"
        @ONLY
    )
endfunction()

function(cppcmake_version_target target)
    # =========================================================
    # Summary
    #
    # Configures a target to use the generated CppCMake version header by:
    #   - Adding the generated include directory to the target.
    #
    # Parameters:
    #   [in] target - Target receiving the generated version header.
    # =========================================================
    
    target_include_directories(${target}
        PUBLIC
            "$<BUILD_INTERFACE:${CPPCMAKE_PROJECT_GENERATED_INCLUDE_DIR}>"
    )
endfunction()
