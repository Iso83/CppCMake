include_guard(GLOBAL)

function(cppcmake_helper_include_target target)
    # =========================================================
    # Summary
    #
    # Adds the CppCMake framework include directories to a target.
    #
    # Parameters:
    #   [in] target - Target receiving the framework include directories.
    # =========================================================

    target_include_directories(${target}
        PUBLIC
            "${CPPCMAKE_PROJECT_FRAMEWORK_DIR}/include"
    )
endfunction()