#RUN: %fish %s
#REQUIRES: command -v tmux

isolated-tmux-start
isolated-tmux send-keys 'echo "foo bar baz"' Enter C-l
isolated-tmux send-keys 'echo '
isolated-tmux send-keys M-Right
tmux-sleep
isolated-tmux capture-pane -p
# CHECK: prompt 1> echo "foo bar baz"

touch COMPL

# Regression test.
isolated-tmux send-keys C-u C-l ': sometoken' M-b c
tmux-sleep
isolated-tmux capture-pane -p
# CHECK: prompt 1> : csometoken

# Test that we get completion autosuggestions also when the cursor is not at EOL.
isolated-tmux send-keys C-u 'complete nofilecomp -f' Enter C-l 'nofilecomp ./CO' C-a M-d :
tmux-sleep
isolated-tmux capture-pane -p
# CHECK: prompt 2> : ./COMPL

isolated-tmux send-keys C-u C-k C-l ': ./CO'
isolated-tmux send-keys A C-h
tmux-sleep
isolated-tmux capture-pane -p
# CHECK: prompt 2> : ./COMPL

isolated-tmux send-keys C-u 'echo (echo)' Enter
isolated-tmux send-keys C-l 'echo ('
tmux-sleep
isolated-tmux capture-pane -p
# CHECK: prompt 3> echo (echo)
