import() {
  IMPORT_VERSION="0.0.1"
  ___IMPORT_HELP="import $IMPORT_VERSION

import [path][/*[*]]

import -- help
import -- version

import -- list                # list directories in IMPORT_PATH
import -- push    [dir] [dir] # push onto back of IMPORT_PATH
import -- unshift [dir] [dir] # add to front of IMPORT_PATH
import -- search  [path]      # print all locations path is ___import___Found

import -- handlers       # list all handler functions in order
import -- prependHandler # add handler as first handler
import -- appendHandler  # add handler as last handler
import -- removeHandler  # remove a handler
"

  [ $# -eq 0 ] && echo "$___IMPORT_HELP"

  if [ "$1" = "--" ]
  then
    shift

    if [ $# -eq 0 ]
    then
      echo "Missing required command for 'import -- [command]'" >&2
      return 1
    fi

    local ___import___command="$1"
    shift

    case "$___import___command" in

      version)
        echo "import $IMPORT_VERSION"
        ;;

      help)
        echo "$___IMPORT_HELP"
        ;;

      list)
        # TEST ME
        # [ $# -ne 0 ] && { echo "Too many arguments provided for 'import -- list', expected 0, received $#" >&2; return 1; }

        local ___import___ImportPaths
        IFS=: read -ra ___import___ImportPaths <<<"$IMPORT_PATH"

        declare -a ___import___StandardizedImportPaths

        local ___import___ImportPath
        for ___import___ImportPath in "${___import___ImportPaths[@]}"
        do
          if [[ "$___import___ImportPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi

          local ___import___AlreadyImported=""
          local ___import___StandardizedImportPath="${___import___ImportPath#./}"
          ___import___StandardizedImportPath="${___import___StandardizedImportPath/%\/}"
          
          [ -z "$___import___StandardizedImportPath" ] && continue

          local ___import___AlreadyImportedPath
          for ___import___AlreadyImportedPath in "${___import___StandardizedImportPaths[@]}"
          do
            if [ "$___import___AlreadyImportedPath" = "$___import___StandardizedImportPath" ]
            then
              ___import___AlreadyImported=true
              break
            fi
          done

          if [ -z "$___import___AlreadyImported" ]
          then
            ___import___StandardizedImportPaths+=("$___import___StandardizedImportPath")
            echo "$___import___ImportPath"
          fi
        done
        ;;

      handlers)
        # test if $# anything but zero
        if [ -z "$IMPORT_HANDLERS" ]
        then
          echo "import"
        else
          local ___import___handlers
          IFS=: read -ra ___import___handlers <<<"$IMPORT_HANDLERS"
          local IMPORT_HANDLER
          for IMPORT_HANDLER in "${___import___handlers[@]}"
          do
            echo "$IMPORT_HANDLER"
          done
        fi
        ;;

      appendHandler)
        [ $# -lt 1 ] && { echo "Missing required argument for 'import -- appendHandler': handler function/___import___command name" >&2; return 1; }
        local handlerFunctionName="$1"
        if [ -z "$IMPORT_HANDLERS" ]
        then
          IMPORT_HANDLERS="import:$handlerFunctionName"
        else
          IMPORT_HANDLERS="$IMPORT_HANDLERS:$handlerFunctionName"
        fi
        ;;

      prependHandler)
        [ $# -lt 1 ] && { echo "Missing required argument for 'import -- prependHandler': handler function/___import___command name" >&2; return 1; }
        local handlerFunctionName="$1"
        if [ -z "$IMPORT_HANDLERS" ]
        then
          IMPORT_HANDLERS="$handlerFunctionName:import"
        else
          IMPORT_HANDLERS="$handlerFunctionName:$IMPORT_HANDLERS"
        fi
        ;;

      removeHandler)
        [ $# -lt 1 ] && { echo "Missing required argument for 'import -- removeHandler': handler function/___import___command name" >&2; return 1; }
        local handlerFunctionName="$1"
        if [ -n "$IMPORT_HANDLERS" ]
        then
          if [ "$IMPORT_HANDLERS" = "$handlerFunctionName" ]
          then
            unset IMPORT_HANDLERS
          elif [[ "$IMPORT_HANDLERS" = *":$handlerFunctionName:"* ]]
          then
            IMPORT_HANDLERS="${IMPORT_HANDLERS/:"$handlerFunctionName":}"
          elif [[ "$IMPORT_HANDLERS" =~ ^$handlerFunctionName: ]]
          then
            IMPORT_HANDLERS="${IMPORT_HANDLERS#"$handlerFunctionName":}"
          elif [[ "$IMPORT_HANDLERS" =~ :$handlerFunctionName$ ]]
          then
            IMPORT_HANDLERS="${IMPORT_HANDLERS/%:"$handlerFunctionName"}"
          else
            echo "Handler not present: $handlerFunctionName" >&2
            return 1
          fi
        fi

        ;;

      search)
        [ $# -lt 1 ] && { echo "Missing required argument for 'import -- search': import name" >&2; return 1; }
        [ $# -gt 1 ] && { echo "Too many arguments provided for 'import -- search', expected 1: import name, received $#" >&2; return 1; }

        local ___import___Found
        local ___import___ImportToFind="$1"
        shift

        if [[ "$___import___ImportToFind" =~ \* ]]
        then
          if [[ ! "$___import___ImportToFind" =~ \/\*$ ]] && [[ ! "$___import___ImportToFind" =~ \/\*\*$ ]]
          then
            echo "* and ** operators are only supported at the end of import names, e.g. import lib/* or import lib/**" >&2
            return 1
          fi
        fi

        local ___import___ImportPaths
        IFS=: read -ra ___import___ImportPaths <<<"$IMPORT_PATH"

        local ___import___ImportPath
        for ___import___ImportPath in "${___import___ImportPaths[@]}"
        do
          if [[ "$___import___ImportPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi

          local ___import___StandardizedImportPath="${___import___ImportPath#./}"
          ___import___StandardizedImportPath="${___import___StandardizedImportPath/%\/}"

          if [[ "$___import___ImportToFind" =~ \/\*$ ]]
          then
            local importDirectory="${___import___ImportToFind/%\/\*}"
            importDirectory="${___import___StandardizedImportPath}/${importDirectory}"
            if [ -d "$importDirectory" ]
            then
              declare -a shFilesInImportDirectory=()
              local shFile
              while IFS= read -rd '' shFile; do shFilesInImportDirectory+=("$shFile")
              done < <(find "$importDirectory" -maxdepth 1 -type f -iname "*.sh" -print0)
              [ "${#shFilesInImportDirectory[@]}" -gt 0 ] && ___import___Found=true
              local shFileFound
              for shFileFound in "${shFilesInImportDirectory[@]}"
              do
                echo "$shFileFound"
              done
            fi
          elif [[ "$___import___ImportToFind" =~ \/\*\*$ ]]
          then
            local importDirectory="${___import___ImportToFind/%\/\*\*}"
            importDirectory="${___import___StandardizedImportPath}/${importDirectory}"
            if [ -d "$importDirectory" ]
            then
              declare -a shFilesInImportDirectory=()
              local shFile
              while IFS= read -rd '' shFile; do shFilesInImportDirectory+=("$shFile")
              done < <(find "$importDirectory" -type f -iname "*.sh" -print0)
              [ "${#shFilesInImportDirectory[@]}" -gt 0 ] && ___import___Found=true
              local shFileFound
              for shFileFound in "${shFilesInImportDirectory[@]}"
              do
                echo "$shFileFound"
              done
            fi
          fi

          # Import FIRST FOUND and return, don't detect ambiguous imports for the user.
          # That's kinda the whole point of ordering your IMPORT_PATH in a specific way.
          local expectedImportPath="${___import___StandardizedImportPath}/${___import___ImportToFind}"
          if [ -f "$expectedImportPath" ]
          then
            echo "$expectedImportPath"
            ___import___Found=true
          elif [ -f "$expectedImportPath.sh" ]
          then
            echo "$expectedImportPath.sh"
            ___import___Found=true
          fi
        done

        [ -n "$___import___Found" ]
        ;;

      push)
        local ___import___ImportPath
        for ___import___ImportPath in "$@"
        do
          if [[ "$___import___ImportPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi
          if [ -z "$IMPORT_PATH" ]
          then
            IMPORT_PATH="$___import___ImportPath"
          else
            IMPORT_PATH="$IMPORT_PATH:$___import___ImportPath"
          fi
        done
        ;;

      unshift)
        local ___import___ImportPath
        for ___import___ImportPath in "$@"
        do
          if [[ "$___import___ImportPath" =~ \* ]]
          then
            echo "IMPORT_PATH does not support * splat operators in paths" >&2
            return 1
          fi
          if [ -z "$IMPORT_PATH" ]
          then
            IMPORT_PATH="$___import___ImportPath"
          else
            IMPORT_PATH="$___import___ImportPath:$IMPORT_PATH"
          fi
        done
        ;;

      *)
        echo "Unknown command for 'import': $___import___command" >&2
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
    local ___import___handlers
    IFS=: read -ra ___import___handlers <<<"$IMPORT_HANDLERS"

    ##
    # If this flag is ever flipped to true, this 'import' will return 1.
    # Otherwise it will return 0.
    ##
    local ___import___AnyImportsFailed=""

    ##
    # For each path to import, e.g. import foo bar
    ##
    local ___import___ImportToFind
    for ___import___ImportToFind in "$@"
    do
      local ___import___Found=""

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
      #              import ___import___command will return a 1 instead of a 0
      #              if there are any instances of this
      #
      #              ^---- this flags ___import___AnyImportsFailed=true
      #
      #   return 3 - there was an error, stop and return. the function
      #              is responsible for printing its own STDERR/STDOUT.
      ##
      local IMPORT_HANDLER
      for IMPORT_HANDLER in "${___import___handlers[@]}"
      do
        ##
        # Detect type of handler (custom function or 'import' main code)
        ##
        if [ "$IMPORT_HANDLER" = "import" ]
        then
          ##
          # 'import'
          ##

          ##
          # Load IMPORT_PATH
          ##
          local ___import___RawImportPaths
          IFS=: read -ra ___import___RawImportPaths <<<"$IMPORT_PATH"
          declare -a ___import___ImportPaths=()
          local ___import___RawImportPath
          for ___import___RawImportPath in "${___import___RawImportPaths[@]}"
          do
            local ___import___StandardizedImportPath="${___import___RawImportPath#./}"
            ___import___StandardizedImportPath="${___import___StandardizedImportPath/%\/}"
            ___import___ImportPaths+=("$___import___StandardizedImportPath")
          done

          ##
          # Load IMPORTED_PATHS
          ##
          local ___import___ImportedPaths
          IFS=: read -ra ___import___ImportedPaths <<<"$IMPORTED_PATHS"

          ##
          # Either the import ends with /** or /* or doesn't (3 main cases to handle)
          ##

          # /**
          if [[ "$___import___ImportToFind" =~ \/\*\*$ ]]
          then

            # strip /**
            ___import___ImportToFind="${___import___ImportToFind/%\/\*\*}"

            ##
            # Find the first directory that matched from IMPORT_PATHS
            ##
            local ___import___ImportToFindAsDirectory=""
            local ___import___ImportPath
            for ___import___ImportPath in "${___import___ImportPaths[@]}"
            do
              if [ -d "${___import___ImportPath}/${___import___ImportToFind}" ]
              then
                ___import___ImportToFindAsDirectory="${___import___ImportPath}/${___import___ImportToFind}"
                break
              fi
            done

            if [ -z "$___import___ImportToFindAsDirectory" ]
            then
              # Hmm. No matching directly. Let's let another import handler deal with this!
              continue # Go to the next handler!
            fi

            ##
            # Find all of the source files in /**
            ##
            declare -a ___import___SplatFilesToImport=()
            local ___import___ShFileFound
            while IFS= read -rd '' ___import___ShFileFound; do ___import___SplatFilesToImport+=("$___import___ShFileFound")
            done < <(find "$___import___ImportToFindAsDirectory" -type f -iname "*.sh" -print0)

            local ___import___LoadedOneSplatFile=""

            ##
            # For each of the /** splat ___import___Found .sh files, source them unless they've been sourced
            # in which case mark ___import___AnyImportsFailed=true because re-sourcing the same import counts as a 'fail'
            # so you can detect whether or not you've imported a single import before (less useful for N imports).
            # Every sourced file should be added to IMPORTED_PATHS
            ##
            local ___import___SplatFileToImport
            for ___import___SplatFileToImport in "${___import___SplatFilesToImport[@]}"
            do
              local ___import___ItWasAlreadyImported=""

              ##
              # Check IMPORTED_PATHS else source this one and 
              ##
              local ___import___AlreadyImported
              for ___import___AlreadyImported in "${___import___ImportedPaths[@]}"
              do
                if [ "$___import___SplatFileToImport" = "$___import___AlreadyImported" ]
                then
                  ___import___ItWasAlreadyImported=true
                  break
                fi
              done

              if [ -n "$___import___ItWasAlreadyImported" ]
              then
                # One of the imports was already import, mark everything to fail
                ___import___AnyImportsFailed=true
                # And do nothing :)
              else
                # Hey! We're good to go! Let's source this and add it to the list of imported imports!
                ___import___Found=true
                ___import___LoadedOneSplatFile=true
                IMPORTED_PATHS="$IMPORTED_PATHS:$___import___SplatFileToImport"
                source "$___import___SplatFileToImport"
              fi
            done

            [ -n "$___import___LoadedOneSplatFile" ] && break # success! this import has been loaded and handled by 'import'

          # /*
          elif [[ "$___import___ImportToFind" =~ \/\*$ ]]
          then

            # strip /*
            ___import___ImportToFind="${___import___ImportToFind/%\/\*}"

            ##
            # Find the first directory that matched from IMPORT_PATHS
            ##
            local ___import___ImportToFindAsDirectory=""
            local ___import___ImportPath
            for ___import___ImportPath in "${___import___ImportPaths[@]}"
            do
              if [ -d "${___import___ImportPath}/${___import___ImportToFind}" ]
              then
                ___import___ImportToFindAsDirectory="${___import___ImportPath}/${___import___ImportToFind}"
                break
              fi
            done

            if [ -z "$___import___ImportToFindAsDirectory" ]
            then
              # Hmm. No matching directly. Let's let another import handler deal with this!
              continue # Go to the next handler!
            fi

            ##
            # Find all of the source files in /**
            ##
            declare -a ___import___SplatFilesToImport=()
            local ___import___ShFileFound
            while IFS= read -rd '' ___import___ShFileFound; do ___import___SplatFilesToImport+=("$___import___ShFileFound")
            done < <(find "$___import___ImportToFindAsDirectory" -maxdepth 1 -type f -iname "*.sh" -print0)

            local ___import___LoadedOneSplatFile=""

            ##
            # For each of the /** splat ___import___Found .sh files, source them unless they've been sourced
            # in which case mark ___import___AnyImportsFailed=true because re-sourcing the same import counts as a 'fail'
            # so you can detect whether or not you've imported a single import before (less useful for N imports).
            # Every sourced file should be added to IMPORTED_PATHS
            ##
            local ___import___SplatFileToImport
            for ___import___SplatFileToImport in "${___import___SplatFilesToImport[@]}"
            do
              local ___import___ItWasAlreadyImported=""

              ##
              # Check IMPORTED_PATHS else source this one and 
              ##
              local ___import___AlreadyImported
              for ___import___AlreadyImported in "${___import___ImportedPaths[@]}"
              do
                if [ "$___import___SplatFileToImport" = "$___import___AlreadyImported" ]
                then
                  ___import___ItWasAlreadyImported=true
                  break
                fi
              done

              if [ -n "$___import___ItWasAlreadyImported" ]
              then
                # One of the imports was already import, mark everything to fail
                ___import___AnyImportsFailed=true
                # And do nothing :)
              else
                # Hey! We're good to go! Let's source this and add it to the list of imported imports!
                ___import___Found=true
                ___import___LoadedOneSplatFile=true
                IMPORTED_PATHS="$IMPORTED_PATHS:$___import___SplatFileToImport"
                local IMPORTED_PATH="$___import___FoundMatchToSource"
                source "$___import___SplatFileToImport"
              fi
            done

            [ -n "$___import___LoadedOneSplatFile" ] && break # success! this import has been loaded and handled by 'import'

          # Regular, non-splat case
          else

            local ___import___FoundMatchToSource=""

            ##
            # Regular check against each of the import paths :)
            ##
            local ___import___ImportPath
            for ___import___ImportPath in "${___import___ImportPaths[@]}"
            do
              if [ -f "${___import___ImportPath}/${___import___ImportToFind}" ]
              then
                ___import___FoundMatchToSource="${___import___ImportPath}/${___import___ImportToFind}"
                break
              elif [ -f "${___import___ImportPath}/${___import___ImportToFind}.sh" ]
              then
                ___import___FoundMatchToSource="${___import___ImportPath}/${___import___ImportToFind}.sh"
                break
              fi
            done

            if [ -n "$___import___FoundMatchToSource" ]
            then

              local ___import___ItWasAlreadyImported=""

              ##
              # Got it! Now, let's just double check that we haven't already sourced this before...
              ##
              local ___import___AlreadyImported
              for ___import___AlreadyImported in "${___import___ImportedPaths[@]}"
              do
                if [ "$___import___FoundMatchToSource" = "$___import___AlreadyImported" ]
                then
                  ___import___ItWasAlreadyImported=true
                  break
                fi
              done

              if [ -n "$___import___ItWasAlreadyImported" ]
              then
                # One of the imports was already import, mark everything to fail
                ___import___AnyImportsFailed=true
                # And do nothing :)
              else
                # Good to go! Load it! And mark it as having been loaded.
                ___import___Found=true
                IMPORTED_PATHS="$IMPORTED_PATHS:$___import___FoundMatchToSource"
                local IMPORTED_PATH="$___import___FoundMatchToSource"
                source "$___import___FoundMatchToSource"
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
          if "$IMPORT_HANDLER" "$___import___ImportToFind"
          then
            local handlerReturnCode=$?
            case $handlerReturnCode in
              0)
                ___import___Found=true
                break # handled ok!
                ;;
              1)
                : # keep trying, didn't handle / don't want to stop!
                ;;
              2)
                ___import___Found=true
                break # handled but silent fail!
                ___import___AnyImportsFailed=true
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
      if [ -z "$___import___Found" ]
      then
        echo "import not found: $___import___ImportToFind"
        return 1
      fi
    done

    if [ -n "$___import___AnyImportsFailed" ]
    then    
      return 1
    fi
  fi
}