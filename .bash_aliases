# Source file specific per computer
if [ -s ~/.bash_aliases.local ]; then
    source ~/.bash_aliases.local
fi

# Core aliases
alias cp="cp -vi"
alias rm="rm -vi"
alias ls="ls --color"
alias ll="ls --color -lah"
alias lt="tree -C -L 2"
alias mkdir="mkdir -p"
alias tree="tree -C -A"
alias grep="grep --color"
alias less="less -R"
alias dus="dus --color -h -n"

# Find first occurence of target in parent directories bottom-up
function dir-root() {
    local SOURCE_DIR="$1"
    local TARGET="$2"

    if [ -z "$SOURCE_DIR" ]; then
        return 1
    fi

    if [ -e "$SOURCE_DIR/$TARGET" ]; then
        echo "$SOURCE_DIR"
        return 0
    fi

    if [ "$SOURCE_DIR" == "/" ]; then
        return 1
    fi

    dir-root "$(dirname "$SOURCE_DIR")" "$TARGET"
}

# Get root path of eventual svn repo of `pwd`
function svn-root() {
    if  [ $# == 0 ]; then
        dir-root "$PWD" ".svn"
    else
        dir-root "$@" ".svn"
    fi
}

# Get root path of eventual git repo of `pwd`
function git-root() {
    if  [ $# == 0 ]; then
        dir-root "$PWD" ".git"
    else
        dir-root "$@" ".git"
    fi
}

# Called on bash spawn + after call to 'cd', 'pushd' or 'popd'
function pwd_altered_hook() {
    local PREV_PWD="$1"
    local CUR_PWD="$2"

    # git
    local PREV_GIT_ROOT="$(git-root "$PREV_PWD")"
    local CUR_GIT_ROOT="$(git-root "$CUR_PWD")"
    if [ "$PREV_GIT_ROOT" != "$CUR_GIT_ROOT" ]; then
        if [ "$PREV_GIT_ROOT" ]; then
            echo ">>> left git repo '$(basename "$(grep '.git' "$PREV_GIT_ROOT/.git/config")")' <<<"
        fi
        if [ "$CUR_GIT_ROOT" ]; then
            echo ">>> entered git repo '$(basename "$(grep '.git' "$CUR_GIT_ROOT/.git/config")")' <<<"
        fi
    fi

    # svn
    local PREV_SVN_ROOT="$(svn-root "$PREV_PWD")"
    local CUR_SVN_ROOT="$(svn-root "$CUR_PWD")"
    if [ "$PREV_SVN_ROOT" != "$CUR_SVN_ROOT" ]; then
        if [ "$PREV_SVN_ROOT" ]; then
            echo ">>> left svn repo 'TODO' <<<"
        fi
        if [ "$CUR_SVN_ROOT" ]; then
            echo ">>> entered svn repo 'TODO' <<<"
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

# Placed after 'grep' alias to apply additional parameters
function cmd_with_grep() {
    if [ $# -gt 1 ]; then
        local COMMAND="${@:1:(($#-1))}"
        local MATCH="${@:$#}"
        echo "$COMMAND | grep \"$MATCH\""
        $COMMAND | grep "$MATCH"
    else
        local COMMAND="${@}"
        echo "$COMMAND"
        $COMMAND
    fi
}

# Special aliases
alias h="cmd_with_grep history"
alias md="~/.scripts/markdown.sh"

# "cd ../../../.." replaced by ".. 4"
function ..() {
    if [ -z "$1" ]; then
        cd ..
    elif [[ "$1" =~ [0-9]+ ]]; then
        for i in $(seq 1 $1); do cd ..; done
    else
        echo "NaN: $1" 1>&2
        return 1
    fi
}

# "awk '{print 2}'" replaced by "fawk 2"
function fawk {
    if [[ ! "$1" =~ [0-9]+ ]]; then
        echo "NaN: $1" 1>&2
        return 1
    fi

    local FIRST="awk '{print "
    local LAST="}'"
    local CMD="${FIRST}\$${1}${LAST}"
    eval $CMD
}

