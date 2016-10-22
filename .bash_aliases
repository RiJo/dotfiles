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
    dir-root "$PWD" ".svn"
}

# Get root path of eventual git repo of `pwd`
function git-root() {
    dir-root "$PWD" ".git"
}

# Override builtin cd command for git- and svn-hook triggers
# TODO: also override pushd, popd, and c/o
function cd() {
    local PREV_PWD="$PWD"
    local PREV_GIT_ROOT="$(git-root "$PWD")"
    local PREV_SVN_ROOT="$(svn-root "$PWD")"
    builtin cd "$@"
    local CUR_PWD="$PWD"
    if [ "$PREV_PWD" == "$CUR_PWD" ]; then
        return
    fi

    local CUR_GIT_ROOT="$(git-root "$CUR_PWD")"
    if [ "$PREV_GIT_ROOT" != "$CUR_GIT_ROOT" ]; then
        if [ "$PREV_GIT_ROOT" ]; then
            echo ">>> left git repo '$(basename "$(grep '.git' "$PREV_GIT_ROOT/.git/config")")' <<<"
        fi
        if [ "$CUR_GIT_ROOT" ]; then
            echo ">>> entered git repo '$(basename "$(grep '.git' "$CUR_GIT_ROOT/.git/config")")' <<<"
        fi
    fi

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

