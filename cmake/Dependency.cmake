include_guard(GLOBAL)

include(FetchContent)

# =========================================================
# Internal helpers
# =========================================================

function(_cppcmake_dependency_summary message_text)
    message(STATUS "CppCMake dependencies: ${message_text}")
endfunction()

function(_cppcmake_dependency_collect_targets TARGETS)
    # =========================================================
    # Summary
    #
    # Collects all build-system targets registered in the
    # current directory and its subdirectories.
    #
    # Parameters:
    #   [out] TARGETS - Receives the collected target list.
    # =========================================================

    set(targets)

    _cppcmake_dependency_collect_directory_targets(
        "${CMAKE_CURRENT_SOURCE_DIR}"
        targets
    )

    set(${TARGETS}
        ${targets}
        PARENT_SCOPE
    )
endfunction()

function(_cppcmake_dependency_collect_directory_targets directory TARGETS)
    # =========================================================
    # Summary
    #
    # Recursively collects build-system targets from a CMake
    # directory and all registered subdirectories.
    #
    # Parameters:
    #   [in]  directory - CMake source directory to inspect.
    #   [out] TARGETS   - Receives the collected target list.
    # =========================================================

    get_property(
        directory_targets
        DIRECTORY "${directory}"
        PROPERTY BUILDSYSTEM_TARGETS
    )

    set(targets
        ${${TARGETS}}
        ${directory_targets}
    )

    get_property(
        subdirectories
        DIRECTORY "${directory}"
        PROPERTY SUBDIRECTORIES
    )

    foreach(subdirectory IN LISTS subdirectories)
        _cppcmake_dependency_collect_directory_targets(
            "${subdirectory}"
            targets
        )
    endforeach()

    set(${TARGETS}
        ${targets}
        PARENT_SCOPE
    )
endfunction()

function(_cppcmake_dependency_organize_targets targets_before)
    # =========================================================
    # Summary
    #
    # Places all newly created targets into the project's
    # third_party IDE folder.
    #
    # Parameters:
    #   [in] targets_before - Target list captured before a dependency
    #                         was added.
    # =========================================================

    _cppcmake_dependency_collect_targets(TARGETS_AFTER)

    foreach(target IN LISTS TARGETS_AFTER)
        list(FIND targets_before "${target}" target_index)

        if(target_index GREATER_EQUAL 0)
            continue()
        endif()

        get_property(
            existing_folder
            TARGET ${target}
            PROPERTY FOLDER
        )

        if(existing_folder)
            continue()
        endif()

        set_property(
            TARGET ${target}
            PROPERTY FOLDER
            "${CPPCMAKE_PROJECT_IDE_THIRD_PARTY_FOLDER}/${target}"
        )
    endforeach()
endfunction()

# =========================================================
# FetchContent
# =========================================================

macro(cppcmake_dependency_make_available)
    # =========================================================
    # Summary
    #
    # Executes FetchContent_MakeAvailable() and automatically
    # places newly created targets inside the project's
    # third_party IDE folder.
    #
    # Note:
    #   Macro due to FetchContent_*_SOURCE_DIR variables.
    #
    # Usage:
    #
    #   cppcmake_dependency_make_available(
    #       imgui
    #       glm
    #       glfw
    #   )
    # =========================================================

    _cppcmake_dependency_collect_targets(TARGETS_BEFORE)

    FetchContent_MakeAvailable(${ARGV})

    _cppcmake_dependency_organize_targets("${TARGETS_BEFORE}")
endmacro()

# =========================================================
# Subdirectories
# =========================================================

function(cppcmake_dependency_add_subdirectory)
    # =========================================================
    # Summary
    #
    # Executes add_subdirectory() and automatically places
    # newly created targets inside the project's third_party
    # IDE folder.
    #
    # Usage:
    #
    #   cppcmake_dependency_add_subdirectory(
    #       extern/MyLibrary
    #   )
    # =========================================================

    _cppcmake_dependency_collect_targets(TARGETS_BEFORE)

    add_subdirectory(${ARGV})

    _cppcmake_dependency_organize_targets("${TARGETS_BEFORE}")
endfunction()

function(cppcmake_dependency_add_subdirectory_unless_target target)
    # =========================================================
    # Summary
    #
    # Adds a dependency subdirectory only when the specified
    # CMake target does not already exist.
    #
    # Newly created targets are automatically placed inside
    # the project's third_party IDE folder.
    #
    # Parameters:
    #   [in] target - Existing target that indicates the
    #                 dependency is already available.
    #
    # Remaining arguments are passed to
    # cppcmake_dependency_add_subdirectory().
    #
    # Usage:
    #
    #   cppcmake_dependency_add_subdirectory_unless_target(
    #       ScopeCanvas_engine_core
    #       extern/ScopeCanvas
    #   )
    # =========================================================

    if(TARGET "${target}")
        return()
    endif()

    cppcmake_dependency_add_subdirectory(${ARGN})
endfunction()

# =========================================================
# Target organization
# =========================================================

function(cppcmake_dependency_set_folder target folder)
    # =========================================================
    # Summary
    #
    # Assigns an explicit IDE folder to a dependency target.
    #
    # Parameters:
    #   [in] target - Target name.
    #   [in] folder - Folder relative to the project's
    #                 third_party IDE folder.
    # =========================================================

    if(TARGET ${target})
        set_property(
            TARGET ${target}
            PROPERTY FOLDER
            "${CPPCMAKE_PROJECT_IDE_THIRD_PARTY_FOLDER}/${folder}"
        )
    endif()
endfunction()

# =========================================================
# Local packages
# =========================================================

set(
    CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE
    ""
    CACHE FILEPATH
    "Optional local dependency package configuration"
)

function(cppcmake_dependency_try_local_packages)
    # =========================================================
    # Summary
    #
    # Loads an optional machine-local dependency package
    # configuration before resolving project dependencies.
    #
    # The configuration may extend CMAKE_PREFIX_PATH and
    # provide package-specific helpers for prebuilt libraries.
    # When no configuration file is specified or available,
    # dependency resolution continues normally.
    #
    # Configuration:
    #   CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE
    #       Path to the optional local package configuration.
    #
    # Usage:
    #
    #   cppcmake_dependency_try_local_packages()
    #
    # Example:
    #
    #   cmake -S . -B build
    #       -DCPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE=<file>
    # =========================================================

    if(NOT CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE)
        _cppcmake_dependency_summary(
            "local package configuration disabled"
        )
        return()
    endif()

    if(NOT EXISTS "${CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE}")
        _cppcmake_dependency_summary(
            "local package configuration unavailable: "
            "${CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE}"
        )
        return()
    endif()

    _cppcmake_dependency_summary(
        "using local package configuration: "
        "${CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE}"
    )

    include("${CPPCMAKE_DEPENDENCY_LOCAL_PACKAGE_FILE}")

    set(
        CMAKE_PREFIX_PATH
        "${CMAKE_PREFIX_PATH}"
        PARENT_SCOPE
    )
endfunction()