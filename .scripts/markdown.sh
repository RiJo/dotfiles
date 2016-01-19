#!/bin/bash
#
#   Bash markdown syntax highligter
#
# TODO:
#   - pass '-l' to pipe to less
#   - parse italics, bold, etc
#   - parse monospace/code (indented 4 spaces?)
#   - Add numbering to bullet lists
#   - Match multiple links on same line
#

# TODO: move into main()?
# Global scope
MD_HEADER_LEVEL= # TODO: store array?
MD_CODE_IN_BLOCK=0

md_get_header_index() {
    local TARGET_LEVEL="$1"
    local SUBLEVELS=(${MD_HEADER_LEVEL//./ })

    # Add missing sublevels (if long jump)
    local TARGET_SUBLEVELS=$((TARGET_LEVEL-1))
    if [ ${#SUBLEVELS[@]} -lt $TARGET_SUBLEVELS ]; then
        local MISSING_SUBLEVELS=$(($TARGET_SUBLEVELS-${#SUBLEVELS[@]}))
        for (( c=0; c<$MISSING_SUBLEVELS; c++ )); do
            SUBLEVELS+=('1')
        done
    fi

    # Strip exceeding sublevels
    local ROOT_LEVELS=("${SUBLEVELS[@]::((${TARGET_LEVEL}-1))}")

    # Calculate new level index
    local NEW_LEVEL=$((${SUBLEVELS[((${TARGET_LEVEL}-1))]}+1))

    # Generate result
    local RESULT="${ROOT_LEVELS[@]}"
    if [ "$RESULT" ]; then
        RESULT="${RESULT}."
    fi
    RESULT="${RESULT}${NEW_LEVEL}"
    echo "${RESULT// /.}"
}

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

    # Colors in use
    local COLOR_MD_DEFAULT="${COLOR_WHITE}"
    local COLOR_MD_HEADER="${COLOR_YELLOW}"
    local COLOR_MD_LIST="${COLOR_LIGHTGREEN}"
    local COLOR_MD_LINK="${COLOR_LIGHTBLUE}"
    local COLOR_MD_CODE="${COLOR_PURPLE}"

    # Regular expressions
    local REGEX_HEADER='^(#{1,6}) ([^#]*).*$'
    local REGEX_H1_ALT="^={${#TARGET_LINE}}\$"
    local REGEX_H2_ALT="^-{${#TARGET_LINE}}\$"
    local REGEX_LIST_UNORDERED='^(  )?[*+-] (.*)$'
    local REGEX_LIST_ORDERED='^(  )?[0-9]+ (.*)$'
    local REGEX_LINK='^(.*)\[(.*)\](\(([^)]*)\))?(.*)$'
    local REGEX_CODE_BLOCK1='^(.*)?`{3}(.*)?$'
    local REGEX_CODE_BLOCK2='^ {4}(.*)?$'
    local REGEX_CODE_INLINE='^(.*)`(.*)`(.*)$'

    # Headers
    if [[ "${TARGET_LINE}" =~ $REGEX_HEADER ]]; then
        local HEADER_INDEX="$(md_get_header_index "${#BASH_REMATCH[1]}")"
        export MD_HEADER_LEVEL="$HEADER_INDEX" # TODO: move into md_get_header_index()
        printf "${COLOR_MD_HEADER}${HEADER_INDEX} ${BASH_REMATCH[2]}${COLOR_RESET}"
    elif [[ "$NEXT_LINE" =~ $REGEX_H1_ALT ]]; then
        printf "${COLOR_MD_HEADER}${TARGET_LINE}${COLOR_RESET}"
    elif [[ "$NEXT_LINE" =~ $REGEX_H2_ALT ]]; then
        printf "${COLOR_MD_HEADER}${TARGET_LINE}${COLOR_RESET}"
    # Lists
    elif [[ "$TARGET_LINE" =~ $REGEX_LIST_UNORDERED ]]; then
        printf "${COLOR_MD_LIST}${BASH_REMATCH[1]}*${COLOR_MD_DEFAULT} ${BASH_REMATCH[2]}${COLOR_RESET}"
    elif [[ "$TARGET_LINE" =~ $REGEX_LIST_ORDERED ]]; then
        printf "${COLOR_MD_LIST}${BASH_REMATCH[1]}#${COLOR_MD_DEFAULT} ${BASH_REMATCH[2]}${COLOR_RESET}"
    # Links
    elif [[ "$TARGET_LINE" =~ $REGEX_LINK ]]; then
        if [ -z "${BASH_REMATCH[3]}" ]; then
            printf "${COLOR_MD_DEFAULT}${BASH_REMATCH[1]}${COLOR_MD_LINK}${BASH_REMATCH[2]}${COLOR_MD_DEFAULT}${BASH_REMATCH[5]}${COLOR_RESET}"
        else
            printf "${COLOR_MD_DEFAULT}${BASH_REMATCH[1]}${COLOR_MD_LINK}${BASH_REMATCH[2]} (${BASH_REMATCH[4]})${COLOR_MD_DEFAULT}${BASH_REMATCH[5]}${COLOR_RESET}"
        fi
    # Code
    elif [[ "$TARGET_LINE" =~ $REGEX_CODE_BLOCK1 ]]; then
        [[ MD_CODE_IN_BLOCK -eq 0 ]] && MD_CODE_IN_BLOCK=1 || MD_CODE_IN_BLOCK=0
        if [ -z "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" ]; then
            return 0
        fi
        printf "${COLOR_MD_CODE}${BASH_REMATCH[1]}${BASH_REMATCH[2]}${COLOR_RESET}"
    elif [[ "$TARGET_LINE" =~ $REGEX_CODE_BLOCK2 ]]; then
        printf "${COLOR_MD_CODE}${BASH_REMATCH[1]}${COLOR_RESET}"
        [[ "$NEXT_LINE" =~ $REGEX_CODE_BLOCK2 ]] && MD_CODE_IN_BLOCK=1 || MD_CODE_IN_BLOCK=0
    elif [ $MD_CODE_IN_BLOCK -ne 0 ]; then
        printf "${COLOR_MD_CODE}${TARGET_LINE}${COLOR_RESET}"
    elif [[ "$TARGET_LINE" =~ $REGEX_CODE_INLINE ]]; then
        printf "${COLOR_MD_DEFAULT}${BASH_REMATCH[1]}${COLOR_MD_CODE}${BASH_REMATCH[2]}${COLOR_MD_DEFAULT}${BASH_REMATCH[3]}${COLOR_RESET}"
    # Default text
    elif [ -z "$TARGET_LINE" ]; then
        printf "${TARGET_LINE}"
    else
        printf "${COLOR_MD_DEFAULT}${TARGET_LINE}${COLOR_RESET}"
    fi
    printf "\n"

    return 0
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
