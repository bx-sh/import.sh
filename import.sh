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
        # TEST ME
        # [ $# -ne 0 ] && { echo "Too many arguments provided for 'import -- list', expected 0, received $#" >&2; return 1; }

        local importPaths
        IFS=: read -ra importPaths <<<"$IMPORT_PATH"

        declare -a standardizedImportPaths

        local importPath
        for importPath in "${importPaths[@]}"
        do
          local alreadyImported=""
          local standardizedImportPath="${importPath#./}"
          standardizedImportPath="${standardizedImportPath/%\/}"
          
          [ -z "$standardizedImportPath" ] && continue

          local alreadyImportedPath
          for alreadyImportedPath in "${standardizedImportPaths[@]}"
          do
            if [ "$alreadyImportedPath" = "$standardizedImportPath" ]
            then
              alreadyImported=true
              break
            fi
          done

          if [ -z "$alreadyImported" ]
          then
            standardizedImportPaths+=("$standardizedImportPath")
            echo "$importPath"
          fi
        done
        ;;

      search)
        [ $# -lt 1 ] && { echo "Missing required argument for 'import -- search': import name" >&2; return 1; }
        [ $# -gt 1 ] && { echo "Too many arguments provided for 'import -- search', expected 1: import name, received $#" >&2; return 1; }

        local found
        local importToFind="$1"
        shift

        if [[ "$importToFind" = *"*"* ]]
        then
          if [[ ! "$importToFind" =~ \/\*$ ]] && [[ ! "$importToFind" =~ \/\*\*$ ]]
          then
            echo "* and ** operators are only supported at the end of import names, e.g. import lib/* or import lib/**" >&2
            return 1
          fi
        fi

        local importPaths
        IFS=: read -ra importPaths <<<"$IMPORT_PATH"

        local importPath
        for importPath in "${importPaths[@]}"
        do
          local standardizedImportPath="${importPath#./}"
          standardizedImportPath="${standardizedImportPath/%\/}"

          if [[ "$standardizedImportPath" = *"**"* ]]
          then
            echo "Currently do not support import paths with splats" >&2
          elif [[ "$standardizedImportPath" = *"*"* ]]
          then
            echo "Currently do not support import paths with splats" >&2
          fi

          if [[ "$importToFind" =~ \/\*$ ]]
          then
            local importDirectory="${importToFind/%\/\*}"
            importDirectory="${standardizedImportPath}/${importDirectory}"
            if [ -d "$importDirectory" ]
            then
              declare -a shFilesInImportDirectory=()
              local shFile
              while IFS= read -rd '' shFile; do shFilesInImportDirectory+=("$shFile")
              done < <(find "$importDirectory" -type f -iname "*.sh" -maxdepth 1 -print0)
              [ "${#shFilesInImportDirectory[@]}" -gt 0 ] && found=true
              local shFileFound
              for shFileFound in "${shFilesInImportDirectory[@]}"
              do
                echo "$shFileFound"
              done
            fi
          elif [[ "$importToFind" =~ \/\*\*$ ]]
          then
            local importDirectory="${importToFind/%\/\*\*}"
            importDirectory="${standardizedImportPath}/${importDirectory}"
            if [ -d "$importDirectory" ]
            then
              declare -a shFilesInImportDirectory=()
              local shFile
              while IFS= read -rd '' shFile; do shFilesInImportDirectory+=("$shFile")
              done < <(find "$importDirectory" -type f -iname "*.sh" -print0)
              [ "${#shFilesInImportDirectory[@]}" -gt 0 ] && found=true
              local shFileFound
              for shFileFound in "${shFilesInImportDirectory[@]}"
              do
                echo "$shFileFound"
              done
            fi
          fi

          # Import FIRST FOUND and return, don't detect ambiguous imports for the user.
          # That's kinda the whole point of ordering your IMPORT_PATH in a specific way.
          local expectedImportPath="${standardizedImportPath}/${importToFind}"
          if [ -f "$expectedImportPath" ]
          then
            echo "$expectedImportPath"
            found=true
          elif [ -f "$expectedImportPath.sh" ]
          then
            echo "$expectedImportPath.sh"
            found=true
          fi
        done

        [ -n "$found" ]
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