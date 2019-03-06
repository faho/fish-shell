#include <cstring>
#include <wchar.h>
#include <iostream>

int main(int argc, char** argv) {
    // This initializes the locale according to the environment variables.
    // That means if the environment isn't set up for unicode, this whole excercise is pointless.
    setlocale(LC_ALL, "");

    // The locale is C, so try to get UTF-8 somehow.
    // Note that we don't handle locales with other encodings. I've never seen one used on purpose,
    // the biggest problem is the POSIX default.
    if (strcmp(setlocale(LC_ALL, NULL),"C") == 0) {
        std::cerr < "Please re-run this with a multibyte locale or the result is worthless\n";
    }
    std::cout << wcwidth(L'😃');
    return 0;
}
