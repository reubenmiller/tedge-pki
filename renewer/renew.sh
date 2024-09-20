#!/bin/sh
set -e

#
# Settings
#
DEFAULT_BASEDIR=${DEFAULT_BASEDIR:-/etc/tedge/device-certs}
BASEDIR="${BASEDIR:-}"
DEVICE_CERT="${DEVICE_CERT:-}"
MIN_VALIDITY_SEC=${MIN_VALIDITY_SEC:-}

if [ -z "$BASEDIR" ]; then
    if [ -d "$DEFAULT_BASEDIR" ]; then
        BASEDIR="$DEFAULT_BASEDIR"
    else
        # default to current directory
        BASEDIR="."
    fi
fi

if [ -z "$MIN_VALIDITY_SEC" ] || [ "$MIN_VALIDITY_SEC" -lt 60 ]; then
    # 604800  = (7 days in seconds)
    MIN_VALIDITY_SEC="604800"
fi

if [ -z "$DEVICE_CERT" ]; then
    DEVICE_CERT="$BASEDIR/tedge-certificate.pem"
fi

#
# Functions
#
expires_soon() {
    if openssl x509 -checkend "$MIN_VALIDITY_SEC" -noout -in "$DEVICE_CERT" >/dev/null 2>&1; then
        echo "Certificate does not expire within $MIN_VALIDITY_SEC seconds" >&2
        return 1
    fi

    echo "Certificate expires within $MIN_VALIDITY_SEC seconds" >&2
    return 0
}

renew() {
    echo "Renewing certificate" >&2
    TEDGE="tedge"
    if command -V tedge-cli >/dev/null 2>&1; then
        TEDGE="tedge-cli"
    fi
    rm -f "/tmp/tedge.csr"
    "$TEDGE" cert create-csr --output-path "/tmp/tedge.csr"
    pki-cfssl sign "/tmp/tedge.csr"
}

#
# main
#
COMMAND=check_renew
if [ $# -gt 0 ]; then
    COMMAND="$1"
    shift
fi

case "$COMMAND" in
    check)
        expires_soon
        ;;
    renew)
        renew
        ;;
    check_renew)
        if expires_soon; then
            renew
        fi
        ;;
    *)
        echo "Unknown command" >&2
        exit 1
        ;;
esac
