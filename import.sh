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

    case "$command" in

      list)
        local importPaths
        IFS=: read -ra importPaths <<<"$IMPORT_PATH"

        declare -a cleanImportPaths

        local importPath
        for importPath in "${importPaths[@]}"
        do
          local alreadyImported=""
          local cleanImportPath="${importPath#./}"
          cleanImportPath="${cleanImportPath/%\/}"
          
          [ -z "$cleanImportPath" ] && continue

          local alreadyImportedPath
          for alreadyImportedPath in "${cleanImportPaths[@]}"
          do
            if [ "$alreadyImportedPath" = "$cleanImportPath" ]
            then
              alreadyImported=true
              break
            fi
          done

          if [ -z "$alreadyImported" ]
          then
            cleanImportPaths+=("$cleanImportPath")
            echo "$importPath"
          fi
        done
        ;;

      push)
        local importPath
        for importPath in "$@"
        do
          if [ -z "$IMPORT_PATH" ]
          then
            IMPORT_PATH="$importPath"
          else
            IMPORT_PATH="$IMPORT_PATH:$importPath"
          fi
        done
        ;;

      unshift)
        local importPath
        for importPath in "$@"
        do
          if [ -z "$IMPORT_PATH" ]
          then
            IMPORT_PATH="$importPath"
          else
            IMPORT_PATH="$importPath:$IMPORT_PATH"
          fi
        done
        ;;

      *)
        echo "Unknown command for 'import': $command" >&2
        return 1
        ;;

    esac
  fi
}