use libc::{c_int};

use crate::builtins::shared::{
    builtin_missing_argument, builtin_print_help, builtin_unknown_option, io_streams_t,
    STATUS_CMD_OK, STATUS_INVALID_ARGS,
};
use crate::ffi::{parser_t};
use crate::wchar::{widestrs, wstr};
use crate::wgetopt::{wgetopter_t, wopt, woption, woption_argument_t};
use crate::wutil::{self, format, fish_wcstoi_radix_all, wgettext_fmt};
use rand::{Rng, SeedableRng};
use rand::rngs::SmallRng;


#[widestrs]
pub fn random(
    parser: &mut parser_t,
    streams: &mut io_streams_t,
    argv: &mut [&wstr],
) -> Option<c_int> {
    let cmd = argv[0];
    let argc = argv.len();
    let print_hints = false;

    const shortopts: &wstr = "+:h"L;
    const longopts: &[woption] = &[
        wopt("help"L, woption_argument_t::no_argument, 'h'),
    ];

    let mut w = wgetopter_t::new(shortopts, longopts, argv);
    while let Some(c) = w.wgetopt_long() {
        match c {
            'h' => {
                builtin_print_help(parser, streams, cmd);
                return STATUS_CMD_OK;
            }
            ':' => {
                builtin_missing_argument(parser, streams, cmd, argv[w.woptind - 1], print_hints);
                return STATUS_INVALID_ARGS;
            }
            '?' => {
                builtin_unknown_option(parser, streams, cmd, argv[w.woptind - 1], print_hints);
                return STATUS_INVALID_ARGS;
            }
            _ => {
                panic!("unexpected retval from wgeopter.next()");
            }
        }
    }

    let mut small_rng = SmallRng::from_entropy();
    let mut start = 0;
    let mut end = 32767;
    let mut step = 1;
    let argnum = argc - w.woptind;
    let mut i = w.woptind;
    if argnum >= 1 && argv[i] == "choice" {
        if argnum == 1 {
            streams.err.append(wgettext_fmt!(
                "%ls: nothing to choose from\n",
                cmd,
            ));
            return Some(2);
        }

        let rand = small_rng.gen_range(0..argnum - 1);
        streams.out.append(format::printf::sprintf!("%ls\n"L, argv[i + 1 + rand]));

        return Some(0);
    }

    match argnum {
        0 => {
            // Keep the defaults
        },
        1 => {
            // TODO: Seed the engine persistently
            streams.err.append(wgettext_fmt!(
                "%ls: SEED NOT IMPLEMENTED\n",
                cmd,
            ));
            return Some(255);
        },
        2 => {
            // start is first, end is second
            // TODO: wcstoi doesn't require that the string is fully used, but we should!
            let mpid: Result<i64, wutil::Error> = fish_wcstoi_radix_all(argv[i].chars(), None, true);
            // For some reason this error checking doesn't work?
            if mpid.is_err() {
                streams.err.append(wgettext_fmt!(
                    "%ls: %ls: invalid integer\n",
                    cmd,
                    argv[i],
                ));
                return Some(2);
            }
            start = mpid.unwrap();
            i += 1;
            let mpid: Result<i64, wutil::Error> = fish_wcstoi_radix_all(argv[i].chars(), None, true);
            if mpid.is_err() {
                streams.err.append(wgettext_fmt!(
                    "%ls: %ls: invalid integer\n",
                    cmd,
                    argv[i],
                ));
                return Some(2);
            }
            end = mpid.unwrap();
        },
        3 => {
            // start, step, end
            // TODO: Is this repetition necessary?
            let mpid: Result<i64, wutil::Error> = fish_wcstoi_radix_all(argv[i].chars(), None, true);
            if mpid.is_err() {
                streams.err.append(wgettext_fmt!(
                    "%ls: %ls: invalid integer\n",
                    cmd,
                    argv[i],
                ));
                return Some(2);
            }
            start = mpid.unwrap();
            i += 1;
            let mpid: Result<i64, wutil::Error> = fish_wcstoi_radix_all(argv[i].chars(), None, true);
            match mpid {
                Err(wutil::Error::Overflow) => {
                    // XXX For historical reasons - we have overflown. I'm quite sure this also happened
                    // in C++
                    streams.err.append(wgettext_fmt!(
                        "%ls: range contains only one possible value\n",
                        cmd,
                    ));
                    return Some(2);
                },
                Err(_) => {
                    streams.err.append(wgettext_fmt!(
                        "%ls: %ls: invalid integer\n",
                        cmd,
                        argv[i],
                    ));
                    return Some(2);
                }
                _ => {},
            };
            if mpid.unwrap() <= 0 {
                streams.err.append(wgettext_fmt!(
                    "%ls: STEP must be a positive integer\n",
                    cmd,
                ));
                return Some(2);
            }
            step = mpid.unwrap();
            i += 1;
            let mpid: Result<i64, wutil::Error> = fish_wcstoi_radix_all(argv[i].chars(), None, true);
            if mpid.is_err() {
                streams.err.append(wgettext_fmt!(
                    "%ls: %ls: invalid integer\n",
                    cmd,
                    argv[i],
                ));
                return Some(2);
            }
            end = mpid.unwrap();
        },
        _ => {
            streams.err.append(wgettext_fmt!(
                "%ls: too many arguments\n",
                cmd,
            ));
            return Some(1);
        }

    }

    if end <= start {
        streams.err.append(wgettext_fmt!(
            "%ls: END must be greater than START\n",
            cmd,
        ));
        return Some(2);
    }

    let real_end : i64 = if start >= 0 || end < 0 {
        start + ((end - start) / step)
    } else {
        let a = start.abs();
        ((end + a) / step) - a
    };

    let a = if start < real_end { start } else { real_end };
    let b = if start > real_end { start } else { real_end };

    if start.checked_add(step) == None {
        streams.err.append(wgettext_fmt!(
            "%ls: range contains only one possible value\n",
            cmd,
        ));
        return Some(2);
    }

    if a == b {
        streams.err.append(wgettext_fmt!(
            "%ls: range contains only one possible value\n",
            cmd,
        ));
        return Some(2);
    }

    match b.checked_add(1) {
        Some(c) => {
            let rand = small_rng.gen_range(a..c);

            let result = if start >= 0 {
                start + (rand - start) * step
            } else if rand < 0 {
                (rand - start) * step - start.abs()
            } else {
                (rand + start.abs()) * step - start.abs()
            };
            streams.out.append(format::printf::sprintf!("%d\n"L, result));
        },
        None => {
            streams.err.append(wgettext_fmt!(
                "%ls: END is too large\n",
                cmd,
            ));
            return Some(2);
        }
    }

    return Some(0);
}
