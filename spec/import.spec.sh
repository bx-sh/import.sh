source "../import.sh"

@spec.import.importPaths.noArgument() {
  expect { import } toFail "Missing required argument for 'import'"
}

@spec.import.importPaths.missingCommand() {
  expect { import -- } toFail "Missing required command for 'import -- [command]'"
}

@pending.import.importPaths.unknownCommand() {
  :
}

@pending.import.importPaths.list() {
  expect "$( import -- list )" toBeEmpty

  local IMPORT_PATH="./lib"
  expect "$( import -- list )" toEqual "./lib"

  IMPORT_PATH="$IMPORT_PATH:/some/other/path"
  expect "$( import -- list )" toEqual "./lib\n/some/other/path"

  IMPORT_PATH="/added/in/front:$IMPORT_PATH"
  expect "$( import -- list )" toEqual "/added/in/front\n./lib\n/some/other/path"
}

@pending.import.importPaths.list.doesntShowDuplicates() {
  :
}

@pending.import.importPaths.push.pathAlreadyPresent() {
  :
}

@pending.import.importPaths.push() {
  :
  import -- push
}

@pending.import.importPaths.unshift.pathAlreadyPresent() {
  :
}

@pending.import.importPaths.unshift() {
  :
  import -- unshift
}

some_function() {
  echo "The path is: $1"
}

@pending.import.importPaths.forEach() {
  :
  # make sure to try paths with spaces
  import -- forEach some_function
}

@pending.import.importPaths.search() {
  :
}

@pending.import.missingFile() {
  :
}

@pending.import.alreadyImported() {
  :
}

@pending.import.ok() {
  :
}