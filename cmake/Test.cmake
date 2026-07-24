include_guard(GLOBAL)

macro(cppcmake_test_setup)
    # =========================================================
    # Summary
    #
    # Configures project test support by creating the project
    # build tests option and enabling CTest when requested.
    #
    # Memo
    #
    # Implemented as a macro because include(CTest) must execute
    # in the calling CMakeLists.txt.
    # =========================================================

    if(PROJECT_IS_TOP_LEVEL)
        set(build_tests_default ON)
    else()
        set(build_tests_default OFF)
    endif()

    option(
        ${PROJECT_NAME}_BUILD_TESTS
        "Build ${PROJECT_NAME} tests"
        ${build_tests_default}
    )

    if(${PROJECT_NAME}_BUILD_TESTS)
        include(CTest)
    endif()
endmacro()

function(cppcmake_test_add)
    # =========================================================
    # Summary
    #
    # Registers a project test by:
    #   - Creating the test executable.
    #   - Adding the CppCMake test helper include directory.
    #   - Linking the target library.
    #   - Registering the executable with CTest.
    #   - Assigning the test to the configured IDE folder.
    #   - Optionally linking additional libraries.
    #   - Optionally adding include directories.
    #   - Optionally adding compile definitions.
    #
    # If project test support is disabled, no changes are made.
    #
    # Parameters:
    #   [in] NAME                - Test executable and CTest name.
    #   [in] TARGET              - Target library under test.
    #   [in] SOURCES             - Test source files.
    #   [in] MODULE              - Optional module name used for the IDE folder.
    #   [in] LINK_LIBRARIES      - Optional additional libraries to link.
    #   [in] INCLUDE_DIRECTORIES - Optional include directories.
    #   [in] COMPILE_DEFINITIONS - Optional compile definitions.
    # =========================================================

    if(NOT DEFINED BUILD_TESTING OR NOT BUILD_TESTING)
        return()
    endif()

    set(build_tests_option "${PROJECT_NAME}_BUILD_TESTS")

    if(NOT ${build_tests_option})
        return()
    endif()

    cmake_parse_arguments(
        ARG
        ""
        "NAME;TARGET;MODULE"
        "SOURCES;LINK_LIBRARIES;INCLUDE_DIRECTORIES;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    if(NOT ARG_NAME OR NOT ARG_TARGET OR NOT ARG_SOURCES)
        message(FATAL_ERROR
            "cppcmake_test_add() requires NAME, TARGET and SOURCES."
        )
    endif()

    add_executable(
        ${ARG_NAME}
        ${ARG_SOURCES}
    )

    target_include_directories(
        ${ARG_NAME}
        PRIVATE
            "${CPPCMAKE_PROJECT_FRAMEWORK_DIR}/tests"
    )

    if(ARG_INCLUDE_DIRECTORIES)
        target_include_directories(
            ${ARG_NAME}
            PRIVATE
                ${ARG_INCLUDE_DIRECTORIES}
        )
    endif()

    target_link_libraries(
        ${ARG_NAME}
        PRIVATE
            ${ARG_TARGET}
    )

    if(ARG_LINK_LIBRARIES)
        target_link_libraries(
            ${ARG_NAME}
            PRIVATE
                ${ARG_LINK_LIBRARIES}
        )
    endif()

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(
            ${ARG_NAME}
            PRIVATE
                ${ARG_COMPILE_DEFINITIONS}
        )
    endif()

    add_test(
        NAME ${ARG_NAME}
        COMMAND ${ARG_NAME}
    )

    set(test_ide_folder "tests")

    if(ARG_MODULE)
        set(test_ide_folder "${test_ide_folder}/${ARG_MODULE}")
    endif()

    cppcmake_project_ide_folder(
        TEST_IDE_FOLDER
        "${test_ide_folder}"
    )

    set_property(
        TARGET ${ARG_NAME}
        PROPERTY FOLDER "${TEST_IDE_FOLDER}"
    )
endfunction()