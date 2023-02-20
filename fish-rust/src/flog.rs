use crate::ffi::{get_flog_file_fd, parse_util_unescape_wildcards, wildcard_match};
use crate::wchar::{wstr, WString};
use crate::wchar_ffi::WCharToFFI;
use std::io::Write;
use std::os::unix::io::{FromRawFd, IntoRawFd, RawFd};
use std::sync::atomic::Ordering;

#[rustfmt::skip::macros(category)]
pub mod categories {
    use super::wstr;
    use std::sync::atomic::AtomicBool;

    pub struct category_t {
        pub name: &'static wstr,
        pub description: &'static wstr,
        pub enabled: AtomicBool,
    }

    /// Macro to declare a static variable identified by $var,
    /// with the given name and description, and optionally enabled by default.
    macro_rules! declare_category {
        (
            ($var:ident, $name:expr, $description:expr, $enabled:expr)
        ) => {
            pub static $var: category_t = category_t {
                name: $name,
                description: $description,
                enabled: AtomicBool::new($enabled),
            };
        };
        (
            ($var:ident, $name:expr, $description:expr)
        ) => {
            declare_category!(($var, $name, $description, false));
        };
    }

    /// Macro to extract the variable name for a category.
    macro_rules! category_name {
        (($var:ident, $name:expr, $description:expr, $enabled:expr)) => {
            $var
        };
        (($var:ident, $name:expr, $description:expr)) => {
            $var
        };
    }

    macro_rules! categories {
        (
            // A repetition of categories, separated by semicolons.
            $($cats:tt);*

            // Allow trailing semicolon.
            $(;)?
        ) => {
            // Declare each category.
            $(
                declare_category!($cats);
            )*

            // Define a function which gives you a Vector of all categories.
            pub fn all_categories() -> Vec<&'static category_t> {
                vec![
                    $(
                        & category_name!($cats),
                    )*
                ]
            }
        };
    }

    categories!(
        (error, widestring::utf32str!("error"), widestring::utf32str!("Serious unexpected errors (on by default)"), true);

        (debug, widestring::utf32str!("debug"), widestring::utf32str!("Debugging aid (on by default)"), true);

        (warning, widestring::utf32str!("warning"), widestring::utf32str!("Warnings (on by default)"), true);

        (warning_path, widestring::utf32str!("warning-path"), widestring::utf32str!("Warnings about unusable paths for config/history (on by default)"), true);

        (config, widestring::utf32str!("config"), widestring::utf32str!("Finding and reading configuration"));

        (event, widestring::utf32str!("event"), widestring::utf32str!("Firing events"));

        (exec, widestring::utf32str!("exec"), widestring::utf32str!("Errors reported by exec (on by default)"), true);

        (exec_job_status, widestring::utf32str!("exec-job-status"), widestring::utf32str!("Jobs changing status"));

        (exec_job_exec, widestring::utf32str!("exec-job-exec"), widestring::utf32str!("Jobs being executed"));

        (exec_fork, widestring::utf32str!("exec-fork"), widestring::utf32str!("Calls to fork()"));

        (output_invalid, widestring::utf32str!("output-invalid"), widestring::utf32str!("Trying to print invalid output"));
        (ast_construction, widestring::utf32str!("ast-construction"), widestring::utf32str!("Parsing fish AST"));

        (proc_job_run, widestring::utf32str!("proc-job-run"), widestring::utf32str!("Jobs getting started or continued"));

        (proc_termowner, widestring::utf32str!("proc-termowner"), widestring::utf32str!("Terminal ownership events"));

        (proc_internal_proc, widestring::utf32str!("proc-internal-proc"), widestring::utf32str!("Internal (non-forked) process events"));

        (proc_reap_internal, widestring::utf32str!("proc-reap-internal"), widestring::utf32str!("Reaping internal (non-forked) processes"));

        (proc_reap_external, widestring::utf32str!("proc-reap-external"), widestring::utf32str!("Reaping external (forked) processes"));
        (proc_pgroup, widestring::utf32str!("proc-pgroup"), widestring::utf32str!("Process groups"));

        (env_locale, widestring::utf32str!("env-locale"), widestring::utf32str!("Changes to locale variables"));

        (env_export, widestring::utf32str!("env-export"), widestring::utf32str!("Changes to exported variables"));

        (env_dispatch, widestring::utf32str!("env-dispatch"), widestring::utf32str!("Reacting to variables"));

        (uvar_file, widestring::utf32str!("uvar-file"), widestring::utf32str!("Writing/reading the universal variable store"));
        (uvar_notifier, widestring::utf32str!("uvar-notifier"), widestring::utf32str!("Notifications about universal variable changes"));

        (topic_monitor, widestring::utf32str!("topic-monitor"), widestring::utf32str!("Internal details of the topic monitor"));
        (char_encoding, widestring::utf32str!("char-encoding"), widestring::utf32str!("Character encoding issues"));

        (history, widestring::utf32str!("history"), widestring::utf32str!("Command history events"));
        (history_file, widestring::utf32str!("history-file"), widestring::utf32str!("Reading/Writing the history file"));

        (profile_history, widestring::utf32str!("profile-history"), widestring::utf32str!("History performance measurements"));

        (iothread, widestring::utf32str!("iothread"), widestring::utf32str!("Background IO thread events"));
        (fd_monitor, widestring::utf32str!("fd-monitor"), widestring::utf32str!("FD monitor events"));

        (term_support, widestring::utf32str!("term-support"), widestring::utf32str!("Terminal feature detection"));

        (reader, widestring::utf32str!("reader"), widestring::utf32str!("The interactive reader/input system"));
        (reader_render, widestring::utf32str!("reader-render"), widestring::utf32str!("Rendering the command line"));
        (complete, widestring::utf32str!("complete"), widestring::utf32str!("The completion system"));
        (path, widestring::utf32str!("path"), widestring::utf32str!("Searching/using paths"));

        (screen, widestring::utf32str!("screen"), widestring::utf32str!("Screen repaints"));
    );
}

/// Write to our FLOG file.
pub fn flog_impl(s: &str) {
    let fd = get_flog_file_fd().0 as RawFd;
    if fd < 0 {
        return;
    }
    let mut file = unsafe { std::fs::File::from_raw_fd(fd) };
    let _ = file.write(s.as_bytes());
    // Ensure the file is not closed.
    file.into_raw_fd();
}

macro_rules! FLOG {
    ($category:ident, $($elem:expr),+) => {
        if crate::flog::categories::$category.enabled.load(std::sync::atomic::Ordering::Relaxed) {
            let mut vs = Vec::new();
            $(
                vs.push(format!("{:?}", $elem));
            )+
            // We don't use locking here so we have to append our own newline to avoid multiple writes.
            let mut v = vs.join(" ");
            v.push('\n');
            crate::flog::flog_impl(&v);
        }
    };
}
pub(crate) use FLOG;

/// For each category, if its name matches the wildcard, set its enabled to the given sense.
fn apply_one_wildcard(wc_esc: &wstr, sense: bool) {
    let wc = parse_util_unescape_wildcards(&wc_esc.to_ffi());
    let mut match_found = false;
    for cat in categories::all_categories() {
        if wildcard_match(&cat.name.to_ffi(), &wc, false) {
            cat.enabled.store(sense, Ordering::Relaxed);
            match_found = true;
        }
    }
    if !match_found {
        eprintln!("Failed to match debug category: {wc_esc}");
    }
}

/// Set the active flog categories according to the given wildcard \p wc.
pub fn activate_flog_categories_by_pattern(wc_ptr: &wstr) {
    let mut wc: WString = wc_ptr.into();
    // Normalize underscores to dashes, allowing the user to be sloppy.
    for c in wc.as_char_slice_mut() {
        if *c == '_' {
            *c = '-';
        }
    }
    for s in wc.as_char_slice().split(|c| *c == ',') {
        if s.starts_with(&['-']) {
            apply_one_wildcard(wstr::from_char_slice(&s[1..]), false);
        } else {
            apply_one_wildcard(wstr::from_char_slice(s), true);
        }
    }
}
