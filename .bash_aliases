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

    if [ -z "$SOURCE_DIR" ] || [ "$SOURCE_DIR" == "/" ]; then
        return 1 # base case
    fi

    if [ -e "$SOURCE_DIR/$TARGET" ]; then
        echo "$SOURCE_DIR"
        return 0
    fi

    dir-root "$(dirname "$SOURCE_DIR")" "$TARGET"
}

# Get root path of eventual svn repo of `pwd`
function svn-root() {
    if  [ $# == 0 ] && [ "$PWD" ]; then
        svn-root "$PWD"
    else
        dir-root "$@" ".svn"
    fi
}

# Get root path of eventual git repo of `pwd`
function git-root() {
    if  [ $# == 0 ] && [ "$PWD" ]; then
        git-root "$PWD"
    else
        dir-root "$@" ".git"
    fi
}

function svn-name() {
    if  [ $# == 0 ]; then
        svn-name "$(svn-root)" # Evaluate current directory
    elif [ -d "${@}" ]; then
        local SVN_NAME="$(svn info "${@}" | grep '^URL:' | sed 's/: /:/g' | cut -d: -f2- | rev | cut -d'/' -f1 | cut -d':' -f1 | rev)"
        if [ "$SVN_NAME" ]; then
            echo "$SVN_NAME"
        else
            echo "$(dirname "${@}")"
        fi
    else
        echo "Not a svn repo" 1>&2
        return 1
    fi
}

function git-name() {
    if  [ $# == 0 ]; then
        git-name "$(git-root)/.git" # Evaluate current directory
    else
        if [ -d "${@}" ]; then
            # Normal git repo
            if [ -f "${@}/config" ]; then
                # TODO: handle different url definitions:
                # - remote.origin.url=https://github.com/RiJo/dotfiles.git
                # - remote.origin.url=git@server.com:repo.git
                local GIT_NAME="$(git config --file "${@}/config" --list | grep '^remote.origin.url' | cut -d= -f2- | rev | cut -d'/' -f1 | cut -d':' -f1 | rev)"
                if [ "$GIT_NAME" ]; then
                    echo "$GIT_NAME" # Remote repo name
                else
                    echo "$(dirname "${@}")" # No remote: pick directory name
                fi
            elif [ -e "${@}/.git" ]; then
                git-name "${@}/.git"
            else
                echo "Git config file not found: ${@}/config" 1>&2
                return 1
            fi
        elif [ -f "${@}" ]; then
            # Git submodule repo
            local SUBMODULE_CONFIG="$(cat "${@}" | grep '^gitdir:' | sed 's/: /:/g' | cut -d: -f2-)"
            if [ "$SUBMODULE_CONFIG" ]; then
                git-name "$(readlink -f "$(dirname "${@}")/$SUBMODULE_CONFIG")"
            else
                echo "Git submodule config file invalid: ${@}" 1>&2
                return 1
            fi
        else
            echo "Not a git repo" 1>&2
            return 1
        fi
    fi
}

function git-describe() {
    if [ -z "$(git-root)" ]; then
        echo "No a git repo" 1>&2
        return 1
    fi

    local TAG_NAMES="$(git show-ref --tags | grep "$(git rev-parse --short HEAD)")"
    if [ "$TAG_NAMES" ]; then
        git describe --always --tag
    else
        local BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
        local COMMIT_HASH="$(git rev-parse --short HEAD)"
        echo "${BRANCH_NAME}-${COMMIT_HASH}"
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
            echo ">>> left git repo '$(git-name "$PREV_GIT_ROOT/.git")' <<<"
        fi
        if [ "$CUR_GIT_ROOT" ]; then
            echo ">>> entered git repo '$(git-name "$CUR_GIT_ROOT/.git")' <<<"
        fi
    fi

    # svn
    local PREV_SVN_ROOT="$(svn-root "$PREV_PWD")"
    local CUR_SVN_ROOT="$(svn-root "$CUR_PWD")"
    if [ "$PREV_SVN_ROOT" != "$CUR_SVN_ROOT" ]; then
        if [ "$PREV_SVN_ROOT" ]; then
            echo ">>> left svn repo '$(svn-name "$PREV_SVN_ROOT")' <<<"
        fi
        if [ "$CUR_SVN_ROOT" ]; then
            echo ">>> entered svn repo '$(svn-name "$CUR_SVN_ROOT")' <<<"
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
alias repos="find . -type d -name '.git' -o -name '.svn'"

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

