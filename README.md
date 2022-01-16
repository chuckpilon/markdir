# markdir

Shell functions for tagging directories for easy navigation and use in other commands that take directory name(s) as parameters.

Marks (aka tags) are stored in a text file referred to as the mark file. Commands are provided to read and write marks in the mark file as well as perform maintenance on the mark file.


## Functions

### am - Add Mark
Adds a mark to the mark file.

Usage: `am `*`mark`*`[description]`

```
$ cd /var/log
$ am log "Log files"
```

### bm - Build Mark
Executes the `build` task associated with the current directory.

Usage: `bm`

```
$ cd /projects/project
$ bm
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
$ gm log
```

### im - Is Marked
Shows mark for the current directory

Usage: `im`

```
$ cd /var/log
$ im
log
```

### lm - List Marks
Lists all marks

Usage: `lm [mark]`

```
$ lm
[
  {
    "mark": "log",
    "description": "Log files",
    "dir": "/var/log"
  },
  ...
]

$ lm log
{
  "dir": "/var/log",
  "description": "Log files"
}
```

### sm - Show Mark
Shows the directory associated with a mark

Usage: `sm `*`mark`*

```
$ ls -1 $(sm log)/apache2
access.log
error.log
other_vhosts_access.log
```

### tm - Test Mark
Executes the `test` task associated with the current directory.

Usage: `tm`

```
$ gm project
$ tm
yarn test
```

### xm - eXecute Mark
Executes the `run` task associated with the current directory.

Usage: `xm [task]`

```
$ gm project
$ xm
yarn dev
$ xm lint
yarn lint
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
