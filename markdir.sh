complete -F _markdir_complete dm
complete -F _markdir_complete gm
complete -F _markdir_complete lm
complete -F _markdir_complete sm
complete -F _markdir_complete_tasks xd

# am - Add Mark
# Adds a mark for the current working directory. The mark defaults to the directory's
# basename.
# 
# Usage: am [mark]
# Example:
#    $ cd /app/bea/wlserver_10.3/server/bin
#    $ am wls103bin
function am()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        mark=`basename ${PWD}`
    else
        mark="${1}"
    fi

    directory=`_get_directory_for_mark "${mark}"`
    if [ "${directory}" != "null" ]; then
        echo "${mark} already marks ${directory}" >&2
        return 2
    fi

    description="${2}"

    cat "${MARKFILE}" | jq ".marks |= . + { \"${mark}\": { \"dir\": \"${PWD}\", \"description\": \"${description}\" } }" > /tmp/$(basename "$MARKFILE")
    cp /tmp/$(basename "$MARKFILE") "${MARKFILE}"
    rm /tmp/$(basename "$MARKFILE")
}

# bd - Build Directory
# Usage: Executes the build task associated with the directory
# Example: bd
function bd()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "build" "FALSE" ${*} || return 1
}

# cm - Check Marks
# Usage: Removes invalid marks from the mark file.
# Example: cm
function cm()
{
    _verify_markfile || return 1

    MARKS=$((cat "${MARKFILE}" | jq -r '.marks | keys | @sh') | tr -d \'\")
    for mark in "${MARKS[@]}"
    do
        directory=`_get_directory_for_mark "${mark}"`
        if [[ ! -d "$directory" ]]; then
            echo "${mark} is not valid (${directory})"
            dm "${mark}"
        fi
    done
}

# dm - Delete Mark
# Usage: dm mark
# Example: dm wls103bin
function dm()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        echo "Usage: dm mark" >&2
        return 1
    fi

    mark="${1}"
    cat "${MARKFILE}" | jq ".marks |= del(.\"$mark\")" > /tmp/$(basename "$MARKFILE")
    cp /tmp/$(basename "$MARKFILE") "${MARKFILE}"
    rm /tmp/$(basename "$MARKFILE")
}

# ed - Environment for Directory
# Usage: ed [directory|mark]
function ed()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        directory="$PWD"
    elif [ -d "${1}" ]; then
        directory="${1}"
    else 
        directory=`_get_directory_for_mark "${1}"`
        if [ $directory == "null" ]; then
            echo "${1} not found." >&2; return 2;
        fi
    fi

    environment_structure=`cat "${MARKFILE}" | jq -r ".directories.\"${directory}\".env"`
    if [ "${environment_structure}" != "null" ]; then
        environment=`echo ${environment_structure} | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr '\n' ' ' | tr '$' ' '`
        echo "${environment}"
        export "${environment}"
    fi
}

# em - Edit Markfile
# Usage: em
function em()
{
    _verify_markfile || return 1

    if [ ! -n "$EDITOR" ]; then
        echo "EDITOR is not set." >&2
        return 1
    fi

    ${EDITOR} "${MARKFILE}"
}

# gm - Goto Mark
# Usage: Changes the working directory to the directory associated with the mark.
# Example: gm wls103bin
function gm()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        echo "Usage: sm mark" >&2
        return 1
    fi

    extended_mark="${1}"
    extended_markdir=`_get_extended_markdir "${extended_mark}"` || { echo "${1} not found." >&2; return 2; }
    cd "${extended_markdir}"
    ed
}

# gms - Goto Mark for Session
# Usage: Changes the working directory to the directory associated with the session.
# Example: gms
function gms()
{
    _verify_markfile || return 1

    extended_mark="${1}"
    mark=`_get_mark_for_session`
    gm $mark

    # extended_markdir=`_get_extended_markdir "${extended_mark}"` || { echo "${1} not found." >&2; return 2; }
    # cd "${extended_markdir}"
    # ed


}

# bd - Install Directory
# Usage: Executes the install task associated with the directory
# Example: id
function id()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "install" "FALSE" ${*} || return 1
}

# ud - Up Directory
# Usage: Executes the up task associated with the directory
# Example: ud
function ud()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "up" "FALSE" ${*} || return 1
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
    _verify_markfile || return 1

    mark=`_get_mark_for_directory "${PWD}"`
    if [[ "${mark}" == "" ]]; then
        echo "${PWD} is not marked." >&2
        return 1
    else
        echo "${mark}"
    fi
}

# lm - List Marks
# Usage: lm [mark]
# If mark is specified, displays all information on the mark.  Otherwise, displays all marks and
# directories.
function lm()
{
    _verify_markfile || return 1

    mark="${1}"
    if [ -z "${mark}" ]; then
        cat "${MARKFILE}" | jq '.marks | to_entries | map( { mark: .key, description: .value.description, dir: .value.dir })'
    else
        cat "${MARKFILE}" | jq ".marks.\"${mark}\""
    fi
}

# sm - Show Mark
# Usage: sm mark
# Displays the directory associated with a mark.
# Example:
#   $ cp item200128610.jpg $(sm images)
function sm()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        echo "Usage: sm mark" >&2
        return 1
    fi

    extended_mark="${1}"
    extended_markdir=`_get_extended_markdir "${extended_mark}"` || { echo "${1} not found." >&2; return 2; }
    echo "${extended_markdir}"
}

# td - Test Directory
# Usage: Executes the test task associated with the directory
# Example: td
function td()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "test" "FALSE" ${*} || return 1
}

# sd - Show Directory
# Usage: sd [directory|mark]
# Displays the information associated with a directory or a marked directory.
# Example:
#   $ sd project
function sd()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        directory="$PWD"
    elif [ -d "${1}" ]; then
        directory="${1}"
    else 
        directory=`_get_directory_for_mark "${1}"`
        if [ $directory == "null" ]; then
            echo "${1} not found." >&2; return 2;
        fi
    fi
    _get_info_for_directory "${directory}" || { echo "${1} not found." >&2; return 2; }
}


# xd - Execute Directory
# Usage: Executes the specified task associated with the directory, or the default task by default
# Example: xd wls103bin
function xd()
{
    _verify_markfile || return 1

    if [ "${1}" = "-s" ]; then
        show_only="TRUE"
        shift 1
    else
        show_only="FALSE"
    fi

    if [ -z "${1}" ]; then
        task="default"
    else
        task="${1}"
        shift 1
    fi
    _execute_directory_task "${PWD}" "${task}" "${show_only}" ${*}
}

function _get_info_for_directory()
{
    directory="${1}"
    cat "${MARKFILE}" | jq -r ".directories.\"${directory}\""
}

function _get_directory_for_mark()
{
    mark="${1}"
    directory=`cat "${MARKFILE}" | jq -r ".marks.\"${mark}\".dir"`
    echo "${directory}"
}

function _get_mark_for_session()
{
    session=${TERM_SESSION_ID}
    mark=`cat "${MARKFILE}" | jq -r ".sessions.\"${session}\".mark"`
    echo "${mark}"
}

function _get_mark_for_directory()
{
    directory="${1}"
    mark=`cat "${MARKFILE}" | jq -r ".marks | to_entries[] | select(.value.dir == \"${directory}\") | .key"`
    echo "${mark}"
}

# Executes the task (build, test, default, etc.) for the mark
function _execute_directory_task()
{
    directory="${1}"
    task="${2}"
    show_only="${3}"
    shift 3

    command_structure=`cat "${MARKFILE}" | jq -r ".directories.\"${directory}\".tasks.\"${task}\""`
    if [ "${command_structure}" = "null" ]; then
        echo "${task} task not set for ${directory}" >&2
        return 2
    fi
    command=`echo ${command_structure} | jq -r ".command"`
    environment_structure=`echo ${command_structure} | jq -r ".env"`
    if [[ "${environment_structure}" == "null" ]]; then
        environment=""
    else
        environment=`echo ${environment_structure} | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr '\n' ' ' | tr '$' ' '`
    fi

    echo "${environment}${command} ${*}"

    if [ "${show_only}" = "FALSE" ]; then
        sh -c "${environment}${command} ${*}"
    fi

}

function _verify_markfile()
{
    if [ ! -n "${MARKFILE}" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi

    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi
}

# Command line completion function for im, lm, sm, gm, and dm.
# Completes a partially enterred mark.
function _markdir_complete()
{
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    MARKS=`cat "${MARKFILE}" | jq -r '.marks | to_entries[] | .key'`
    COMPREPLY=( $(compgen -W "${MARKS}" -- ${cur}) )
}

# Command line completion function for xd.
# Completes a partially enterred mark.
function _markdir_complete_tasks()
{
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    TASKS=`cat "${MARKFILE}" | jq -r ".directories.\"${PWD}\".tasks | try keys | join(\" \")"`
    COMPREPLY=( $(compgen -W "${TASKS}" -- ${cur}) )
}

function _get_extended_markdir()
{
    mark=`echo "${1}" | awk -F/ '{print $1}'`
    directory=`_get_directory_for_mark "${mark}"`
    if [[ "${directory}" == "null" ]]; then
        return 2
    else
        subdir=`echo "${1}" | sed "s/^${mark}//g"`
        echo "${directory}${subdir}"
    fi
}