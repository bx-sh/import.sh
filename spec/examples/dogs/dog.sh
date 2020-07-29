DOG="Rover"

DOG_IMPORTED_PATH="Dog was given this path: $IMPORTED_PATH"

set -o posix
DOG_AVAILABLE_VARIABLES="$( set | sort | grep -v ^___ )"
set +o posix

# it's ok if it wants to get the handler, tho! just expose importHandler as IMPORT_HANDLER TODO