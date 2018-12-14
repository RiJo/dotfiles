#!/bin/bash
#
# Generate a dependency graph of a C/C++ project directory.
#
# Example usage:
#    $ ./graph-deps.sh /home/user/my-project | dot -Tpng -o/tmp/deps.png
#

# TODO: handle extensions .c .cpp .cxx .h .hpp .hxx
# TODO: handle relative paths
# TODO: render warning: dependency on implementation (not abstraction)

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
    echo "#include \"baz.hpp\"" >> baz.hpp
    echo "#include <external>" >> baz.hpp
    popd &> /dev/null
}

# 0=normal, 1=indirect, 2=same, 3=circular
find_target() {
    declare -p REF &> /dev/null || local -n REF="$1"
    local SOURCE="$2"
    local TARGET="$3"
    local DEPS="$4"
    local HANDLED="$5"
    # echo "SOURCE=\"$SOURCE\", TARGET=\"$TARGET\", DEPS=\"$DEPS\", HANDLED=\"$HANDLED\""
    [ "$SOURCE" == "$TARGET" ] && return 0 # reference self
    for DEP in $DEPS; do
        [ "$DEP" == "$TARGET" ] && return 0 # found

        CIRCULAR=
        for TEMP in $HANDLED; do
            if [ "$DEP" == "$TEMP" ]; then
               CIRCULAR=1
               break
            fi
        done
        [ "$CIRCULAR" ] && continue # already handled

        HANDLED+=" $DEP"
        find_target REF "$SOURCE" "$TARGET" "${REF[$DEP]}" "$HANDLED" && return $?
    done
    return 1 # not found
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
        [ "${MATCH##*.}" == "cpp" ] && printf "    \"$MATCH\" [shape=box, style=filled, fillcolor=gray94] ;\n"
    done
    printf "  }\n"

    # abstraction nodes
    printf "  subgraph cluster_1 {\n"
    printf "    label=\"abstraction\";\n"
    for MATCH in $ALL_MATCHES; do
        [ "${MATCH##*.}" == "hpp" ] && printf "    \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray94] ;\n"
    done
    printf "  }\n"

    # undefined nodes
    printf "  subgraph cluster_1 {\n"
    printf "    label=\"abstraction\";\n"
    for MATCH in $ALL_MATCHES; do
        [ "${MATCH##*.}" != "hpp" ] && [ "${MATCH##*.}" != "cpp" ] && printf "    \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray98, color=gray55, fontcolor=gray55] ;\n"

    done
    printf "  }\n"

    # edges
    for SOURCE in "${!MATCHES[@]}"; do
        for TARGET in ${MATCHES[$SOURCE]}; do
            if [ "$SOURCE" == "$TARGET" ]; then
                printf "  \"$SOURCE\" -> \"$TARGET\" [color=red];\n" # self dependency
                continue
            fi

            find_target MATCHES "$TARGET" "$SOURCE" "${MATCHES[$TARGET]}"
            if [ $? -eq 0 ]; then
                printf "  \"$SOURCE\" -> \"$TARGET\" [color=red];\n" # circular dependency
                continue
            fi

            local OTHER_TARGETS=""
            for OTHER_TARGET in ${MATCHES[$SOURCE]}; do
                [ "$OTHER_TARGET" != "$TARGET" ] && OTHER_TARGETS+=" $OTHER_TARGET"
            done

            find_target MATCHES "$SOURCE" "$TARGET" "$OTHER_TARGETS" "$SOURCE"
            if [ $? -eq 0 ]; then
                # found in other (longer) branch
                if [ "${SOURCE%.*}" == "${TARGET%.*}" ]; then
                    printf "  \"$SOURCE\" -> \"$TARGET\" [style=dashed, color=blue];\n" # same name: implementation of abstraction
                else
                    printf "  \"$SOURCE\" -> \"$TARGET\" [style=dashed, color=gray55];\n"
                fi
            else
                if [ "${SOURCE%.*}" == "${TARGET%.*}" ]; then
                    printf "  \"$SOURCE\" -> \"$TARGET\" [color=blue];\n" # same name: implementation of abstraction
                else
                    printf "  \"$SOURCE\" -> \"$TARGET\";\n"
                fi
            fi
        done
    done
    echo "}"
}

main "$@"
exit $?

