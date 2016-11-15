#!/bin/bash

main () {
	local DOTFILES_PATH="$(readlink -f "$(dirname "$(readlink -f "$0")")/../")"
	for FILE in $(ls --color=never -a $DOTFILES_PATH); do
		if [ "$FILE" == "." ] || [ "$FILE" == ".." ]; then
			continue
		fi
		if [ "$FILE" == ".dotfiles" ]; then
			continue
		fi

		FILE_PATH="$DOTFILES_PATH/$FILE"
		LINK_TARGET="$(readlink ~/$(basename "$FILE"))"
		READLINK_RESULT=$?
		if [ $READLINK_RESULT -eq 0 ]; then
			if [ "$LINK_TARGET" != "$FILE_PATH" ]; then
				echo "[INVALID] $FILE" 1>&2
			fi
		else
			echo "[NO LINK] $FILE" 1>&2
		fi
	done
	return 0
}

main "$@"
exit $?

