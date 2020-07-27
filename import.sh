import() {
  if [ $# -eq 0 ]
  then
    echo "Missing required argument for 'import'" >&2
    return 1
  fi

  if [ "$1" = "--" ]
  then
    shift

    if [ $# -eq 0 ]
    then
      echo "Missing required command for 'import -- [command]'" >&2
    fi

    local command="$1"
    shift

    # case "$command" in)

    # esac
  fi
}