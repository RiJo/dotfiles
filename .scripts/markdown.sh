#!/bin/bash
#
#   Bash markdown syntax highligter
#
# TODO:
#   - pass '-l' to pipe to less
#   - parse italics, bold, etc
#   - parse links: "[link](http://example.com)"
#   - Add numbering to headers
#   - Add numbering to bullet lists
#

md_format() {
    local TARGET_LINE="$1"
    local NEXT_LINE="$2"

    local COLOR_BLACK="\033[0;30m"
    local COLOR_BLUE="\033[0;34m"
    local COLOR_GREEN="\033[0;32m"
    local COLOR_CYAN="\033[0;36m"
    local COLOR_RED="\033[0;31m"
    local COLOR_PURPLE="\033[0;35m"
    local COLOR_BROWN="\033[0;33m"
    local COLOR_LIGHTGRAY="\033[0;37m"
    local COLOR_DARKGRAY="\033[1;30m"
    local COLOR_LIGHTBLUE="\033[1;34m"
    local COLOR_LIGHTGREEN="\033[1;32m"
    local COLOR_LIGHTCYAN="\033[1;36m"
    local COLOR_LIGHTRED="\033[1;31m"
    local COLOR_LIGHTPURPLE="\033[1;35m"
    local COLOR_YELLOW="\033[1;33m"
    local COLOR_WHITE="\033[1;37m"
    local COLOR_RESET="\033[0m"

    # Regular expressions
    local REGEX_HEADER='^#{1,6} .*$'
    local REGEX_H1_ALT="^={${#TARGET_LINE}}\$"
    local REGEX_H2_ALT="^-{${#TARGET_LINE}}\$"
    local REGEX_LIST_UNORDERED='^(  )?[*+-] .*$'
    local REGEX_LIST_ORDERED='^(  )?[0-9]+ .*$'

    # Headers
    if [[ "${TARGET_LINE}" =~ $REGEX_HEADER ]]; then
        printf "${COLOR_YELLOW}${TARGET_LINE}${COLOR_RESET}"
    elif [[ "$NEXT_LINE" =~ $REGEX_H1_ALT ]]; then
        printf "${COLOR_YELLOW}${TARGET_LINE}${COLOR_RESET}"
    elif [[ "$NEXT_LINE" =~ $REGEX_H2_ALT ]]; then
        printf "${COLOR_YELLOW}${TARGET_LINE}${COLOR_RESET}"
    # Lists
    elif [[ "$TARGET_LINE" =~ $REGEX_LIST_UNORDERED ]]; then
        printf "${COLOR_GREEN}${TARGET_LINE}${COLOR_RESET}"
    elif [[ "$TARGET_LINE" =~ $REGEX_LIST_ORDERED ]]; then
        printf "${COLOR_BLUE}${TARGET_LINE}${COLOR_RESET}"
    # Default text
    elif [ -z "$TARGET_LINE" ]; then
        printf "${TARGET_LINE}"
    else
        printf "${COLOR_WHITE}${TARGET_LINE}${COLOR_RESET}"
    fi
    printf "\n"
}

main() {
    local MD_FILE="$1"
    if [ -z "$MD_FILE" ]; then
        echo "No target markdown file given"
        return 1
    elif [ ! -f "$MD_FILE" ]; then
        echo "Could not find markdown file given: $MD_FILE"
        return 1
    fi

    local PREVIOUS_LINE='\0' # Null character used to ignore first line
    while IFS='\n' read LINE; do
        if [ "$PREVIOUS_LINE" != '\0' ]; then
            md_format "$PREVIOUS_LINE" "$LINE"
        fi
        PREVIOUS_LINE="$LINE"
    done < "$MD_FILE"
    md_format "$PREVIOUS_LINE" ""
}

main "$@"
exit $?
