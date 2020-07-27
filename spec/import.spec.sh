source "../import.sh"

@spec.import.importPaths.noArgument() {
  expect { import } toFail "Missing required argument for 'import'"
}

@spec.import.importPaths.missingCommand() {
  expect { import -- } toFail "Missing required command for 'import -- [command]'"
}

@spec.import.importPaths.unknownCommand() {
  expect { import -- foo } toFail "Unknown command for 'import': foo"
}

@spec.import.importPaths.list() {
  expect "$( import -- list )" toBeEmpty

  local IMPORT_PATH="./lib"
  expect "$( import -- list )" toEqual "./lib"

  IMPORT_PATH="$IMPORT_PATH:/some/other/path"
  expect "$( import -- list )" toEqual "./lib\n/some/other/path"

  IMPORT_PATH="/added/in/front:$IMPORT_PATH"
  expect "$( import -- list )" toEqual "/added/in/front\n./lib\n/some/other/path"
}

@spec.import.importPaths.list.doesntShowDuplicates() {
  expect "$( import -- list )" toBeEmpty

  local IMPORT_PATH="./lib"
  expect "$( import -- list )" toEqual "./lib"

  # Exact same path
  IMPORT_PATH="$IMPORT_PATH:./lib"
  expect "$( import -- list )" toEqual "./lib"

  # This is the same but has a / slash at the end
  IMPORT_PATH="$IMPORT_PATH:./lib/"
  expect "$( import -- list )" toEqual "./lib"

  # This is the same but doesn't have the ./ at the start
  IMPORT_PATH="$IMPORT_PATH:lib"
  expect "$( import -- list )" toEqual "./lib"

  # This is different, it's an absolute path
  IMPORT_PATH="$IMPORT_PATH:/lib"
  expect "$( import -- list )" toEqual "./lib\n/lib"

  IMPORT_PATH="$IMPORT_PATH:/some/other/path"
  expect "$( import -- list )" toEqual "./lib\n/lib\n/some/other/path"

  IMPORT_PATH="/added/in/front:$IMPORT_PATH"
  expect "$( import -- list )" toEqual "/added/in/front\n./lib\n/lib\n/some/other/path"
  :
}

@spec.import.importPaths.push() {
  expect "$( import -- list )" toBeEmpty

  import -- push /some/path

  expect "$( import -- list )" toEqual "/some/path"
  expect "$IMPORT_PATH" toEqual "/some/path"

  import -- push ./another

  expect "$( import -- list )" toEqual "/some/path\n./another"
  expect "$IMPORT_PATH" toEqual "/some/path:./another"
}

@spec.import.importPaths.push.multiplePaths() {
  expect "$( import -- list )" toBeEmpty

  import -- push /some/path

  expect "$( import -- list )" toEqual "/some/path"
  expect "$IMPORT_PATH" toEqual "/some/path"

  import -- push ./another /and/another this/too

  expect "$( import -- list )" toEqual "/some/path\n./another\n/and/another\nthis/too"
  expect "$IMPORT_PATH" toEqual "/some/path:./another:/and/another:this/too"
}

@spec.import.importPaths.unshift() {
  expect "$( import -- list )" toBeEmpty

  import -- unshift /some/path

  expect "$( import -- list )" toEqual "/some/path"
  expect "$IMPORT_PATH" toEqual "/some/path"

  import -- unshift ./another

  expect "$( import -- list )" toEqual "./another\n/some/path"
  expect "$IMPORT_PATH" toEqual "./another:/some/path"
}

@spec.import.importPaths.unshift.multiplePaths() {
  expect "$( import -- list )" toBeEmpty

  import -- unshift /some/path

  expect "$( import -- list )" toEqual "/some/path"
  expect "$IMPORT_PATH" toEqual "/some/path"

  import -- unshift ./another /and/another this/too

  expect "$( import -- list )" toEqual "this/too\n/and/another\n./another\n/some/path"
  expect "$IMPORT_PATH" toEqual "this/too:/and/another:./another:/some/path"
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