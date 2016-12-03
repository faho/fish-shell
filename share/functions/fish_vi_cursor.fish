function fish_vi_cursor -d 'Set cursor shape for different vi modes'
    # Check hard if we are in a supporting terminal.
    #
    # Challenges here are term-in-a-terms (emacs ansi-term does not support this, tmux does),
    # that we can only figure out if we are in konsole/iterm/vte via exported variables,
    # and ancient xterm versions.
    #
    # tmux defaults to $TERM = screen, but can do this if it is in a supporting terminal.
    # Unfortunately, we can only detect this via the exported variables, so we miss some cases.
    #
    # We will also miss some cases of terminal-stacking,
    # e.g. tmux started in suckless' st (no support) started in konsole.
    # But since tmux in konsole seems rather common and that case so uncommon,
    # we will just fail there (though it seems that tmux or st swallow it anyway).
    #
    # TERM = xterm is special because plenty of things claim to be it, but aren't fully compatible
    # This includes old vte-terms (without $VTE_VERSION), old xterms (without $XTERM_VERSION or < 280)
    # and maybe other stuff.

    if set -q INSIDE_EMACS
        return
    end

    # vte-based terms set $TERM = xterm*, but only gained support relatively recently.
    # From https://bugzilla.gnome.org/show_bug.cgi?id=720821, it appears it was version 0.40.0
    if set -q VTE_VERSION
        and test "$VTE_VERSION" -lt 4000 ^/dev/null
        return
    end

    # We don't use `tput Ss` here because there's nothing to be gained from it.
    # The sequence is a tmux extension that isn't included in e.g. macOS xterm definition (iTerm),
    # and we need another condition anyway.
    if not begin
            # (xterm or tmux) and (konsole or iterm or vte or new-xterm)
            begin
                begin # tmux
                    set -q TMUX
                    and string match -qr '^screen.*|^tmux.*' -- $TERM
                end
                or string match -q 'xterm*' -- $TERM
            end
            and begin set -q KONSOLE_PROFILE_NAME
                or set -q ITERM_PROFILE
                or set -q VTE_VERSION # no need to check which, we've done that before
                or begin
                    set -l xterm_version (string replace -r "XTerm\((\d+)\)" '$1' -- $XTERM_VERSION)
                    and test "$xterm_version" -ge 280 ^/dev/null
                end
            end
            # Other supporting terms via $TERM
            # This can't be included because unsupporting st versions are still in the wild
            # or begin
            #     string match -qr 'st*' -- $TERM
            # end
        end

        return
    end

    set -l terminal $argv[1]
    set -q terminal[1]
    or set terminal auto
    set -l uses_echo

    set -l function
    switch "$terminal"
        case auto
            if set -q KONSOLE_PROFILE_NAME
                set function __fish_cursor_konsole
                set uses_echo 1
            else if set -q ITERM_PROFILE
                set function __fish_cursor_1337
                set uses_echo 1
            else
                set function __fish_cursor_xterm
                set uses_echo 1
            end
        case konsole
            set function __fish_cursor_konsole
            set uses_echo 1
        case xterm
            set function __fish_cursor_xterm
            set uses_echo 1
    end

    set -l tmux_prefix
    set -l tmux_postfix
    if set -q TMUX
        and set -q uses_echo[1]
        set tmux_prefix echo -ne "'\ePtmux;\e'"
        set tmux_postfix echo -ne "'\e\\\\'"
    end

    set -q fish_cursor_unknown
    or set -g fish_cursor_unknown block blink

    echo "
          function fish_vi_cursor_handle --on-variable fish_bind_mode --on-event fish_postexec
              set -l varname fish_cursor_\$fish_bind_mode
              if not set -q \$varname
                set varname fish_cursor_unknown
              end
              $tmux_prefix
              $function \$\$varname
              $tmux_postfix
          end
         " | source

    echo "
          function fish_vi_cursor_handle_preexec --on-event fish_preexec
              set -l varname fish_cursor_default
              if not set -q \$varname
                set varname fish_cursor_unknown
              end
              $tmux_prefix
              $function \$\$varname
              $tmux_postfix
          end
         " | source
end

