# Source file specific per computer
if [ -s ~/.bash_aliases.local ]; then
    source ~/.bash_aliases.local
fi

#alias h="history"
alias cp="cp -vi"
alias rm="rm -vi"
alias ls="ls --color"
alias ll="ls --color -lah"
alias lt="tree -C -L 2"
alias mkdir="mkdir -p"
alias tree="tree -C"
alias grep="grep --color"
alias less="less -R"
alias dus="dus --color -h -n"
alias md="~/.scripts/markdown.sh"

# This is GOLD for finding out what is taking so much space on your drives!
alias diskspace="du -S | sort -n -r | more"

# Show me the size (sorted) of only the folders in this directory
alias folders="find . -maxdepth 1 -type d -print | xargs du -sk | sort -rn"

# history command w/ support for eventual matching
h() {
    local MATCH="$@"
    if [ "$MATCH" ]; then
        history | grep "$MATCH"
    else
        history
    fi
}

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
