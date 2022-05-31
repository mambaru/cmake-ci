ogenc_warning(-Wc++11-extensions "Warn about C++11 constructs in code compiled with an older standard." ON)
ogenc_warning(-Wc++14-extensions "Warn about C++14 constructs in code compiled with an older standard." ON)
ogenc_warning(-Wc++17-extensions "Warn about C++17 constructs in code compiled with an older standard." ON)
ogenc_warning(-Wc++20-extensions "Warn about C++20 constructs in code compiled with an older standard." ON)
ogenc_warning(-Wdeclaration-after-statement "Warn when a declaration is found after a statement." ON)
ogenc_warning(-Wexceptions "Warn when an exception handler is shadowed by another handler." ON)
ogenc_warning(-Wnarrowing "Warn about narrowing conversions within { } that are ill-formed in C++11." ON)
ogenc_warning(-Wshift-negative-value "Warn if left shifting a negative value." ON)
ogenc_warning(-Wvla "Warn if a variable length array is used." ON)

ogenc_warning(-Wlong-long "Do not warn about using `long long` when -pedantic." OFF)
ogenc_warning(-Wno-frame-larger-than "Disable -Wframe-larger-than= warning. Equivalent to -Wframe-larger-than=<SIZE_MAX> or larger. Same as" OFF)

