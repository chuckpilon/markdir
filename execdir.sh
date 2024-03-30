#! /bin/bash

complete -F _markdir_complete_tasks xd

# bd - Build Directory
# Usage: Executes the build task associated with the directory
# Example: bd
bd()
{
    _verify_execfile || return 1

    _execute_directory_task "${PWD}" "build" "FALSE" "${@}" || return 1
}

# ed - Environment for Directory
# Usage: ed [directory]
ed()
{
    _verify_execfile || return 1

    if [ -z "${1}" ]; then
        directory="${PWD}"
    elif [ -d "${1}" ]; then
        directory="${1}"
    else 
        echo "${1} not found." >&2; return 2;
    fi

    environment_structure=$(jq -r ".directories.\"${directory}\".env" "${EXECFILE}")
    if [ "${environment_structure}" != "null" ]; then
        environment=$(echo "${environment_structure}" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr '\n' ' ' | tr '$' ' ')
        echo "${environment}"
        export "${environment?}"
    fi
}

# TODO: [feature/split-dir-exec] Need something for EXECFILE
# em - Edit Markfile
# Usage: em
# em()
# {
#     _verify_execfile || return 1

#     if [ -z "$EDITOR" ]; then
#         echo "EDITOR is not set." >&2
#         return 1
#     fi

#     ${EDITOR} "${EXECFILE}"
# }

# id - Initialize Directory
# Usage: Initializes the current directory by adding an entry to the directories dictionary
# and configuring a default task that echos the directoy path
# Example: id
id()
{
    _verify_execfile || return 1

    command_structure=$(jq -r ".directories.\"${PWD}\"" "${EXECFILE}")
    if [ "${command_structure}" != "null" ]; then
        echo "${PWD} is already initialized" >&2
        return 2
    fi

    baseexecfile=$(basename "${EXECFILE}")
    tmpexecfile="/tmp/${baseexecfile}"
    jq ".directories |= . + { \"${PWD}\": { \"tasks\": { \"default\": { \"command\": \"echo ${PWD}\"} } } }" "${EXECFILE}" > "${tmpexecfile}"
    cp "${tmpexecfile}" "${EXECFILE}"
    rm "${tmpexecfile}"
}

# sd - Show Directory
# Usage: sd [directory]
# Displays the information associated with a directory.
# Example:
#   $ sd myproject
sd()
{
    _verify_execfile || return 1

    if [ -z "${1}" ]; then
        directory="$PWD"
    elif [ -d "${1}" ]; then
        directory="${1}"
    else 
        echo "${1} not found." >&2; return 2;
    fi
    _get_info_for_directory "${directory}" || { echo "${1} not found." >&2; return 2; }
}

# td - Test Directory
# Usage: Executes the test task associated with the directory
# Example: td
td()
{
    _verify_execfile || return 1

    _execute_directory_task "${PWD}" "test" "FALSE" "${@}" || return 1
}

# st - Show Tasks
# Usage: st [directory|mark]
# Displays the tasks associated with a directory or a marked directory.
# Example:
#   $ st myproject
st()
{
    _verify_execfile || return 1

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
    _get_tasks_for_directory "${directory}" || { echo "${1} not found." >&2; return 2; }
}

# xd - Execute Directory
# Usage: Executes the specified task associated with the directory, or the default task by default
# Example: xd myproject
xd()
{
    _verify_execfile || return 1

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
    jq -r ".directories.\"${directory}\"" "${EXECFILE}"
}

_get_tasks_for_directory()
{
    directory="${1}"
    jq -r ".directories.\"${directory}\".tasks | keys[] as \$k | \"\(\$k)\t\(.[\$k] | .command)\"" "${EXECFILE}" | awk -F\\t '{printf "\033[38;5;69m%-20.20s \033[38;5;34m%s\n", $1, $2}'
}

# Executes the task (build, test, default, etc.) for the mark
_execute_directory_task()
{
    directory="${1}"
    task="${2}"
    show_only="${3}"
    shift 3

    command_structure=$(jq -r ".directories.\"${directory}\".tasks.\"${task}\"" "${EXECFILE}")
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

_verify_execfile()
{
    if [ -z "${EXECFILE}" ]; then
        echo "EXECFILE is not set." >&2
        return 1
    fi

    if [ ! -f "${EXECFILE}" ]; then
        touch "${EXECFILE}"
    fi
}

# Command line completion function for xd.
# Completes a partially entered mark.
_markdir_complete_tasks()
{
    local tasks

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    tasks=$(jq -r ".directories.\"${PWD}\".tasks | try keys | join(\" \")" "${EXECFILE}")
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${tasks}" -- "${cur}") )
}

_verify_execfile || return 1
