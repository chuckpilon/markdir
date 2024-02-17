# markdir

Shell functions for 
- tagging directories with marks (aka tags) for easy navigation and use in other commands that take directory name(s) as parameters
- executing directory-specific aliases (tasks)

Marks and tasks are configured in a JSON file referred to as the mark file. Commands are provided to read and write marks in the mark file as well as perform maintenance on the mark file.


## Functions

### am - Add Mark
Adds a mark to the mark file.

Usage: `am `*`mark`*`[description]`

```
$ cd /Users/me/code/myproject
$ am myproject "My Project"
```

### bd - Build Directory
Executes the `build` task associated with the current directory.

Usage: `bd`

```
$ gm myproject
$ bd
pants package ::
```

### cm - Check Mark File
Prunes marks from the mark file that do not have valid associated directories.

Usage: `cm`

```
$ cm
themark is not valid (/tmp/baddirectory)"
```

### dm - Delete Mark

Deletes a mark

Usage: `dm `*`mark`*

`$ dm log`

### em - Edit Mark File

Edits the Mark File using the editor set in the EDITOR environment variable.

Usage: `em`

```
$ em
```

### gm - Goto Mark
Changes the current directory to the directory associated with the mark

Usage: `gm `*`mark`*

```
$ gm myproject
```

### im - Is Marked
Shows mark for the current directory

Usage: `im`

```
$ cd /Users/me/code/myproject
$ im
myproject
```

### lm - List Marks
Lists all marks

Usage: `lm [mark]`

```
$ lm
[
  {
    "mark": "myproject",
    "description": "My Project",
    "dir": "/Users/me/code/myproject"
  },
  ...
]

$ lm myproject
{
  "mark": "myproject",
  "description": "My Project",
  "dir": "/Users/me/code/myproject"
}
```

### sm - Show Mark
Shows the directory associated with a mark

Usage: `sm `*`mark`*

```
$ cat $(sm myproject)/README.md
# My Project
This is the README for My Project.

## Background
```

### st - Show Tasks
Shows the task names and definitions associated with a mark

Usage: `st `*`mark`*

```
$ gm myproject
$ st
build                pants package ::
default              pants run app
lint                 pants fmt lint ::
test                 pants test ::
```

### td - Test Directory
Executes the `test` task associated with the current directory.

Usage: `td`

```
$ gm myproject
$ td
pants test ::
```

### xd - Execute Directory
Executes the specified task associated with the current directory, or the run task by default.

Usage: `xd [task]`

```
$ gm myproject
$ xd
pants run app
$ xd lint
pants fmt lint ::
```



## Installation
1. Place `markdir.sh` in a readable location:

        $ mkdir ~/markdir
        $ cp markdir.sh ~/markdir

2. Copy `marks.json` into a writable location:

        $ cp marks.json ~
 
3. In the login script (e.g. `~\.bashrc`), set `MARKFILE` to the location of `marks.json` and source in `markdir.sh`

        export MARKFILE=~/marks.json
        source ~/markdir/markdir.sh

4. Copy the files in the man subdirectory to the man1 subdirectory of one of the directories specified in the output of the manpath command:

        $ manpath
        /usr/local/man:/usr/local/share/man:/usr/share/man

        $ sudo cp man/*.1 /usr/local/share/man/man1

# LICENSE
Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
