complete -F _markdir_complete im
complete -F _markdir_complete lm
complete -F _markdir_complete sm
complete -F _markdir_complete gm
complete -F _markdir_complete dm

export MARKFILE=~/marks

# Command line completion function for im, lm, sm, gm, and dm.
# Completes a partially enterred mark.
function _markdir_complete()
{
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    tags="$(grep ^${cur} ${MARKFILE} | awk -F: '{print $1;}')"
    COMPREPLY=( $(compgen -W "${tags}" -- ${cur}) )
}

# im - Is Marked
# Usage: im
# If the current directory is marked, shows the mark, otherwise displays an error message.
# Example:
#    $ cd /app/bea/wlserver_10.3/server/bin
#    $ im
#    wls103bin
function im()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    mark=$(grep "^[^:]*:${PWD}:" ${MARKFILE} | awk -F: '{print $1}')
    if [[ ${mark} == "" ]]; then
        echo "${PWD} is not marked."
    else
        echo "${mark}"
    fi
}

# am - Add Mark
# Adds a mark for the current working directory.
# Usage: am
# Example:
#    $ cd /app/bea/wlserver_10.3/server/bin
#    $ am wls103bin
function am()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    # Check to see if mark is already used.
    mark=$(echo ${1} | awk -F/ '{print $1}')
    markdir=$(grep "^${mark}:" ${MARKFILE} | awk -F: '{print $2}')
    if [[ ${markdir} != "" ]]; then
        echo "${1} already marks ${markdir}" >&2
        return 2
    fi


    echo "${1}:${PWD}:${2}" >> ${MARKFILE}
    sort -u ${MARKFILE} > ${MARKFILE}.tmp
    cp ${MARKFILE}.tmp ${MARKFILE}
    rm ${MARKFILE}.tmp
}

# lm - List Marks
# Usage: lm [mark]
# If mark is specified, displays all information on the mark.  Otherwise, displays the entire mark file.
# Output is formatted.
function lm()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi

    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    if [ "x${1}" = "x" ]; then
        cat ${MARKFILE} | sed 's:/cygdrive::g' |  awk -F: '{printf "%-20.20s   %-80.80s   %-20.20s\n", $1, $2, $3}'
    else
        grep "^${1}:" ${MARKFILE} | sed 's:/cygdrive::g' |  awk -F: '{printf "%-20.20   %-80.80   %-20.20s\n", $1, $2, $3}'
    fi
}

# sm - Show Mark
# Usage: sm mark
# Displays the directory associated with a mark.
# Example:
#   $ cp item200128610.jpg $(sm images)
function sm()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    mark=$(echo ${1} | awk -F/ '{print $1}')
    markdir=$(grep "^${mark}:" ${MARKFILE} | awk -F: '{print $2}')
    if [[ ${markdir} == "" ]]; then
        echo "${1} not found." >&2
    else
        subdir=$(echo ${1} | sed "s/^${mark}//g")
        echo "${markdir}${subdir}"
    fi
}

# gm - Goto Mark
# Usage: Changes the working directory to the directory associated with the mark.
# Example: gm wls103bin
function gm()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    mark=$(echo ${1} | awk -F/ '{print $1}')
    markdir=$(grep "^${mark}:" ${MARKFILE} | awk -F: '{print $2}')
    if [[ ${markdir} == "" ]]; then
        echo "${1} not found." >&2
    else
        subdir=$(echo ${1} | sed "s/^${mark}//g")
        cd "${markdir}${subdir}"
    fi
}

# dm - Delete Mark
# Usage: dm mark
# Example: dm wls103bin
function dm()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi
    grep -v "^${1}:" ${MARKFILE} > ${MARKFILE}.tmp
    cp ${MARKFILE}.tmp ${MARKFILE}
    rm ${MARKFILE}.tmp
}

# em - Edit Markfile
# Usage: em
function em()
{
    if [ ! -n "$EDITOR" ]; then
        echo "EDITOR is not set." >&2
        return 1
    fi
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi
    ${EDITOR} ${MARKFILE}
}

# cm - Check Marks
# Usage: Removes invalid marks from the mark file.
# Example: cm
function cm()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    cp ${MARKFILE} ${MARKFILE}.tmp
    rm ${MARKFILE}

    while read line; do
        mark=$(echo $line | awk -F: '{print $1}')
        markdir=$(echo $line | awk -F: '{print $2}')
        if [[ ! -d $markdir ]]; then
            echo "${mark} is not valid (${markdir})"
        else
            echo "${line}" >> ${MARKFILE}
        fi
    done < "${MARKFILE}.tmp"
    rm ${MARKFILE}.tmp
}

# xm - Execute Mark
# Usage: Executes the command associated with the directory
# Example: xm wls103bin
function xm()
{
    if [ ! -n "$MARKFILE" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi
    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi

    mark=$(grep "^[^:]*:${PWD}:" ${MARKFILE} | awk -F: '{print $1}')
    if [[ ${mark} == "" ]]; then
        echo "${PWD} is not marked."
    else
        command=$(grep "^[^:]*:${PWD}:" ${MARKFILE} | awk -F: '{print $4}')
        if [[ ${command} == "" ]]; then
            echo "No command associated with ${mark}"
        else
            sh -c ${command}
        fi
    fi
}
