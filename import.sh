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
          if [[ "$importPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi

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

        if [[ "$importToFind" =~ \* ]]
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
          if [[ "$importPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi

          local standardizedImportPath="${importPath#./}"
          standardizedImportPath="${standardizedImportPath/%\/}"

          if [[ "$importToFind" =~ \/\*$ ]]
          then
            local importDirectory="${importToFind/%\/\*}"
            importDirectory="${standardizedImportPath}/${importDirectory}"
            if [ -d "$importDirectory" ]
            then
              declare -a shFilesInImportDirectory=()
              local shFile
              while IFS= read -rd '' shFile; do shFilesInImportDirectory+=("$shFile")
              done < <(find "$importDirectory" -maxdepth 1 -type f -iname "*.sh" -print0)
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
          if [[ "$importPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi
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
          if [[ "$importPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi
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

  else
    ##
    # import
    ##
    [ $# -lt 1 ] && { echo "Missing required argument for 'import': import name(s)" >&2; return 1; }

    local anyWereAlreadyImported

    local importToFind
    for importToFind in "$@"
    do
      if [[ "$importToFind" =~ \* ]]
      then
        if [[ ! "$importToFind" =~ \/\*$ ]] && [[ ! "$importToFind" =~ \/\*\*$ ]]
        then
          echo "* and ** operators are only supported at the end of import names, e.g. import lib/* or import lib/**" >&2
          return 1
        fi
      fi

      local importPaths
      IFS=: read -ra importPaths <<<"$IMPORT_PATH"

      local found=""
      local importPath
      for importPath in "${importPaths[@]}"
      do
        [ -n "$found" ] && break

        if [[ "$importPath" =~ \* ]]
        then
          echo "IMPORT_PATH does not support * splat operators in paths" >&2
          return 1
        fi

        local standardizedImportPath="${importPath#./}"
        standardizedImportPath="${standardizedImportPath/%\/}"

        local importedPaths
        IFS=: read -ra importedPaths <<<"$IMPORTED_PATHS"

        if [[ "$importToFind" =~ \/\*$ ]]
        then
          local importDirectory="${importToFind/%\/\*}"
          importDirectory="${standardizedImportPath}/${importDirectory}"
          if [ -d "$importDirectory" ]
          then
            declare -a shFilesInImportDirectory=()
            local shFile
            while IFS= read -rd '' shFile; do shFilesInImportDirectory+=("$shFile")
            done < <(find "$importDirectory" -maxdepth 1 -type f -iname "*.sh" -print0)
            local shFileFound
            for shFileFound in "${shFilesInImportDirectory[@]}"
            do
              local shFileImportPath="${shFileFound/%.sh}"
              local wasAlreadyImported=""
              local importedPath
              for importedPath in "${importedPaths[@]}"
              do
                if [ "$importedPath" = "$shFileImportPath" ]
                then
                  found=true
                  wasAlreadyImported=true
                  anyWereAlreadyImported=true
                  break # already imported this
                fi
              done
              if [ -z "$wasAlreadyImported" ]
              then
                if [ -z "$IMPORTED_PATHS" ]
                then
                  IMPORTED_PATHS="$shFileImportPath"
                else
                  IMPORTED_PATHS="$IMPORTED_PATHS:$shFileImportPath"
                fi
                source "$shFileFound"
              fi
            done
            if [ "${#shFilesInImportDirectory[@]}" -gt 0 ]
            then
              found=true
              break
            fi
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
            local shFileFound
            for shFileFound in "${shFilesInImportDirectory[@]}"
            do
              local shFileImportPath="${shFileFound/%.sh}"
              local wasAlreadyImported=""
              local importedPath
              for importedPath in "${importedPaths[@]}"
              do
                if [ "$importedPath" = "$shFileImportPath" ]
                then
                  found=true
                  wasAlreadyImported=true
                  anyWereAlreadyImported=true
                  break # already imported this
                fi
              done
              if [ -z "$wasAlreadyImported" ]
              then
                if [ -z "$IMPORTED_PATHS" ]
                then
                  IMPORTED_PATHS="$shFileImportPath"
                else
                  IMPORTED_PATHS="$IMPORTED_PATHS:$shFileImportPath"
                fi
                source "$shFileFound"
              fi
            done
            if [ "${#shFilesInImportDirectory[@]}" -gt 0 ]
            then
              found=true
              break
            fi
          fi
        else
          # Import FIRST FOUND and return, don't detect ambiguous imports for the user.
          # That's kinda the whole point of ordering your IMPORT_PATH in a specific way.
          local expectedImportPath="${standardizedImportPath}/${importToFind}"

          local outerBreak
          local importedPath
          for importedPath in "${importedPaths[@]}"
          do
            if [ "$importedPath" = "$expectedImportPath" ] || [ "$importedPath" = "$expectedImportPath.sh" ]
            then
              found=true
              anyWereAlreadyImported=true
              outerBreak=true
              break # already imported this
            fi
          done
          [ -n "$outerBreak" ] && break

          if [ -f "$expectedImportPath" ]
          then
            if [ -z "$IMPORTED_PATHS" ]
            then
              IMPORTED_PATHS="${expectedImportPath/%.sh}"
            else
              IMPORTED_PATHS="$IMPORTED_PATHS:${expectedImportPath/%.sh}"
            fi
            source "$expectedImportPath"
            found=true
            break
          elif [ -f "$expectedImportPath.sh" ]
          then
            if [ -z "$IMPORTED_PATHS" ]
            then
              IMPORTED_PATHS="${expectedImportPath/%.sh}"
            else
              IMPORTED_PATHS="$IMPORTED_PATHS:${expectedImportPath/%.sh}"
            fi
            source "$expectedImportPath.sh"
            found=true
            break
          fi
        fi
      done

      if [ -z "$found" ]
      then
        echo "import not found: $importToFind"
        return 1
      fi
    done

    [ -z "$anyWereAlreadyImported" ]
  fi
}