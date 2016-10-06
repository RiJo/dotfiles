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

# Placed after 'grep' alias to apply additional parameters
cmd_with_grep() {
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

# This is GOLD for finding out what is taking so much space on your drives!
alias diskspace="du -S | sort -n -r | more"

# Show me the size (sorted) of only the folders in this directory
alias folders="find . -maxdepth 1 -type d -print | xargs du -sk | sort -rn"

# "cd ../../../.." replaced by ".. 4"
..() {
    if [ -z "$1" ]; then
        cd ..
    elif [[ "$1" =~ [0-9]+ ]]; then
        for i in $(seq 1 $1); do cd ..; done
    else
        echo "NaN: $1" 1>&2
        return 1
    fi
}

# 
git-remote-delete() {
    if [ -z "$1" ]; then
        echo "No tag name given" 1>&2
        return 1
    fi
    local TAG_NAME="$1"

    if [ -z "$(git tag | grep "^${TAG_NAME}\$")" ]; then
        echo "Tag not found: ${TAG_NAME}" 1>&2
        return 2
    fi

    git tag -d "${TAG_NAME}"
    git push origin ":refs/tags/${TAG_NAME}"
}

# I can now run df -h|fawk 2 which saves a good bit of typing.
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
