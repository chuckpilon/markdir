# markdir

bash functions for tagging directories for easy navigation and use in other commands that take directory name(s) as parameters.

Marks (aka tags) are stored in ~/marks, a text file referred to as the mark file. Commands are provided to read and write marks in the mark file as well as perform maintenance on the mark file.


## Functions

### am - Add Mark
Adds a mark to the mark file.

Usage: `am `*`mark`*`[description]`

```
$ cd /var/log
$ am log "Log files"
```

### cm - Check Mark File
Prunes marks from the mark file that do not have valid associated directories.

Usage: `cm`

`$ cm`

### dm - Delete Mark

Deletes a mark

Usage: `dm `*`mark`*

`$ dm log`

### em - Edit Mark File

Edits the Mark File using the editor set in the EDITOR environment variable.

Usage: `em`

`$ em`

### gm - Goto Mark
Changes the current directory to the directory associated with the mark

Usage: `gm `*`mark`*

`$ gm log`

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
documents    /home/user/Documents     My documents
log          /var/log                 Log files

$ lm log
log          /var/log                 Log files
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

## Installation
1. Place `markdir.sh` in a readable location.

        $ mkdir ~/markdir
        $ cp markdir.sh ~/markdir

2. In the login script (e.g. `~\.bashrc`), source in `markdir.sh`

        source ~/markdir/markdir.sh

3. Copy the files in the man subdirectory to the man1 subdirectory of one of the directories specified in the output of the manpath command:

        $ manpath
        /usr/local/man:/usr/local/share/man:/usr/share/man

        $ sudo cp man/*.1 /usr/local/man

# LICENSE
Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
