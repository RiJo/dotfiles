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

load_test_data() {
    local TARGET_DIRECTORY="$1"
    pushd "$TARGET_DIRECTORY" &> /dev/null
    touch foo.hpp bar.hpp baz.hpp foo.cpp bar.cpp
    echo "#include \"foo.hpp\"" >> foo.cpp
    echo "#include \"bar.hpp\"" >> foo.cpp
    echo "#include \"bar.hpp\"" >> foo.hpp
    echo "#include \"baz.hpp\"" >> foo.hpp
    echo "#include \"bar.hpp\"" >> bar.cpp
    echo "#include \"baz.hpp\"" >> bar.cpp
    echo "#include \"foo.hpp\"" >> baz.hpp
    echo "#include <external>" >> baz.hpp
    popd &> /dev/null
}

main() {
    local TARGET_DIRECTORY="$1"
    local TEMP_DIRECTORY=
    if [ "$TARGET_DIRECTORY" == "--test" ]; then
        local TEMP_DIRECTORY="$(mktemp -d)"
        load_test_data "$TEMP_DIRECTORY"
        local TARGET_DIRECTORY="$TEMP_DIRECTORY"
        trap "rm -rf \"$TEMP_DIRECTORY\"" EXIT
    fi
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

