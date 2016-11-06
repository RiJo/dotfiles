# Source file specific per computer
if [ -s ~/.bashrc.local ]; then
    source ~/.bashrc.local
fi

#
# Environment
#

export EDITOR="/usr/bin/vim"
export GEDITOR="/usr/bin/scite"
export VISUAL="$EDITOR"
export PAGER="less -R"
if [ -x "/usr/bin/terminology" ]; then
    export TERMINAL="/usr/bin/terminology"
else
    export TERMINAL="/usr/bin/xterm"
fi
if [ -x "/usr/bin/firefox-bin" ]; then
    export WEBBROWSER="/usr/bin/firefox-bin"
else
    export WEBBROWSER="/usr/bin/firefox"
fi

# This is where you put your hand rolled scripts (remember to chmod them)
export PATH="$HOME/bin:$PATH"

# Remove duplicates in bash history
#export HISTCONTROL=ignoredups
#export HISTCONTROL=erasedups
export HISTCONTROL="erasedups:ignoreboth"
export HISTSIZE=100
#export HISTIGNORE="h:h *"
#export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
export HISTTIMEFORMAT='%F %T '

# Automatically trim long paths in the prompt (requires Bash 4.x)
#export PROMPT_DIRTRIM=2

#so as not to be disturbed by Ctrl-S ctrl-Q in terminals:
stty -ixon

# Load xmodmap config
if [ -s ~/.Xmodmap ] && [ -x /usr/bin/xmodmap ]; then
    /usr/bin/xmodmap ~/.Xmodmap
fi

#
# shopt
#

#shopt -s histappend
# Combine multiline commands into one in history
#shopt -s cmdhist
#use extra globing features. See man bash, search extglob.
#shopt -s extglob
#include .files when globbing.
#shopt -s dotglob
#When a glob expands to nothing, make it an empty string instead of the literal characters.
#shopt -s nullglob
# fix spelling errors for cd, only in interactive shell
#shopt -s cdspell
# This will prevent you from accidentally destroying the content of an already existing file if you redirect output (>filename). You can always force overwriting with >|filename.
#shopt -o noclobber


#
# Aliases
#
if [ -s ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

#
# Console
#

set_bash_prompt() {
    # Define a few Color's
    local BLACK="\[\033[0;30m\]"
    local BLUE="\[\033[0;34m\]"
    local GREEN="\[\033[0;32m\]"
    local CYAN="\[\033[0;36m\]"
    local RED="\[\033[0;31m\]"
    local PURPLE="\[\033[0;35m\]"
    local BROWN="\[\033[0;33m\]"
    local LIGHTGRAY="\[\033[0;37m\]"
    local DARKGRAY="\[\033[1;30m\]"
    local LIGHTBLUE="\[\033[1;34m\]"
    local LIGHTGREEN="\[\033[1;32m\]"
    local LIGHTCYAN="\[\033[1;36m\]"
    local LIGHTRED="\[\033[1;31m\]"
    local LIGHTPURPLE="\[\033[1;35m\]"
    local YELLOW="\[\033[1;33m\]"
    local WHITE="\[\033[1;37m\]"
    local NO_COLOR="\[\033[0m\]"

    #local SMILEY="${WHITE}:)${NO_COLOR}"
    #local FROWNY="${RED}:(${NO_COLOR}"
    #local SELECT="FOO=\$?;if [ \$FOO = 0 ]; then echo \"${SMILEY}\"; else echo \"(\$FOO) ${FROWNY}\"; fi"
    local PS_EXIT_CODE="PS_TEMP=\$?;if [ \$PS_TEMP -ne 0 ]; then echo \" (${RED}\$PS_TEMP${NO_COLOR})\"; fi"

source /usr/share/git/completion/git-prompt.sh

    export PS1="${WHITE}[${GREEN}\W${WHITE}]${NO_COLOR}${BLUE}\$(__git_ps1)${NO_COLOR}\`${PS_EXIT_CODE}\` \$"
    export PS2="${WHITE}[${GREEN}\W${WHITE}]${NO_COLOR} >"
}
set_bash_prompt

# Start X client
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    # X is not running
    startx -- vt1; exit
    logout
else
    # X is running
    echo "Linux `uname -r` @ `date`"
fi

