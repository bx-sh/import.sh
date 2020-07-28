# 🖥️ `import`

This is the heart of everything.

----

```
📂 folder

  🗂️ my-common-scripts

    📁 subfolder
       - script1.sh
       - script2.sh
      
    - foo.sh
    - bar.sh
    
  🗂️ other-scripts
    - hello.sh
    - world.sh
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
