# 🖥️ `import`

This is the heart of everything.

----

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
