#! /bin/bash

complete -F _markdir_complete_marks dm
complete -F _markdir_complete_marks gm
complete -F _markdir_complete_worktrees gw
complete -F _markdir_complete_marks lm
complete -F _markdir_complete_marks sm

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

    # If "main" is specified and we're in a git worktree, switch to the main worktree first
    if [ "${1}" = "main" ]; then
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            # Get the git directory (for worktrees, this contains /worktrees/)
            git_dir=$(git rev-parse --git-dir 2>/dev/null)
            
            # If the git dir path contains "worktrees", we're in a worktree
            if [[ "${git_dir}" == *"/worktrees/"* ]]; then
                # Get the main worktree path (first entry in worktree list)
                main_worktree=$(git worktree list --porcelain | awk '/^worktree / {print $2; exit}')
                
                if [ -n "${main_worktree}" ] && [ -d "${main_worktree}" ]; then
                    # Switch to the main worktree and return
                    cd "${main_worktree}" || return
                    return 0
                fi
            fi
        fi
        # If we get here with "main", fall through to normal mark lookup
    fi

    extended_mark="${1}"
    extended_markdir=$(_get_extended_markdir "${extended_mark}") || { echo "${1} not found." >&2; return 2; }
    cd "${extended_markdir}" || return
}

# gw - Goto Worktree
# Usage: Changes the working directory to the specified git worktree.
#        If a mark is specified, starts from that mark's directory.
# Example: 
#   gw CCA-10
#   gw fpl-cs-cni-infrastructure CCA-11
gw()
{
    local base_dir
    local worktree_name

    if [ -z "${1}" ]; then
        echo "Usage: gw [mark] worktree_name" >&2
        return 1
    fi

    # Check if two parameters provided (mark and worktree)
    if [ -n "${2}" ]; then
        _verify_markfile || return 1

        mark="${1}"
        worktree_name="${2}"

        # Get the directory for the mark
        base_dir=$(_get_directory_for_mark "${mark}")
        if [[ "${base_dir}" = "null" ]]; then
            echo "Mark '${mark}' not found." >&2
            return 2
        fi

        if [[ ! -d "${base_dir}" ]]; then
            echo "Directory '${base_dir}' does not exist." >&2
            return 2
        fi
    else
        # Single parameter - worktree name from current directory
        worktree_name="${1}"
        base_dir="${PWD}"
    fi

    # Check if the base directory is in a git repository
    if ! git -C "${base_dir}" rev-parse --git-dir > /dev/null 2>&1; then
        echo "Not in a git repository." >&2
        return 1
    fi

    # Get the list of worktrees and find the matching one
    # Parse porcelain format: worktree line comes before branch line
    worktree_path=$(git -C "${base_dir}" worktree list --porcelain | awk -v name="${worktree_name}" '
        /^worktree / { path = $2 }
        /^branch / && $2 ~ name"$" { print path; exit }
    ')

    if [ -z "${worktree_path}" ]; then
        echo "Worktree '${worktree_name}' not found." >&2
        return 2
    fi

    cd "${worktree_path}" || return
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
    (if [ -z "${mark}" ]; then
        jq -r ".marks | keys[] as \$k | \"\(\$k)\t\(.[\$k] | .description)\t\(.[\$k] | .dir)\"" "${MARKFILE}"
    else
        jq -r "[.marks.\"${mark}\" | { key: \"${mark}\", description: .description, dir: .dir } | values[]] | join(\"\t\")" "${MARKFILE}"
    fi) | awk -F\\t '{printf "\033[38;5;69m%-35.35s \033[38;5;34m%-30.30s \033[38;5;34m%s\n", $1, $2, $3}'
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

# Command line completion function for gw.
# Completes marks (first arg) or worktree names (first or second arg).
_markdir_complete_worktrees()
{
    local worktrees
    local marks
    local base_dir

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    # If completing the first argument, offer both marks and worktrees
    if [ "${COMP_CWORD}" -eq 1 ]; then
        # Get marks
        if [ -n "${MARKFILE}" ] && [ -f "${MARKFILE}" ]; then
            marks=$(jq -r '.marks | to_entries[] | .key' "${MARKFILE}" 2>/dev/null)
        fi

        # Get worktrees from current directory
        if git rev-parse --git-dir > /dev/null 2>&1; then
            worktrees=$(git worktree list --porcelain | grep "^branch " | cut -d'/' -f3-)
        fi

        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "${marks} ${worktrees}" -- "${cur}") )

    # If completing the second argument, get worktrees from the mark's directory
    elif [ "${COMP_CWORD}" -eq 2 ]; then
        local mark="${COMP_WORDS[1]}"

        # Try to get the directory for the mark
        if [ -n "${MARKFILE}" ] && [ -f "${MARKFILE}" ]; then
            base_dir=$(jq -r ".marks.\"${mark}\".dir" "${MARKFILE}" 2>/dev/null)

            if [ -n "${base_dir}" ] && [ "${base_dir}" != "null" ] && [ -d "${base_dir}" ]; then
                # Get worktrees from the mark's directory
                if git -C "${base_dir}" rev-parse --git-dir > /dev/null 2>&1; then
                    worktrees=$(git -C "${base_dir}" worktree list --porcelain | grep "^branch " | cut -d'/' -f3-)
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "${worktrees}" -- "${cur}") )
                fi
            fi
        fi
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

_get_extended_markdir()
{
    mark=$(echo "${1}" | awk -F/ '{print $1}')
    directory=$(_get_directory_for_mark "${mark}")
    if [[ "${directory}" = "null" ]]; then
        echo "${directory} not found?"
        return 2
    else
        # shellcheck disable=SC2001
        subdir=$(echo "${1}" | sed "s/^${mark}//g")
        echo "${directory}${subdir}"
    fi
}

_verify_markfile || return 1
