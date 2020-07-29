# 🖥️ `import`

This is the heart of everything.

---

```
📂 folder

  🗂️ my-common-scripts

    📁 subfolder
       - hello.sh
       - world.sh

    - foo.sh
    - bar.sh
```

```sh
source "import.sh"

export IMPORT_PATH="$HOME/folder/my-common-scripts:$HOME/folder/other-scripts"
```

```sh
import {foo,bar}

foo "Hello"
bar "World"
```

```sh
import subfolder/*

hello "There"
```

---

## Features

- Imports things.

## Other Features

- Will only import each thing once.

## Additionally

- Does one thing and does it well.

## Finally

- Supports sourcing all scripts in a subdirectory with `import path/*`
- Supports sourcing ALL scripts in a subdirectory with `import path/**`
- Uses `IMPORT_PATH` for searching for `.sh` files to import (`:` separated)

## Nitty Gritty

- Imported file can get the path used to source it with `IMPORTED_PATH`
- Imported file can get the handler used to source it with `IMPORT_HANDLER`
- List of all sourced files is available in `IMPORTED_PATHS`
- Version of `import.sh` used is available at `IMPORT_VERSION`

> Custom handlers might not provide `IMPORTED_PATH` or `IMPORTED_PATHS`

---

## Extensibility

What if you want to handle `import foo` yourself?

- You can add your own handler!
- Handlers are just functions which receive the same arguments as `import`
- There is a list of handlers defined in `IMPORT_HANDLERS`
- If you add your handler to the front, it'll get first dibs!
- If you add your handler to the back, it'll only be called for missing imports.
- If your handler `return 0` then the next handlers will not be called
- If your handler `return 1` then the next handler will be called
- If your handler `return 2` then the `import` function will halt

```sh
# Write a function that simply prints whatever is passed to `import`
# and it returns 1 so that the next handler will be called
# (which will actually perform the real file import)
log_import() {
  echo "You imported $*"
  return 1
}

import -- prependHandler log_import
```

```sh
# Write a function that will be added to the end and so it only
# gets called if all of the other handlers fail to 'handle' the import
# (in other words, when an import is missing/unknown this will be called)
import_missing() {
  echo "Aw jeez, looks like you couldn't import $*"
  echo "Maybe I should look around for another place to find it..."
}

import -- appendHandler import_missing
```

```sh
# Note: if you modify IMPORT_HANDLERS directly, you need to make sure
#       that you include 'import' itself, or the import handler won't run.
export IMPORT_HANDLERS="log_import:import:import_missing"
```

```sh
import [path][/*[*]]

import -- help
import -- version

import -- list                # list directories in IMPORT_PATH
import -- push    [dir] [dir] # push onto back of IMPORT_PATH
import -- unshift [dir] [dir] # add to front of IMPORT_PATH
import -- search  [path]      # print all locations path is found

import -- handlers       # list all handler functions in order
import -- prependHandler # add handler as first handler
import -- appendHandler  # add handler as last handler
import -- removeHandler  # remove a handler
```
