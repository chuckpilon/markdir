#! /bin/bash

# ads - Add Directory for Session
ads()
{
    _verify_sessionfile || return 1

    basesessionfile=$(basename "${SESSIONFILE}")
    tmpsessionfile="/tmp/${basesessionfile}"
    jq ".sessions |= . + { \"${TERM_SESSION_ID}\": { \"dir\": \"${PWD}\" } }" "${SESSIONFILE}" > "${tmpsessionfile}"
    cp "${tmpsessionfile}" "${SESSIONFILE}"
    rm "${tmpsessionfile}"
}

# dds - Delete Directory for Session
# Usage: dds
# Example: dds
dds()
{
    _verify_sessionfile || return 1

    basesessionfile=$(basename "${SESSIONFILE}")
    tmpsessionfile="/tmp/${basesessionfile}"
    jq ".sessions |= del(.\"${TERM_SESSION_ID}\")" "${SESSIONFILE}" > "${tmpsessionfile}"
    cp "${tmpsessionfile}" "${SESSIONFILE}"
    rm "${tmpsessionfile}"
}

# gds - Goto Directory for Session
# Usage: Changes the working directory to the directory associated with the session.
# Example: gds
gds()
{
    _verify_sessionfile || return 1

    dir=$(_get_directory_for_session)
    if [ -z "${dir}" ]; then
        echo "No directory found for session" >&2
        return 1
    fi

    cd "${dir}" || return 1
}

_verify_sessionfile()
{
    if [ -z "${SESSIONFILE}" ]; then
        echo "SESSIONFILE is not set." >&2
        return 1
    fi

    if [ ! -f "${SESSIONFILE}" ]; then
        touch "${SESSIONFILE}"
    fi
}
