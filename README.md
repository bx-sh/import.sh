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
- Uses `IMPORT_PATH` for searching for `.sh` files to import
