if [ -f ../import.sh ]
then
  # Local development
  source ../import.sh
elif [ -f /import.sh ]
then
  # Docker
  source /import.sh
else
  echo "Missing import.sh" >&2
  exit 1
fi

IMPORT_PATH=

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

@spec.import.search() {
  expect { import -- search } toFail "Missing"
  expect { import -- search first second } toFail "Too many"

  refute import -- search dog
  expect "$( import -- search dog )" toBeEmpty

  import -- push examples/dogs

  assert import -- search dog
  expect "$( import -- search dog )" toContain "examples/dogs/dog.sh"
  expect "$( import -- search dog )" not toContain "cat.sh" "duplicate"

  import -- push examples/duplicates

  assert import -- search dog
  expect "$( import -- search dog )" toContain "examples/dogs/dog.sh"
  expect "$( import -- search dog )" toContain "duplicate"
  expect "$( import -- search dog )" not toContain "cat.sh"

  assert import -- search breeds/daschund
  refute import -- search breeds/golden_retriever

  expect "$DOG" toBeEmpty # doesn't source the file
}

@spec.import.search.withSplat() {
  import -- push examples

  expect { import -- search dogs/*/sub-breeds } toFail "* and ** operators are only supported at the end of import names, e.g. import lib/* or import lib/**"
  expect { import -- search dogs/* } not toFail
  expect { import -- search dogs/** } not toFail

  refute import -- search dogs/breeds # can't import a directory
  expect "$( import -- search dogs/breeds )" toBeEmpty

  assert import -- search dogs/breeds/*
  expect "$( import -- search dogs/breeds/* )" toContain "daschund" "pomeranian"
  expect "$( import -- search dogs/breeds/* )" not toContain "sub-breeds" "daschund-pomeranian"
}

@spec.import.search.withDoubleSplat() {
  import -- push examples

  assert import -- search dogs/breeds/**
  expect "$( import -- search dogs/breeds/** )" toContain "daschund" "pomeranian"
  expect "$( import -- search dogs/breeds/** )" toContain "sub-breeds" "daschund-pomeranian"
}

@spec.import.importHasSplat() {
  expect { import -- push foo/dogs/* } toFail "IMPORT_PATH does not support * splat operators in paths"
  expect { import -- push foo/dogs/** } toFail "IMPORT_PATH does not support * splat operators in paths"
  expect { import -- unshift foo/dogs/* } toFail "IMPORT_PATH does not support * splat operators in paths"
  expect { import -- unshift foo/dogs/** } toFail "IMPORT_PATH does not support * splat operators in paths"

  expect "$( import -- list )" toBeEmpty

  IMPORT_PATH="foo/dogs/**"

  expect { import -- list } toFail "IMPORT_PATH does not support * splat operators in paths"
  expect { import -- search dog } toFail "IMPORT_PATH does not support * splat operators in paths"
}

@spec.import.ok() {
  import -- push examples/dogs

  expect "$DOG" toBeEmpty

  assert import dog

  expect "$DOG" toEqual "Rover"

  refute import dog # already imported this

  import -- unshift examples/duplicates

  # So. If you change the paths at runtime, YES, it might re-import a certain path.
  assert import dog
  refute import dog # already imported this
  expect "$DOG" toEqual "Duplicate Dog"
}

@spec.import.ok.second() {
  import -- push examples/duplicates examples/dogs

  expect "$DOG" toBeEmpty

  assert import dog

  expect "$DOG" toEqual "Duplicate Dog"

  refute import dog # already imported this

  expect "$DOG" toEqual "Duplicate Dog"
}

@spec.import.multiple() {
  import -- push examples

  expect "$CAT" toBeEmpty
  expect "$DOG" toBeEmpty

  assert import cats/cat dogs/dog

  expect "$CAT" toEqual "Meow"
  expect "$DOG" toEqual "Rover"

  refute import cats/cat
  refute import dogs/dog
}

@spec.import.splat() {
  import -- push examples

  expect "$BREEDS" toBeEmpty

  assert import dogs/breeds/*

  refute import dogs/breeds/daschund
  refute import dogs/breeds/pomeranian

  expect "$BREEDS" toEqual ":Pomeranian:Daschund"

  assert import dogs/breeds/sub-breeds/daschund-pomeranian
  refute import dogs/breeds/sub-breeds/daschund-pomeranian

  expect "$BREEDS" toEqual ":Pomeranian:Daschund:Daschund-Pomeranian Mix"
}

@spec.import.doubleSplat() {
  import -- push examples

  expect "$BREEDS" toBeEmpty

  assert import dogs/breeds/**

  refute import dogs/breeds/daschund
  refute import dogs/breeds/pomeranian
  refute import dogs/breeds/sub-breeds/daschund-pomeranian

  expect "$BREEDS" toEqual ":Pomeranian:Daschund-Pomeranian Mix:Daschund"
}

@pending.import.withImportsInImport() {
  :
}

@pending.import.reimport() {
  :
}

my_handler() {
  FOO="You imported $1"
}

@spec.import.lookupHandlers.addHandler.list() {
  import -- push examples

  expect "$( import -- handlers )" toEqual "import"

  expect { import -- addHandler } toFail "Missing"

  import -- addHandler my_handler

  expect "$( import -- handlers )" toEqual "import\nmy_handler"
  expect "$IMPORT_HANDLERS" toEqual "import:my_handler"

  expect "$DOG" toBeEmpty
  expect "$FOO" toBeEmpty

  import dogs/dog

  expect "$DOG" toEqual "Rover"
  expect "$FOO" toBeEmpty # was handled by import OK

  import i/dont/exist

  expect "$FOO" toEqual "You imported i/dont/exist"
}

@pending.import.lookupHandlers.prependHandler() {
  : 
}

@pending.import.lookupHandlers.removeHandler() {
  :
}

some_function() {
  echo "The path is: $1"
}

@pending.import.importPaths.forEach() {
  :
  # make sure to try paths with spaces
  import -- forEach some_function
}