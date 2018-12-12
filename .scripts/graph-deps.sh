#!/bin/bash
#
# Generate a dependency graph of a C/C++ project directory.
#
# Example usage:
#    $ ./graph-deps.sh /home/user/my-project | dot -Tpng -o/tmp/deps.png
#

# TODO: handle relative paths
# TODO: strip shared root directory

main() {
    local TARGET_DIRECTORY="$1"
    [ ! -d "$TARGET_DIRECTORY" ] && echo "target directory not found: $TARGET_DIRECTORY" 1>&2 && return 1

    # parse
    declare -A MATCHES
    pushd "$TARGET_DIRECTORY" &> /dev/null
    for MATCH in $(find . -name '*\.[ch]pp' -print0 | xargs -0 grep '#include' | tr -d '"' | tr -d '<' | tr -d '>' | sed 's/#include //g'); do
        local FOO="${MATCH:2}"
        # echo "$MATCH == $FOO"
        local KEY="${FOO%%:*}"
        local VALUE="${FOO##*:}"
        MATCHES[$KEY]+=" $VALUE"
        # echo "[$KEY] $VALUE"
    done
    popd &> /dev/null

    # return 0

    # dot output
    printf "digraph {\n"
    for SOURCE in "${!MATCHES[@]}"; do
        printf "  \"$SOURCE\" -> {"
        for TARGET in ${MATCHES[$SOURCE]}; do
            printf " \"$TARGET\""
        done
        printf " };\n"
    done
    echo "}"
}

main "$@"
exit $?

