#!/bin/bash
#
#   Parse config files a´la git-config.
#
# TODO:
#   - Make header matching dynamic: handle other formats of config file
#

config_parse_line() {
    local CURRENT_LINE="$1"
    local NEXT_LINE="$2"
    local TARGET_HEADER="$3"

    if [[ "$CURRENT_LINE" =~ ^\[.*\]$ ]]; then
        CONFIG_LAST_HEADER="$CURRENT_LINE"
    elif [ "$CONFIG_LAST_HEADER" == "[$TARGET_HEADER]" ]; then
        # Note: trim string (no double quotes around)
        echo $CURRENT_LINE
    fi
}

main() {
    local CONFIG_FILE="$1"
    if [ -z "$CONFIG_FILE" ]; then
        echo "No config file given." 1>&2
        return 1
    elif [ ! -f "$CONFIG_FILE" ]; then
        echo "No a file: $CONFIG_FILE"
        return 1
    fi

    local CONFIG_HEADER="$2"
    if [ -z "$CONFIG_HEADER" ]; then
        echo "No target header given." 1>&2
        return 1
    fi

    # Global scope
    local CONFIG_LAST_HEADER=

    local PREVIOUS_LINE='\0' # Null character used to ignore first line
    while IFS=$'\n' read LINE; do
        if [ "$PREVIOUS_LINE" != '\0' ]; then
            config_parse_line "$PREVIOUS_LINE" "$LINE" "$CONFIG_HEADER"
        fi
        PREVIOUS_LINE="$LINE"
    done < "$CONFIG_FILE"
    config_parse_line "$PREVIOUS_LINE" "" "$CONFIG_HEADER"

    return 0
}

main "$@"
exit $?
