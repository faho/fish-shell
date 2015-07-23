
# Completions for ps

# BSD-style options - in ps these can appear _everywhere_ (since it usually doesn't take files)
# A limitation here is that it only checks for the corresponding BSD-style option to determine whether something is already enabled
# i.e. "ps -A <TAB>" will still complete "a"
# The (commandline -ct) part enables argument grouping - otherwise "ps a<TAB>" would jump to the next argument because "a" is a valid option
# Hand fish "aT" instead so it sees that as a new option
# Another limitation is that after completion fish will jump to the next argument, so the user needs to do backward-char to add something to the group
complete -c ps -n "not __fish_seen_bsdoption_from --all a" -a "(commandline -ct)a" -d "Show all processes" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all T" -a "(commandline -ct)T" -d "Processes belonging to this terminal" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all r" -a "(commandline -ct)r" -d "Only running processes" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all x" -a "(commandline -ct)x" -d "Also processes without tty" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all j" -a "(commandline -ct)j" -d "Output BSD job control format" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all l" -a "(commandline -ct)l" -d "Output BSD long format" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all s" -a "(commandline -ct)s" -d "Output signal format" -f
complete -c ps -n "not __fish_seen_bsdoption_from --all u" -a "(commandline -ct)u" -d "Output user-oriented format" -f

complete -c ps -s A --description "Select all" -f
complete -c ps -s N --description "Invert selection" -f
complete -c ps -s a --description "Select all processes except session leaders and terminal-less" -f
complete -c ps -s d --description "Select all processes except session leaders" -f
complete -c ps -s e --description "Select all" -f
complete -c ps -l deselect --description "Deselect all processes that do not fulfill conditions" -f
complete -c ps -s C --description "Select by command" -ra '(__fish_complete_list , __fish_complete_proc)' -f
complete -c ps -s G -l Group --description "Select by group" -x -a "(__fish_complete_list , __fish_complete_groups)" -f
complete -c ps -s U -l User --description "Select by user" -x -a "(__fish_complete_list , __fish_complete_users)" -f
complete -c ps -s u -l user --description "Select by user" -x -a "(__fish_complete_list , __fish_complete_users)" -f
complete -c ps -s g -l group --description "Select by group/session" -x -a "(__fish_complete_list , __fish_complete_groups)" -f
complete -c ps -s p -l pid --description "Select by PID" -x -a "(__fish_complete_list , __fish_complete_pids)" -f
complete -c ps -l ppid --description "Select by parent PID" -x -a "(__fish_complete_list , __fish_complete_pids)" -f
complete -c ps -s s -l sid --description "Select by session ID" -x -a "(__fish_complete_list , __fish_complete_pids)" -f
complete -c ps -s t -l tty --description "Select by tty" -r -f
complete -c ps -s F --description "Extra full format" -f
complete -c ps -s O --description "User defined format" -x -f
complete -c ps -s M --description "Add column for security data" -f
complete -c ps -s c -d 'Show different scheduler information for the -l option' -f
complete -c ps -s f --description "Full format" -f
complete -c ps -s j --description "Jobs format" -f
complete -c ps -s l --description "Long format" -f
complete -c ps -s o -l format --description "User defined format" -x -f
complete -c ps -s y --description "Do not show flags" -f
complete -c ps -s Z -l context --description "Add column for security data" -f
complete -c ps -s H -l forest --description "Show hierarchy" -f
complete -c ps -s n --description "Set namelist file" -r -f
complete -c ps -s w --description "Wide output" -f
complete -c ps -l cols -l columns -l width -d 'Set screen width' -r -f
complete -c ps -l cumulative -d 'Include dead child process data' -f
complete -c ps -l headers -d 'Repead header lines, one per page' -f
complete -c ps -l no-headers -d 'Print no headers' -f
complete -c ps -l lines -l rows -d 'Set screen height' -r -f
complete -c ps -l sort -d 'Spericy sorting order' -r -f
complete -c ps -s L --description "Show threads. With LWP/NLWP" -f
complete -c ps -s T --description "Show threads. With SPID" -f
complete -c ps -s m -d 'Show threads after processes' -f
complete -c ps -s V -l version --description "Display version and exit" -f
complete -c ps -l help --description "Display help and exit" -f
complete -c ps -l info --description "Display debug info" -f
