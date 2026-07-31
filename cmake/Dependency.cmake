include_guard(GLOBAL)

include(FetchContent)

# =========================================================
# Internal helper
# =========================================================

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
# Public API
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