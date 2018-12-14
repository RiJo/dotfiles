#!/bin/bash
#
# Generate a dependency graph of a C/C++ project directory.
#
# Example usage:
#    $ ./graph-deps.sh /home/user/my-project | dot -Tpng -o/tmp/deps.png
#

# TODO: handle relative paths
# TODO: render varnings: cross deps, dependency on implementation (not abstraction)
# TODO: render fainted: dependency already added by parent
# TODO: render abstractions vs. realizations(?)/implementations

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

    local ALL_MATCHES="$(echo ${MATCHES[@]} ${!MATCHES[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ')"

    # dot output
    printf "digraph {\n"
    printf "  rankdir=BT;\n"
    printf "  clusterrank=none;\n"
    printf "  ranksep=1.0;\n"
    printf "  nodesep=1.0;\n"
    # printf "  rank=max;\n"
    # printf "  splines=line;\n"

    # implementation
    printf "  subgraph cluster_0 {\n"
    printf "    label=\"implementation\";\n"
    for MATCH in $ALL_MATCHES; do
        [ "${MATCH##*.}" == "cpp" ] && printf "    \"$MATCH\";\n"
    done
    printf "  }\n"

    # abstraction
    printf "  subgraph cluster_1 {\n"
    printf "    label=\"abstraction\";\n"
    for MATCH in $ALL_MATCHES; do
        [ "${MATCH##*.}" == "hpp" ] && printf "    \"$MATCH\";\n"
    done
    printf "  }\n"

    # edges
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

