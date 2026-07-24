include_guard(GLOBAL)

function(cppcmake_project_initialize)
    # =========================================================
    # Summary
    #
    # Initializes the current project for CppCMake by:
    #   - Validating project initialization.
    #   - Registering the project globally.
    #   - Determining the project's IDE folder.
    #   - Exposing common project and framework configuration
    #     to the parent scope.
    #
    # Parent scope output:
    #   CPPCMAKE_PROJECT_ALREADY_REGISTERED
    #   CPPCMAKE_PROJECT_ROOT_DIR
    #   CPPCMAKE_PROJECT_FRAMEWORK_DIR
    #   CPPCMAKE_PROJECT_GENERATED_INCLUDE_DIR
    #   CPPCMAKE_PROJECT_IDE_FOLDER
    #   CPPCMAKE_PROJECT_IDE_THIRD_PARTY_FOLDER
    # =========================================================

    if(PROJECT_NAME STREQUAL "")
        message(FATAL_ERROR
            "cppcmake_project_initialize() must be called after project()."
        )
    endif()

    get_property(registered_projects
        GLOBAL
        PROPERTY CPPCMAKE_REGISTERED_PROJECTS
    )

    if(PROJECT_NAME IN_LIST registered_projects)
        set(CPPCMAKE_PROJECT_ALREADY_REGISTERED TRUE PARENT_SCOPE)
        return()
    endif()

    set(CPPCMAKE_PROJECT_ALREADY_REGISTERED FALSE PARENT_SCOPE)
    
    list(APPEND registered_projects "${PROJECT_NAME}")
    set_property(
        GLOBAL
        PROPERTY CPPCMAKE_REGISTERED_PROJECTS
        "${registered_projects}"
    )

    set(project_ide_third_party_folder "third_party")

    if(PROJECT_IS_TOP_LEVEL)
        set(project_ide_folder "")
    else()
        set(project_ide_folder
            "${project_ide_third_party_folder}/${PROJECT_NAME}"
        )
    endif()

    set(CPPCMAKE_PROJECT_IDE_THIRD_PARTY_FOLDER
        "${project_ide_third_party_folder}"
        PARENT_SCOPE
    )
   
    set(CPPCMAKE_PROJECT_ROOT_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}"
        PARENT_SCOPE
    )

   get_filename_component(
        cppcmake_project_framework_dir
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/.."
        ABSOLUTE
    )

    set(
        CPPCMAKE_PROJECT_FRAMEWORK_DIR
        "${cppcmake_project_framework_dir}"
        PARENT_SCOPE
    )

    set(CPPCMAKE_PROJECT_GENERATED_INCLUDE_DIR
        "${CMAKE_CURRENT_BINARY_DIR}/generated/include"
        PARENT_SCOPE
    )
    set(CPPCMAKE_PROJECT_IDE_FOLDER
        "${project_ide_folder}"
        PARENT_SCOPE
    )
endfunction()

function(cppcmake_project_ide_folder output_variable relative_folder)
    # =========================================================
    # Summary
    #
    # Resolves the IDE folder for the current project by:
    #   - Combining the project IDE root with a relative folder.
    #   - Falling back to the relative folder for top-level projects.
    #   - Returning the resolved folder to the parent scope.
    #
    # Parameters:
    #   [out] output_variable  - Receives the resolved IDE folder.
    #   [in]  relative_folder  - Folder relative to the project IDE root.
    # =========================================================

    if(CPPCMAKE_PROJECT_IDE_FOLDER AND relative_folder)
        set(folder "${CPPCMAKE_PROJECT_IDE_FOLDER}/${relative_folder}")
    elseif(CPPCMAKE_PROJECT_IDE_FOLDER)
        set(folder "${CPPCMAKE_PROJECT_IDE_FOLDER}")
    else()
        set(folder "${relative_folder}")
    endif()

    set(${output_variable} "${folder}" PARENT_SCOPE)
endfunction()

function(cppcmake_project_set_ide_folder target relative_folder)
    # =========================================================
    # Summary
    #
    # Assigns an IDE folder to a target by:
    #   - Resolving the project-relative IDE folder.
    #   - Applying the resolved folder to the target.
    #
    # Parameters:
    #   [in] target           - Target receiving the IDE folder.
    #   [in] relative_folder  - Folder relative to the project IDE root.
    # =========================================================

    cppcmake_project_ide_folder(
        ide_folder
        "${relative_folder}"
    )

    set_property(
        TARGET ${target}
        PROPERTY FOLDER "${ide_folder}"
    )
endfunction()