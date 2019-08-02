# Source file specific per computer
if [ -s ~/.bashrc.local ]; then
    source ~/.bashrc.local
fi

#
# Environment
#

export EDITOR="/usr/bin/vim"
export GEDITOR="/usr/bin/gvim"
export VISUAL="$EDITOR"
export PAGER="less -R"
if [ -x "/usr/bin/terminology" ]; then
    export TERMINAL="/usr/bin/terminology"
else
    export TERMINAL="/usr/bin/xterm"
fi
if [ -x "/usr/bin/firefox-developer-edition" ]; then
    export WEBBROWSER="/usr/bin/firefox-developer-edition"
elif [ -x "/usr/bin/firefox-bin" ]; then
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

# Development
export BUILD_CC="/usr/bin/gcc" # Required to build GNU C library

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
# $PWD alter hook
#

# Called on bash spawn + after call to 'cd', 'pushd' or 'popd'
function pwd_altered_hook() {
    local PREV_PWD="$1"
    local CUR_PWD="$2"

    # git
    local PREV_GIT_ROOT="$(git-root "$PREV_PWD")"
    local CUR_GIT_ROOT="$(git-root "$CUR_PWD")"
    if [ "$PREV_GIT_ROOT" != "$CUR_GIT_ROOT" ]; then
        if [ "$PREV_GIT_ROOT" ]; then
            echo -e ">>> left git repo '\033[0;33m$(git-name "$PREV_GIT_ROOT/.git")\033[0m' <<<"
        fi
        if [ "$CUR_GIT_ROOT" ]; then
            echo -e ">>> entered git repo '\033[0;33m$(git-name "$CUR_GIT_ROOT/.git")\033[0m' <<<"
        fi
    fi

    # svn
    local PREV_SVN_ROOT="$(svn-root "$PREV_PWD")"
    local CUR_SVN_ROOT="$(svn-root "$CUR_PWD")"
    if [ "$PREV_SVN_ROOT" != "$CUR_SVN_ROOT" ]; then
        if [ "$PREV_SVN_ROOT" ]; then
            echo -e ">>> left svn repo '\033[0;33m$(svn-name "$PREV_SVN_ROOT")\033[0m' <<<"
        fi
        if [ "$CUR_SVN_ROOT" ]; then
            echo -e ">>> entered svn repo '\033[0;33m$(svn-name "$CUR_SVN_ROOT")\033[0m' <<<"
        fi
    fi
}

# Initial hook if bash is spawned inside repo
pwd_altered_hook "" "$PWD"

# Override builtin 'cd' command for pwd alter hook
function cd() {
    local PREV_PWD="$PWD"
    builtin cd "$@"
    local CUR_PWD="$PWD"
    if [ "$PREV_PWD" != "$CUR_PWD" ]; then
        pwd_altered_hook "$PREV_PWD" "$CUR_PWD"
    fi
}

# Override builtin 'pushd' command for pwd alter hook
function pushd() {
    local PREV_PWD="$PWD"
    # Note: default annoying stdout printout removed
    builtin pushd "$@" 1> /dev/null
    local CUR_PWD="$PWD"
    if [ "$PREV_PWD" != "$CUR_PWD" ]; then
        pwd_altered_hook "$PREV_PWD" "$CUR_PWD"
    fi
}

# Override builtin 'popd' command for pwd alter hook
function popd() {
    local PREV_PWD="$PWD"
    # Note: default annoying stdout printout removed
    builtin popd "$@" 1> /dev/null
    local CUR_PWD="$PWD"
    if [ "$PREV_PWD" != "$CUR_PWD" ]; then
        pwd_altered_hook "$PREV_PWD" "$CUR_PWD"
    fi
}

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

    if [ "$(whoami)" == "root" ]; then
        local USER_COLOR="$RED"
    else
        local USER_COLOR="$GREEN"
    fi
    export PS1="${WHITE}[${USER_COLOR}\W${WHITE}]${NO_COLOR}${BLUE}\$(__git_ps1)${NO_COLOR}\`${PS_EXIT_CODE}\` \$"
    export PS2="${WHITE}[${USER_COLOR}\W${WHITE}]${NO_COLOR} >"
}
set_bash_prompt

# Start X client
if [ "$(whoami)" != "root" ] && [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    # X is not running
    startx -- vt1; exit
    logout
else
    # X is running
    echo "Linux `uname -r` @ `date`"
fi

