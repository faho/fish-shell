// Implementation of the echo builtin.
#include "config.h"  // IWYU pragma: keep

#include "builtin_is.h"

#include <climits>
#include <cmath>
#include <cstddef>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "builtin.h"
#include "common.h"
#include "fallback.h"  // IWYU pragma: keep
#include "io.h"
#include "wgetopt.h"
#include "wutil.h"  // IWYU pragma: keep

/// Our number type. We support both doubles and long longs. We have to support these separately
/// because some integers are not representable as doubles; these may come up in practice (e.g.
/// inodes).
class number_t {
    // A number has an integral base and a floating point delta.
    // Conceptually the number is base + delta.
    // We enforce the property that 0 <= delta < 1.
    long long base;
    double delta;

   public:
    number_t(long long base, double delta) : base(base), delta(delta) {
        assert(0.0 <= delta && delta < 1.0 && "Invalid delta");
    }
    number_t() : number_t(0, 0.0) {}

    // Compare two numbers. Returns an integer -1, 0, 1 corresponding to whether we are less than,
    // equal to, or greater than the rhs.
    int compare(number_t rhs) const {
        if (this->base != rhs.base) return (this->base > rhs.base) - (this->base < rhs.base);
        return (this->delta > rhs.delta) - (this->delta < rhs.delta);
    }

    // Return true if the number is a tty()/
    bool isatty() const {
        if (delta != 0.0 || base > INT_MAX || base < INT_MIN) return false;
        return ::isatty(static_cast<int>(base));
    }
};

// Parse a double from arg. Return true on success, false on failure.
static bool parse_double(const wchar_t *arg, double *out_res) {
    // Consume leading spaces.
    while (arg && *arg != L'\0' && iswspace(*arg)) arg++;
    errno = 0;
    wchar_t *end = nullptr;
    *out_res = fish_wcstod(arg, &end);
    // Consume trailing spaces.
    while (end && *end != L'\0' && iswspace(*end)) end++;
    return errno == 0 && end > arg && *end == L'\0';
}

// IEEE 1003.1 says nothing about what it means for two strings to be "algebraically equal". For
// example, should we interpret 0x10 as 0, 10, or 16? Here we use only base 10 and use wcstoll,
// which allows for leading + and -, and whitespace. This is consistent, albeit a bit more lenient
// since we allow trailing whitespace, with other implementations such as bash.
static bool parse_number(const wcstring &arg, number_t *number) {
    const wchar_t *argcs = arg.c_str();
    double floating = 0;
    bool got_float = parse_double(argcs, &floating);
    errno = 0;
    long long integral = fish_wcstoll(argcs);
    bool got_int = (errno == 0);
    if (got_int) {
        // Here the value is just an integer; ignore the floating point parse because it may be
        // invalid (e.g. not a representable integer).
        *number = number_t{integral, 0.0};

        return true;
    } else if (got_float && errno != ERANGE && std::isfinite(floating)) {
        // Here we parsed an (in range) floating point value that could not be parsed as an integer.
        // Break the floating point value into base and delta. Ensure that base is <= the floating
        // point value.
        //
        // Note that a non-finite number like infinity or NaN doesn't work for us, so we checked
        // above.
        double intpart = std::floor(floating);
        double delta = floating - intpart;
        *number = number_t{static_cast<long long>(intpart), delta};

        return true;
    } else {
        // We could not parse a float or an int.
        return false;
    }
}

int is_empty(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    for (int i = 0; i < argc; i++) {
        if (*argv[i] != '\0') return STATUS_CMD_ERROR;
    }

    return STATUS_CMD_OK;
}
int is_notempty(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_empty(parser, streams, argc, argv) == STATUS_CMD_ERROR ? STATUS_CMD_OK : STATUS_CMD_ERROR;
}

int is_same(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    // One element isn't the same as itself.
    // If it were, you couldn't use `is same $var foo` without quoting $var again.
    if (argc < 2) return STATUS_CMD_ERROR;
    wchar_t *needle = argv[0];
    for (int i = 1; i < argc; i++) {
        if (std::wcscmp(needle, argv[i]) != 0) return STATUS_CMD_ERROR;
    }
    return STATUS_CMD_OK;
}

int is_numeric(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv, std::function<bool (number_t, number_t)> compare) {
    if (argc < 2) return STATUS_CMD_ERROR;
    number_t ln, rn;
    if (!parse_number(argv[0], &ln)) return STATUS_CMD_ERROR;

    for (int i = 1; i < argc; i++) {
        if (!parse_number(argv[i], &rn)) return STATUS_CMD_ERROR;
        if (!compare(ln, rn)) return STATUS_CMD_ERROR;
        ln = rn;
    }
    return STATUS_CMD_OK;
}

int is_greater(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_numeric(parser, streams, argc, argv, [](number_t ln, number_t rn) {
                                                       return ln.compare(rn) > 0;
                                                   });
}

int is_greater_equal(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_numeric(parser, streams, argc, argv, [](number_t ln, number_t rn) {
                                                       return ln.compare(rn) >= 0;
                                                   });
}

int is_less(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_numeric(parser, streams, argc, argv, [](number_t ln, number_t rn) {
                                                       return ln.compare(rn) < 0;
                                                   });
}

int is_less_equal(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_numeric(parser, streams, argc, argv, [](number_t ln, number_t rn) {
                                                       return ln.compare(rn) <= 0;
                                                   });
}

int is_equal(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_numeric(parser, streams, argc, argv, [](number_t ln, number_t rn) {
                                                       return ln.compare(rn) == 0;
                                                   });
}

int is_func(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv, std::function<bool (wchar_t*)> func) {
    if (argc < 1) return STATUS_CMD_ERROR;
    for (int i = 0; i < argc; i++) {
        if (!func(argv[i])) {
            return STATUS_CMD_ERROR;
        }
    }
    return STATUS_CMD_OK;
}

int is_path(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           struct stat buf;
                                                           return !wstat(arg, &buf);
                                                       });
}

int is_file(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           struct stat buf;
                                                           return !wstat(arg, &buf) && S_ISREG(buf.st_mode);
                                                       });
}

int is_directory(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           struct stat buf;
                                                           return !wstat(arg, &buf) && S_ISDIR(buf.st_mode);
                                                       });
}

int is_link(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           struct stat buf;
                                                           return !lwstat(arg, &buf) && S_ISLNK(buf.st_mode);
                                                       });
}

int is_readable(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           return !waccess(arg, R_OK);
                                                       });
}

int is_writable(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           return !waccess(arg, W_OK);
                                                       });
}

int is_executable(parser_t &parser, io_streams_t &streams, int argc, wchar_t **argv) {
    return is_func(parser, streams, argc, argv, [](wchar_t *arg) {
                                                           return !waccess(arg, X_OK);
                                                       });
}

static const struct is_subcommand {
    const wchar_t *name;
    int (*handler)(parser_t &, io_streams_t &, int argc,  //!OCLINT(unused param)
                   wchar_t **argv);                       //!OCLINT(unused param)
}

is_subcommands[] = {
                    {L"empty", &is_empty},
                    {L"notempty", &is_notempty},
                    {L"same", &is_same},
                    {L"greater", &is_greater},
                    {L"greater-equal", &is_greater_equal},
                    {L"less", &is_less},
                    {L"less-equal", &is_less_equal},
                    {L"equal", &is_equal},
                    {L"path", &is_path},
                    {L"file", &is_file},
                    {L"directory", &is_directory},
                    {L"link", &is_link},
                    {L"readable", &is_readable},
                    {L"writable", &is_writable},
                    {L"executable", &is_executable},
                    {nullptr, nullptr},
};

/// The is builtin.
int builtin_is(parser_t &parser, io_streams_t &streams, wchar_t **argv) {
    wchar_t *cmd = argv[0];
    int argc = builtin_count_args(argv);
    if (argc <= 1) {
        streams.err.append_format(BUILTIN_ERR_MISSING_SUBCMD, cmd);
        builtin_print_error_trailer(parser, streams.err, L"is");
        return STATUS_INVALID_ARGS;
    }

    // The only option we allow: "-h" or "--help" as the *first argument*.
    if (std::wcscmp(argv[1], L"-h") == 0 || std::wcscmp(argv[1], L"--help") == 0) {
        builtin_print_help(parser, streams, L"is");
        return STATUS_CMD_OK;
    }

    const is_subcommand *subcmd = &is_subcommands[0];

    while (subcmd->name != nullptr && std::wcscmp(subcmd->name, argv[1]) != 0) {
        subcmd++;
    }
    if (!subcmd->handler) {
        streams.err.append_format(BUILTIN_ERR_INVALID_SUBCMD, cmd, argv[1]);
        builtin_print_error_trailer(parser, streams.err, L"string");
        return STATUS_INVALID_ARGS;
    }
    // Remove "is" and the subcommand
    argc -= 2;
    argv += 2;
    return subcmd->handler(parser, streams, argc, argv);
}
