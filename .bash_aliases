# Aliases are not expanded when the shell is not interactive, unless the expand_aliases shell
# option is set using shopt (see the description of shopt under SHELL BUILTIN COMMANDS below).
shopt -s expand_aliases

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
alias cal="cal -w -m -3"
alias shellcheck="shellcheck -Cauto"

# Helper function to retrieve user input and filter invalid entries.
function ask() {
    local VALID_KEYS=("${@:2}")
    local MESSAGE="$1 ($(IFS=, ;echo "${VALID_KEYS[*]}")): "

    local KEY=
    while [ -z "$KEY" ]; do
        local TEMP
        read -s -r -p "$MESSAGE" -n 1 TEMP 1>&2
        for VALID_KEY in ${VALID_KEYS[@]}; do [[ "$VALID_KEY" == "$TEMP" ]] && KEY="$TEMP" && break; done;
        [[ -z "$KEY" ]] && printf "$TEMP\n" 1>&2
    done
    echo $KEY 1>&2
    echo $KEY
}

# Helper function to create a shell script and open it in $EDITOR.
function mkscript() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "usage: mkscript <shell> [<filename>] [<template>]" 1>&2
        return 1
    fi

    local SCRIPT_ENV="$1"
    if [ ! -x "$SCRIPT_ENV" ]; then
        echo "invalid script environment: $SCRIPT_ENV" 1>&2
        return 2
    fi

    local FILE_PATH="$2"
    if [ -e "$FILE_PATH" ]; then
        echo "file aleady exists: $FILE_PATH" 1>&2
        return 3
    elif [ -z "$FILE_PATH" ] || [ "$FILE_PATH" == "-" ]; then
        local FILE_PATH="$(mktemp)"
        echo "temporary file created: $FILE_PATH"
    fi

    local TEMPLATE="${@:3}"

    touch "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo "failed to create file: $FILE_PATH" 1>&2
        return 4
    fi

    echo "#!$SCRIPT_ENV" > "$FILE_PATH"
    if [ "$TEMPLATE" ]; then
        printf "$TEMPLATE\n" >> "$FILE_PATH"
    fi
    chmod +x "$FILE_PATH"
    $EDITOR "$FILE_PATH"
}

# Helper function to create a bash script and open it in $EDITOR.
function mksh() {
    mkscript /bin/sh $@
}

# Helper function to create a bash script and open it in $EDITOR.
function mkbash() {
    local TEMPLATE="${@:2}"
    if [ -z "$TEMPLATE" ]; then
        local TEMPLATE='\nmain() {\n\treturn 0\n}\n\nmain "$@"\nexit $?\n'
    fi

    mkscript /bin/bash "$1" "$TEMPLATE"
}

# Helper function to create a python script and open it in $EDITOR.
function mkpython() {
    mkscript /bin/python $@
}

# Helper function to open file in $EDITOR for editing and then dump a unified diff.
function mkpatch() {
    if [ -z "$1" ]; then
        echo "usage: mkpatch <file to patch> [<optional header>]" 1>&2
        return 1
    fi
    local FILE_TO_PATCH="$1"
    if [ ! -f "$FILE_TO_PATCH" ]; then
        echo "file not found: $FILE_TO_PATCH" 1>&2
        return 2
    fi

    local OPTIONAL_HEADER="${@:2}"

    # Note: stdout is redirected to sterr for vim to prevent clobbering in output if mkpatch is piped into a file.
    cp -i "$FILE_TO_PATCH" "$FILE_TO_PATCH.orig" 1>&2
    if [ $? -ne 0 ]; then
        echo "failed to copy .orig file" 1>&2
        return 3
    fi
    $EDITOR "$FILE_TO_PATCH" 1>&2
    if [ $? -ne 0 ]; then
        echo "$EDITOR aborted" 1>&2
        return 4
    fi

    if [ "$OPTIONAL_HEADER" ]; then
        echo "$OPTIONAL_HEADER"
    fi
    diff -u -s "$FILE_TO_PATCH.orig" "$FILE_TO_PATCH" | sed "s|$FILE_TO_PATCH.orig|$FILE_TO_PATCH|g" | sed 's/^--- /--- a\//g' | sed 's/^+++ /+++ b\//g'

    rm -i "$FILE_TO_PATCH.orig" 1>&2
}

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

    local TARGET_HASH="HEAD"
    if [ "$1" ]; then
        local TARGET_HASH="$1"
    fi

    local TAG_NAMES="$(git describe --exact-match --tags "${TARGET_HASH}" 2> /dev/null)"
    if [ "${TAG_NAMES}" ]; then
        echo ${TAG_NAMES}
        return 0
    fi

    local BRANCH_NAME="$(git rev-parse --abbrev-ref "${TARGET_HASH}")"
    local COMMIT_HASH="$(git rev-parse --short "${TARGET_HASH}")"
    if [ "${BRANCH_NAME}" ]; then
        echo "${BRANCH_NAME}-${COMMIT_HASH}"
    else
        echo "${COMMIT_HASH}"
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

