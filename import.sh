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

      handlers)
        # test if $# anything but zero
        if [ -z "$IMPORT_HANDLERS" ]
        then
          echo "import"
        else
          local importHandlers
          IFS=: read -ra importHandlers <<<"$IMPORT_HANDLERS"
          local importHandler
          for importHandler in "${importHandlers[@]}"
          do
            echo "$importHandler"
          done
        fi
        ;;

      addHandler)
        [ $# -lt 1 ] && { echo "Missing required argument for 'import -- addHandler': handler function/command name" >&2; return 1; }
        local handlerFunctionName="$1"
        if [ -z "$IMPORT_HANDLERS" ]
        then
          IMPORT_HANDLERS="import:$handlerFunctionName"
        else
          IMPORT_HANDLERS="$IMPORT_HANDLERS:$handlerFunctionName"
        fi
        ;;

      # prependHandler)

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

    ##
    # Load IMPORT_HANDLERS
    ##
    [ -z "$IMPORT_HANDLERS" ] && local IMPORT_HANDLERS="import"
    local importHandlers
    IFS=: read -ra importHandlers <<<"$IMPORT_HANDLERS"

    ##
    # If this flag is ever flipped to true, this 'import' will return 1.
    # Otherwise it will return 0 unless importError has a value.
    ##
    local anyImportsFailed=""

    ##
    # Import error to show before returning.
    # If a handler returns 3 then we stop and show this immediately.
    ##
    local importError=""

    ##
    # For each path to import, e.g. import foo bar
    ##
    local importToFind
    for importToFind in "$@"
    do
      local found=""

      ##
      # For each import handler, e.g. 'import' or custom
      #
      # The first handler to return 0 will break this loop.
      #
      # The 'import' code here also declares that it handled
      # the given import by 'break'ing this loop.
      #
      # Because you can import multiple files at one time
      # *and* we want to allow for silent 'failures' like
      # when lots of files 'import @error' which is OK...
      #
      # If the handler wants to...
      #
      #   return 0 - the handler handled this import OK, break
      #
      #   return 1 - the handler didn't handle this import, continue
      #
      #   return 2 - the handler handled this import FAIL, break
      #              the imports will continue running, but the outer
      #              import command will return a 1 instead of a 0
      #              if there are any instances of this
      #
      #              ^---- this flags anyImportsFailed=true
      #
      #   return 3 - there was an error, stop and return. the function
      #              is responsible for printing its own STDERR/STDOUT.
      ##
      local importHandler
      for importHandler in "${importHandlers[@]}"
      do
        ##
        # Detect type of handler (custom function or 'import' main code)
        ##
        if [ "$importHandler" = "import" ]
        then
          ##
          # 'import'
          ##

          ##
          # Load IMPORT_PATH
          ##
          local rawImportPaths
          IFS=: read -ra rawImportPaths <<<"$IMPORT_PATH"
          declare -a importPaths=()
          local rawImportPath
          for rawImportPath in "${rawImportPaths[@]}"
          do
            local standardizedImportPath="${rawImportPath#./}"
            standardizedImportPath="${standardizedImportPath/%\/}"
            importPaths+=("$standardizedImportPath")
          done

          ##
          # Load IMPORTED_PATHS
          ##
          local importedPaths
          IFS=: read -ra importedPaths <<<"$IMPORTED_PATHS"

          ##
          # Either the import ends with /** or /* or doesn't (3 main cases to handle)
          ##

          # /**
          if [[ "$importToFind" =~ \/\*\*$ ]]
          then

            # strip /**
            importToFind="${importToFind/%\/\*\*}"

            ##
            # Find the first directory that matched from IMPORT_PATHS
            ##
            local importToFindAsDirectory=""
            local importPath
            for importPath in "${importPaths[@]}"
            do
              if [ -d "${importPath}/${importToFind}" ]
              then
                importToFindAsDirectory="${importPath}/${importToFind}"
                break
              fi
            done

            if [ -z "$importToFindAsDirectory" ]
            then
              # Hmm. No matching directly. Let's let another import handler deal with this!
              continue # Go to the next handler!
            fi

            ##
            # Find all of the source files in /**
            ##
            declare -a splatSourceFilesToImport=()
            local shSourceFileFound
            while IFS= read -rd '' shSourceFileFound; do splatSourceFilesToImport+=("$shSourceFileFound")
            done < <(find "$importToFindAsDirectory" -type f -iname "*.sh" -print0)

            local loadedOneOfTheSplatSourceFiles=""

            ##
            # For each of the /** splat found .sh files, source them unless they've been sourced
            # in which case mark anyImportsFailed=true because re-sourcing the same import counts as a 'fail'
            # so you can detect whether or not you've imported a single import before (less useful for N imports).
            # Every sourced file should be added to IMPORTED_PATHS
            ##
            local splatSourceFileToImport
            for splatSourceFileToImport in "${splatSourceFilesToImport[@]}"
            do
              local itWasAlreadyImported=""

              ##
              # Check IMPORTED_PATHS else source this one and 
              ##
              local alreadyImported
              for alreadyImported in "${importedPaths[@]}"
              do
                if [ "$splatSourceFileToImport" = "$alreadyImported" ]
                then
                  itWasAlreadyImported=true
                  break
                fi
              done

              if [ -n "$itWasAlreadyImported" ]
              then
                # One of the imports was already import, mark everything to fail
                anyImportsFailed=true
                # And do nothing :)
              else
                # Hey! We're good to go! Let's source this and add it to the list of imported imports!
                found=true
                loadedOneOfTheSplatSourceFiles=true
                IMPORTED_PATHS="$IMPORTED_PATHS:$splatSourceFileToImport"
                source "$splatSourceFileToImport"
              fi
            done

            [ -n "$loadedOneOfTheSplatSourceFiles" ] && break # success! this import has been loaded and handled by 'import'

          # /*
          elif [[ "$importToFind" =~ \/\*$ ]]
          then

            # strip /*
            importToFind="${importToFind/%\/\*}"

            ##
            # Find the first directory that matched from IMPORT_PATHS
            ##
            local importToFindAsDirectory=""
            local importPath
            for importPath in "${importPaths[@]}"
            do
              if [ -d "${importPath}/${importToFind}" ]
              then
                importToFindAsDirectory="${importPath}/${importToFind}"
                break
              fi
            done

            if [ -z "$importToFindAsDirectory" ]
            then
              # Hmm. No matching directly. Let's let another import handler deal with this!
              continue # Go to the next handler!
            fi

            ##
            # Find all of the source files in /**
            ##
            declare -a splatSourceFilesToImport=()
            local shSourceFileFound
            while IFS= read -rd '' shSourceFileFound; do splatSourceFilesToImport+=("$shSourceFileFound")
            done < <(find "$importToFindAsDirectory" -maxdepth 1 -type f -iname "*.sh" -print0)

            local loadedOneOfTheSplatSourceFiles=""

            ##
            # For each of the /** splat found .sh files, source them unless they've been sourced
            # in which case mark anyImportsFailed=true because re-sourcing the same import counts as a 'fail'
            # so you can detect whether or not you've imported a single import before (less useful for N imports).
            # Every sourced file should be added to IMPORTED_PATHS
            ##
            local splatSourceFileToImport
            for splatSourceFileToImport in "${splatSourceFilesToImport[@]}"
            do
              local itWasAlreadyImported=""

              ##
              # Check IMPORTED_PATHS else source this one and 
              ##
              local alreadyImported
              for alreadyImported in "${importedPaths[@]}"
              do
                if [ "$splatSourceFileToImport" = "$alreadyImported" ]
                then
                  itWasAlreadyImported=true
                  break
                fi
              done

              if [ -n "$itWasAlreadyImported" ]
              then
                # One of the imports was already import, mark everything to fail
                anyImportsFailed=true
                # And do nothing :)
              else
                # Hey! We're good to go! Let's source this and add it to the list of imported imports!
                found=true
                loadedOneOfTheSplatSourceFiles=true
                IMPORTED_PATHS="$IMPORTED_PATHS:$splatSourceFileToImport"
                source "$splatSourceFileToImport"
              fi
            done

            [ -n "$loadedOneOfTheSplatSourceFiles" ] && break # success! this import has been loaded and handled by 'import'

          # Regular, non-splat case
          else

            local foundMatchToSource=""

            ##
            # Regular check against each of the import paths :)
            ##
            local importPath
            for importPath in "${importPaths[@]}"
            do
              if [ -f "${importPath}/${importToFind}" ]
              then
                foundMatchToSource="${importPath}/${importToFind}"
                break
              elif [ -f "${importPath}/${importToFind}.sh" ]
              then
                foundMatchToSource="${importPath}/${importToFind}.sh"
                break
              fi
            done

            if [ -n "$foundMatchToSource" ]
            then

              local itWasAlreadyImported=""

              ##
              # Got it! Now, let's just double check that we haven't already sourced this before...
              ##
              local alreadyImported
              for alreadyImported in "${importedPaths[@]}"
              do
                if [ "$foundMatchToSource" = "$alreadyImported" ]
                then
                  itWasAlreadyImported=true
                  break
                fi
              done

              if [ -n "$itWasAlreadyImported" ]
              then
                # One of the imports was already import, mark everything to fail
                anyImportsFailed=true
                # And do nothing :)
              else
                # Good to go! Load it! And mark it as having been loaded.
                found=true
                IMPORTED_PATHS="$IMPORTED_PATHS:$foundMatchToSource"
                source "$foundMatchToSource"
                break
              fi

            else
              # Hmm. No dice. I guess let's let another handler try this one!
              continue
            fi

          fi

          ##
          # end 'import'
          ##
        else
          if "$importHandler" "$importToFind"
          then
            local handlerReturnCode=$?
            case $handlerReturnCode in
              0)
                found=true
                break # handled ok!
                ;;
              1)
                : # keep trying, didn't handle / don't want to stop!
                ;;
              2)
                found=true
                break # handled but silent fail!
                anyImportsFailed=true
                ;;
              3)
                return 3 # oh noes, they want us to stop right away!
                ;;
              *)
                echo "Unexpected import handler return code: $handlerReturnCode" >&2
                ;;
            esac
          fi
        fi
      done

      # At the end of everything, 
      if [ -z "$found" ]
      then
        echo "import not found: $importToFind"
        return 1
      fi
    done

    if [ -n "$anyImportsFailed" ]
    then    
      return 1
    fi
  fi
}