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

usage() {
    echo "usage: $(basename "$0") [--abs] [--mod] [--help] [--test]"
    echo "    --abs         Group by abstraction"
    echo "    --mod         Group by modules"
    echo "    --help        Print this help and exit"
    echo "    --test        Generate test project and use as target"
}

load_test_data() {
    local TARGET_DIRECTORY="$1"
    pushd "$TARGET_DIRECTORY" &> /dev/null
    mkdir -p a/b
    touch foo.hpp a/bar.hpp a/circular.hpp a/b/baz.hpp foo.cpp a/bar.cpp
    echo "#include \"foo.hpp\"" >> foo.cpp
    echo "#include \"a/bar.hpp\"" >> foo.cpp
    echo "#include \"a/bar.hpp\"" >> foo.hpp
    echo "#include \"a/b/baz.hpp\"" >> foo.hpp
    echo "#include \"a/bar.hpp\"" >> a/bar.cpp
    echo "#include \"a/b/baz.hpp\"" >> a/bar.cpp
    echo "#include \"a/circular.hpp\"" >> a/bar.cpp
    echo "#include \"a/bar.cpp\"" >> a/circular.hpp
    echo "#include \"a/bar.hpp\"" >> a/bar.hpp
    echo "#include <external>" >> a/b/baz.hpp
    popd &> /dev/null
}

find_target() {
    declare -p REF &> /dev/null || local -n REF="$1"
    local SOURCE="$2"
    local TARGET="$3"
    local DEPS="$4"
    local HANDLED="$5"

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
    local TARGET_DIRECTORY=
    local GROUP_BY=
    local TEST=
    while [ "$1" ]; do
        case "$1" in
            --abs) GROUP_BY=abstraction ;;
            --mod) GROUP_BY=module ;;
            --help) usage; return 0 ;;
            --test) TEST=1 ;;
            *) TARGET_DIRECTORY="$1" ;;
        esac
        shift
    done

    local TEMP_DIRECTORY=
    if [ "$TEST" ]; then
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

    # output graph
    printf "digraph {\n"
    printf "  rankdir=BT;\n"
    [ -z "$GROUP_BY" ] && printf "  clusterrank=none;\n"
    printf "  ranksep=1.0;\n"
    printf "  nodesep=1.0;\n"

    printf "\n  // nodes\n"
    if [ "$GROUP_BY" == "abstraction" ]; then
        # implementation
        printf "  subgraph cluster_0 {\n"
        printf "    label=\"implementation\";\n"
        printf "    style=filled;"
        printf "    fillcolor=gray96;\n"
        printf "    pencolor=gray60;\n"
        for MATCH in $ALL_MATCHES; do
            [ "${MATCH##*.}" == "cpp" ] && printf "    \"$MATCH\" [shape=box, style=filled, fillcolor=gray94] ;\n"
        done
        printf "  }\n"

        # abstraction nodes
        printf "  subgraph cluster_1 {\n"
        printf "    label=\"abstraction\";\n"
        printf "    style=filled;"
        printf "    fillcolor=gray96;\n"
        printf "    pencolor=gray60;\n"
        for MATCH in $ALL_MATCHES; do
            [ "${MATCH##*.}" == "hpp" ] && printf "    \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray94] ;\n"
        done
        printf "  }\n"

        # undefined nodes
        printf "  subgraph cluster_2 {\n"
        printf "    label=\"other\";\n"
        printf "    style=filled;"
        printf "    fillcolor=gray96;\n"
        printf "    pencolor=gray60;\n"
        for MATCH in $ALL_MATCHES; do
            [ "${MATCH##*.}" != "hpp" ] && [ "${MATCH##*.}" != "cpp" ] && printf "    \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray98, color=gray55, fontcolor=gray55] ;\n"

        done
        printf "  }\n"
    elif [ "$GROUP_BY" == "module" ]; then
        local MODULES=($(echo ${MATCHES[@]} ${!MATCHES[@]} | tr ' ' '\n' | xargs dirname | grep -v '^\.$' | sort | uniq))
        for MATCH in $ALL_MATCHES; do
            [ "$(dirname "$MATCH")" != "." ] && continue
            if [ "${MATCH##*.}" == "cpp" ]; then
                printf "  \"$MATCH\" [shape=box, style=filled, fillcolor=gray94] ;\n"
            elif [ "${MATCH##*.}" == "hpp" ]; then
                printf "  \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray94] ;\n"
            else
                printf "  \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray98, color=gray55, fontcolor=gray55] ;\n"
            fi
        done
        local OPEN_BRACES=0
        local CLUSTER_INDEX=0
        for CLUSTER_INDEX in $(seq 0 $((${#MODULES[@]}-1))); do
            local MODULE="${MODULES[$CLUSTER_INDEX]}"
            local OPEN_BRACES=$((OPEN_BRACES+1))
            local INDENTATION="  "; 
            printf '%*s' $((OPEN_BRACES*2)); printf "subgraph cluster_$CLUSTER_INDEX {\n"
            printf '%*s' $((OPEN_BRACES*2)); printf "label=\"$MODULE\";\n"
            printf '%*s' $((OPEN_BRACES*2)); printf 'style=filled;'
            printf '%*s' $((OPEN_BRACES*2)); printf "fillcolor=gray$((100-OPEN_BRACES*4));\n"
            printf '%*s' $((OPEN_BRACES*2)); printf "pencolor=gray$((64-OPEN_BRACES*4));\n"
            for MATCH in $ALL_MATCHES; do
                [ "$(dirname "$MATCH")" != "$MODULE" ] && continue
                printf '%*s' $((OPEN_BRACES*2))
                if [ "${MATCH##*.}" == "cpp" ]; then
                    printf "\"$MATCH\" [shape=box, style=filled, fillcolor=gray94] ;\n"
                elif [ "${MATCH##*.}" == "hpp" ]; then
                    printf "\"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray94] ;\n"
                else
                    printf "\"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray98, color=gray55, fontcolor=gray55] ;\n"
                fi
            done
            local NEXT_MODULE="${MODULES[$((CLUSTER_INDEX+1))]}"
            if [ "${NEXT_MODULE:0:${#MODULE}}" != "$MODULE" ]; then
                printf '%*s' $((OPEN_BRACES*2)); printf "}\n"
                local OPEN_BRACES=$((OPEN_BRACES-1))
            fi
        done
        while [ $OPEN_BRACES -gt 0 ]; do
            printf '%*s' $((OPEN_BRACES*2)); printf "}\n"
            local OPEN_BRACES=$((OPEN_BRACES-1))
        done
    else
        for MATCH in $ALL_MATCHES; do
            if [ "${MATCH##*.}" == "cpp" ]; then
                printf "  \"$MATCH\" [shape=box, style=filled, fillcolor=gray94] ;\n"
            elif [ "${MATCH##*.}" == "hpp" ]; then
                printf "  \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray94] ;\n"
            else
                printf "  \"$MATCH\" [shape=ellipse, style=filled, fillcolor=gray98, color=gray55, fontcolor=gray55] ;\n"
            fi
        done
    fi

    # edges
    printf "\n  // edges\n"
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

