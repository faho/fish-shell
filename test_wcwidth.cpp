#include <wchar.h>
#include <iostream>

int main() {
    // Check wcwidth of a character that is wide in Unicode 9,
    // but narrow before.

    // For glibc, we skip the check,
    // because we know that >= 2.26 can do it and < can not.
    // This allows us to not depend on the locale.
#if defined(__GLIBC_PREREQ)
#if __GLIBC_PREREQ(2, 26)
    std::cout << 2;
# else
    std::cout << 1;
#endif
#else
    // We're not on glibc, so we actually perform the check.
    // This unfortunately requires a multibyte-locale.
    setlocale(LC_ALL, "");
    // This character picked somewhat arbitrary.
    std::cout << wcwidth(L'😃');
#endif
    return 0;
}
