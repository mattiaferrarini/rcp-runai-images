HISTCONTROL=ignoreboth

function _update_ps1() {
    PS1="$(/usr/local/bin/powerline-shell -git-mode simple -hostname-only-if-ssh -cwd-max-depth 5 -modules venv,cwd -error $? -jobs $(jobs -p | wc -l) -mode compatible -modules ssh,venv,cwd,git,root)"
}

if [ "$TERM" != "linux" ] && [ -f "/usr/local/bin/powerline-shell" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

alias ..="cd .."
alias ll="ls -lh"

# Activate the inherited Python 3.12 environment for training and metrics.
source /opt/venv/bin/activate > /dev/null 2>&1

# Start interactive shells in the user's shared MLBIO home directory.
[ "$(pwd)" = "/" ] && cd ~
