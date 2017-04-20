project('fish', 'cpp', version : '2.6.0', default_options : ['cpp_std=c++11'])

cpp = meson.get_compiler('cpp')

gettextdep = dependency('gettext', required: false)
ncursesdep = dependency('ncurses')
threaddep = dependency('threads')
rtdep = cpp.find_library('rt', required: true)
pcre2dep = dependency('libpcre2-32')
deps = [ncursesdep, rtdep, threaddep, gettextdep, pcre2dep]

subdir('po')
global_warn_flags = []
global_warn_flag_opts = [ '-Wall', '-Wextra', '-Wno-missing-field-initializers' ]
foreach f : global_warn_flag_opts if cpp.has_argument(f)
    global_warn_flags += f
  endif
endforeach

global_opts = ['-fno-exceptions', '-g']
foreach f : global_opts
  if cpp.has_argument(f)
    global_warn_flags += f
  endif
endforeach

conf = configuration_data()

headers = ['curses', 'ncurses', 'dirent', 'execinfo', 'getopt',
           'inttypes', 'libintl', 'memory', 'ndir', 'siginfo',
           'spawn', 'stdint', 'stdlib', 'strings', 'string',
           'stropts', 'termios', 'term', 'unistd',
           'ncurses/curses', 'ncurses/term',
           'sys/ioctl', 'sys/resource', 'sys/ndir',
           'sys/select', 'sys/stat', 'sys/sysctl',
           'sys/types' # , 'sys/dir'
          ]
foreach h : headers
  if cpp.has_header(h + '.h')
    # "underscorify" replaces all chars other than `a-zA-Z0-9` with `_`,
    # so "ncurses/curses.h" ends up as "NCURSES_CURSES_H".
    conf.set('HAVE_' + h.underscorify().to_upper() + '_H', 1)
  endif
endforeach

functions = [ 'backtrace_symbols', 'clock_gettime', 'dirfd',
              'flock', 'futimens', 'futimes', 'getifaddrs',
              'getpwent', 'gettext', 'killpg', 'lrand48_r',
              'mkostemp', 'shm_open', 'wcscasecmp', 'wcsdup',
              'wcslcpy', 'wcsncasecmp', 'wcsndup'
            ]
foreach f : functions
        if cpp.has_function(f)
           conf.set('HAVE_' + f.to_upper(), 1)
        endif
endforeach

# TODO: Unconditionally setting this to true
conf.set('HAVE_CXX11', 1)
# TODO: Needs include
if cpp.has_member('struct dirent', 'd_type')
  conf.set('HAVE_STRUCT_DIRENT_D_TYPE', 1)
endif
if cpp.has_member('struct stat', 'st_mtim_tv_nsec')
  conf.set('HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC', 1)
endif
conf.set('HAVE_SYS_ERRLIST', 1)
conf.set('HAVE_WINSIZE', 1)
conf.set('HAVE__NL_MSG_CAT_CNTR', 1)
conf.set('HAVE__PROC_SELF_STAT', 1)
conf.set('NCURSES_NOMACROS', 1)
conf.set('NOMACROS', 1)
conf.set('SIZEOF_WCHAR_T', cpp.sizeof('wchar_t'))
conf.set('STDC_HEADERS', 1)
conf.set('WCHAR_T_BITS', 32)
conf.set_quoted('PACKAGE_BUGREPORT', 'fish-users@lists.sourceforge.net')
conf.set_quoted('PACKAGE_URL', '')
package_name = 'fish'
conf.set_quoted('PACKAGE_TARNAME', package_name)
conf.set_quoted('PACKAGE_NAME', package_name)
# TODO: This regenerates the file FISH-BUILD-VERSION-FILE
# c = run_command('build_tools/git_version_gen.sh')
vcs_tag(input: 'FISH-BUILD-VERSION-FILE',
        output: 'FISH-BUILD-VERSION-FILE',
        fallback: 'version')
package_version = '7' # c.stdout()
conf.set_quoted('PACKAGE_VERSION', package_version)
conf.set_quoted('PACKAGE_STRING', package_name + package_version)

if gettextdep.found()
    conf.set('USE_GETTEXT', 1)
endif

# TODO: Figure out the directory settings
# "localedir" and "prefix" are pre-defined for meson.
dirs = [ 'bindir', 'datadir', 'docdir', 'sysconfdir', 'localedir', 'prefix' ]
foreach d : dirs
      conf.set_quoted(d.to_upper(), get_option(d))
endforeach

configure_file(input : 'meson_config.h',
               output : 'config.h',
               configuration : conf)

inc = include_directories('src/')

# TODO: There's _got_ to be an easier way than this!
filelist = files('src/autoload.cpp', 'src/builtin.cpp',
                 'src/builtin_commandline.cpp','src/builtin_complete.cpp',
                 'src/builtin_jobs.cpp','src/builtin_printf.cpp',
                 'src/builtin_set.cpp','src/builtin_set_color.cpp',
                 'src/builtin_string.cpp','src/builtin_test.cpp',
                 'src/builtin_ulimit.cpp','src/color.cpp',
                 'src/common.cpp','src/complete.cpp',
                 'src/env.cpp','src/env_universal_common.cpp',
                 'src/event.cpp','src/exec.cpp','src/expand.cpp',
                 'src/fallback.cpp','src/fish_signal.cpp',
                 'src/fish_version.cpp','src/function.cpp',
                 'src/highlight.cpp','src/history.cpp',
                 'src/input.cpp','src/input_common.cpp',
                 'src/intern.cpp','src/io.cpp',
                 'src/iothread.cpp','src/kill.cpp',
                 'src/output.cpp','src/pager.cpp',
                 'src/parse_execution.cpp',
                 'src/parse_productions.cpp','src/parse_tree.cpp',
                 'src/parse_util.cpp','src/parser.cpp',
                 'src/parser_keywords.cpp','src/path.cpp',
                 'src/postfork.cpp','src/print_help.cpp',
                 'src/proc.cpp','src/reader.cpp',
                 'src/sanity.cpp','src/screen.cpp',
                 'src/tokenizer.cpp','src/utf8.cpp','src/util.cpp',
                 'src/wcstringutil.cpp','src/wgetopt.cpp',
                 'src/wildcard.cpp','src/wutil.cpp')

executable('fish', 'src/fish.cpp', filelist,
           include_directories : inc,
           dependencies : deps,
           install : true)
executable('fish_key_reader', 'src/fish_key_reader.cpp', filelist,
                              include_directories : inc,
                              dependencies : deps,
                              install : true)
executable('fish_indent', 'src/fish_indent.cpp', filelist,
                          include_directories : inc,
                          dependencies : deps,
                          install : true)
