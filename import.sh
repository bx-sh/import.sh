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

      *)
        echo "Unknown command for 'import': $command" >&2
        return 1
        ;;

    esac
  fi
}