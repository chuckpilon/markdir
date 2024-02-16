#! /bin/bash

complete -F _markdir_complete_marks dm
complete -F _markdir_complete_marks gm
complete -F _markdir_complete_marks lm
complete -F _markdir_complete_marks sm
complete -F _markdir_complete_tasks xd

# am - Add Mark
# Adds a mark for the current working directory. The mark defaults to the directory's
# basename.
# 
# Usage: am [mark]
# Example:
#    $ cd /Users/cpilon/code/myproject
#    $ am myproject
am()
{
    local basemarkfile
    local tmpmarkfile

    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        mark=$(basename "${PWD}")
    else
        mark="${1}"
    fi

    directory=$(_get_directory_for_mark "${mark}")
    if [ "${directory}" != "null" ]; then
        echo "${mark} already marks ${directory}" >&2
        return 2
    fi

    description="${2}"

    basemarkfile=$(basename "${MARKFILE}")
    tmpmarkfile="/tmp/${basemarkfile}"
    jq ".marks |= . + { \"${mark}\": { \"dir\": \"${PWD}\", \"description\": \"${description}\" } }" "${MARKFILE}" > "${tmpmarkfile}"
    cp "${tmpmarkfile}" "${MARKFILE}"
    rm "${tmpmarkfile}"
}

# asm - Add Session Mark
asm()
{
    _verify_markfile || return 1

    basemarkfile=$(basename "${MARKFILE}")
    tmpmarkfile="/tmp/${basemarkfile}"
    jq ".sessions |= . + { \"${TERM_SESSION_ID}\": { \"dir\": \"${PWD}\" } }" "${MARKFILE}" > "${tmpmarkfile}"
    cp "${tmpmarkfile}" "${MARKFILE}"
    rm "${tmpmarkfile}"
}

# bd - Build Directory
# Usage: Executes the build task associated with the directory
# Example: bd
bd()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "build" "FALSE" "${@}" || return 1
}

# cm - Check Marks
# Usage: Removes invalid marks from the mark file.
# Example: cm
cm()
{
    local marks
    _verify_markfile || return 1

    # shellcheck disable=SC2207
    marks=( $(jq -r '.marks | keys | @sh' "${MARKFILE}" | tr -d \') )
    for mark in "${marks[@]}"
    do
        directory=$(_get_directory_for_mark "${mark}")
        if [[ ! -d "$directory" ]]; then
            echo "${mark} is not valid (${directory})"
            dm "${mark}"
        fi
    done
}

# dm - Delete Mark
# Usage: dm mark
# Example: dm myproject
dm()
{
    local basemarkfile
    local tmpmarkfile

    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        echo "Usage: dm mark" >&2
        return 1
    fi

    mark="${1}"
    basemarkfile=$(basename "${MARKFILE}")
    tmpmarkfile="/tmp/${basemarkfile}"
    
    jq ".marks |= del(.\"$mark\")" "${MARKFILE}" > "${tmpmarkfile}"
    cp "${tmpmarkfile}" "${MARKFILE}"
    rm "${tmpmarkfile}"
}

# ed - Environment for Directory
# Usage: ed [directory|mark]
ed()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        directory="${PWD}"
    elif [ -d "${1}" ]; then
        directory="${1}"
    else 
        directory=$(_get_directory_for_mark "${1}")
        if [ "$directory" = "null" ]; then
            echo "${1} not found." >&2; return 2;
        fi
    fi

    environment_structure=$(jq -r ".directories.\"${directory}\".env" "${MARKFILE}")
    if [ "${environment_structure}" != "null" ]; then
        environment=$(echo "${environment_structure}" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr '\n' ' ' | tr '$' ' ')
        echo "${environment}"
        export "${environment?}"
    fi
}

# em - Edit Markfile
# Usage: em
em()
{
    _verify_markfile || return 1

    if [ -z "$EDITOR" ]; then
        echo "EDITOR is not set." >&2
        return 1
    fi

    ${EDITOR} "${MARKFILE}"
}

# gm - Goto Mark
# Usage: Changes the working directory to the directory associated with the mark.
# Example: gm myproject
gm()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        echo "Usage: sm mark" >&2
        return 1
    fi

    extended_mark="${1}"
    extended_markdir=$(_get_extended_markdir "${extended_mark}") || { echo "${1} not found." >&2; return 2; }
    cd "${extended_markdir}" || return
    ed "$@"
}

# gms - Goto Mark for Session
# Usage: Changes the working directory to the directory associated with the session.
# Example: gms
gms()
{
    _verify_markfile || return 1

    dir=$(_get_directory_for_session)
    if [ -z "${dir}" ]; then
        echo "No directory found for session" >&2
        return 1
    fi

    cd "${dir}" || return 1
}

# bd - Install Directory
# Usage: Executes the install task associated with the directory
# Example: id
id()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "install" "FALSE" "$@" || return 1
}

# im - Is Marked
# Usage: im
# If the current directory is marked, shows the mark, otherwise displays an error message.
# Example:
#    $ cd /Users/cpilon/code/myproject
#    $ im
#    myproject
im()
{
    _verify_markfile || return 1

    mark=$(_get_mark_for_directory "${PWD}")
    if [[ "${mark}" = "" ]]; then
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
lm()
{
    _verify_markfile || return 1

    mark="${1}"
    if [ -z "${mark}" ]; then
        jq '.marks | to_entries | map( { mark: .key, description: .value.description, dir: .value.dir })' "${MARKFILE}"
    else
        jq ".marks.\"${mark}\"" "${MARKFILE}"
    fi
}

# sm - Show Mark
# Usage: sm mark
# Displays the directory associated with a mark.
# Example:
#   $ cp item200128610.jpg $(sm images)
sm()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        echo "Usage: sm mark" >&2
        return 1
    fi

    extended_mark="${1}"
    extended_markdir=$(_get_extended_markdir "${extended_mark}") || { echo "${1} not found." >&2; return 2; }
    echo "${extended_markdir}"
}

# td - Test Directory
# Usage: Executes the test task associated with the directory
# Example: td
td()
{
    _verify_markfile || return 1

    _execute_directory_task "${PWD}" "test" "FALSE" "${@}" || return 1
}

# sd - Show Directory
# Usage: sd [directory|mark]
# Displays the information associated with a directory or a marked directory.
# Example:
#   $ sd myproject
sd()
{
    _verify_markfile || return 1

    if [ -z "${1}" ]; then
        directory="$PWD"
    elif [ -d "${1}" ]; then
        directory="${1}"
    else 
        directory=$(_get_directory_for_mark "${1}")
        if [ "$directory" = "null" ]; then
            echo "${1} not found." >&2; return 2;
        fi
    fi
    _get_info_for_directory "${directory}" || { echo "${1} not found." >&2; return 2; }
}

utd()
{
    echo "Untagged directories:"

    # shellcheck disable=SC2207
    directories=( $(jq -r '.directories | to_entries[] | .key' "${MARKFILE}") )
    for directory in "${directories[@]}"
    do
        mark=$(_get_mark_for_directory "${directory}")
        if [[ "${mark}" = "" ]]; then
            echo "${directory} is not marked." >&2
        fi
    done


    # jq -r ".directories.\"${directory}\"" "${MARKFILE}"
    # Get list of directories from .directories
    # For each directory, see if there exists a marks.xxx.dir qith a matching directory
    # If not print directory name
}


# xd - Execute Directory
# Usage: Executes the specified task associated with the directory, or the default task by default
# Example: xd myproject
xd()
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
    _execute_directory_task "${PWD}" "${task}" "${show_only}" "${@}"
}

_get_info_for_directory()
{
    directory="${1}"
    jq -r ".directories.\"${directory}\"" "${MARKFILE}"
}

_get_directory_for_mark()
{
    mark="${1}"
    directory=$(jq -r ".marks.\"${mark}\".dir" "${MARKFILE}")
    echo "${directory}"
}

_get_directory_for_session()
{
    session=${TERM_SESSION_ID}
    dir=$(jq -r ".sessions.\"${session}\".dir" "${MARKFILE}")
    if [ "${dir}" = "null" ]; then
        echo ""
    else
        echo "${dir}"
    fi
}

_get_mark_for_directory()
{
    directory="${1}"
    mark=$(jq -r ".marks | to_entries[] | select(.value.dir == \"${directory}\") | .key" "${MARKFILE}")
    echo "${mark}"
}

# Executes the task (build, test, default, etc.) for the mark
_execute_directory_task()
{
    directory="${1}"
    task="${2}"
    show_only="${3}"
    shift 3

    command_structure=$(jq -r ".directories.\"${directory}\".tasks.\"${task}\"" "${MARKFILE}")
    if [ "${command_structure}" = "null" ]; then
        echo "${task} task not set for ${directory}" >&2
        return 2
    fi
    command=$(echo "${command_structure}" | jq -r ".command")
    environment_structure=$(echo "${command_structure}" | jq -r ".env")
    if [[ "${environment_structure}" = "null" ]]; then
        environment=""
    else
        environment=$(echo "${environment_structure}" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr '\n' ' ' | tr '$' ' ')
    fi

    echo "${environment}${command} ${*}"

    if [ "${show_only}" = "FALSE" ]; then
        sh -c "${environment}${command} ${*}"
    fi

}

_verify_markfile()
{
    if [ -z "${MARKFILE}" ]; then
        echo "MARKFILE is not set." >&2
        return 1
    fi

    if [ ! -f "${MARKFILE}" ]; then
        touch "${MARKFILE}"
    fi
}

# Command line completion function for im, lm, sm, gm, and dm.
# Completes a partially entered mark.
_markdir_complete_marks()
{
    local marks

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    marks=$(jq -r '.marks | to_entries[] | .key' "${MARKFILE}")
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${marks}" -- "${cur}") )
}

# Command line completion function for xd.
# Completes a partially entered mark.
_markdir_complete_tasks()
{
    local tasks

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    tasks=$(jq -r ".directories.\"${PWD}\".tasks | try keys | join(\" \")" "${MARKFILE}")
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${tasks}" -- "${cur}") )
}

_get_extended_markdir()
{
    mark=$(echo "${1}" | awk -F/ '{print $1}')
    directory=$(_get_directory_for_mark "${mark}")
    if [[ "${directory}" = "null" ]]; then
        return 2
    else
        # shellcheck disable=SC2001
        subdir=$(echo "${1}" | sed "s/^${mark}//g")
        echo "${directory}${subdir}"
    fi
}
