#pragma once

// CPP_DEPRECATED(msg)
// Use before a declaration to mark it deprecated with a message.
// Example:
//   CPP_DEPRECATED("Use Expr") struct ExprOld { ... };

#if defined(_MSC_VER)

#define CPP_DEPRECATED(msg) __declspec(deprecated(msg))

#elif defined(__has_cpp_attribute)

    #if __has_cpp_attribute(deprecated)
        #define CPP_DEPRECATED(msg) [[deprecated(msg)]]
    #elif defined(__GNUC__) || defined(__clang__)
        #define CPP_DEPRECATED(msg) __attribute__((deprecated(msg)))
    #else
        #define CPP_DEPRECATED(msg)
    #endif

#elif defined(__GNUC__) || defined(__clang__)

#define CPP_DEPRECATED(msg) __attribute__((deprecated(msg)))

#else

#define CPP_DEPRECATED(msg)

#endif