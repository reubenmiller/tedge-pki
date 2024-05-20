#!/bin/sh

help() {
    echo "
Start a PKI server. If the CA certificate will be created if they do not already exist

Usage
    $0

Examples
    $0
    \$ Start a pki server which reachable via 127.0.0.1:8888
"
}

dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

CA_CERT_DIR=${CA_CERT_DIR:-/data}
CA_CERT_KEY=${CA_CERT_KEY:-$CA_CERT_DIR/ca-key.pem}
CA_CERT_PUB=${CA_CERT_PUB:-$CA_CERT_DIR/ca.pem}
MUTUAL_TLS_CA=${MUTUAL_TLS_CA:-$CA_CERT_DIR/mutual-tls-ca.pem}

if [ -n "$CA_CERT_CONTENTS_KEY" ]; then
    echo "Loading CA cert key from env variable: CERT_CONTENTS_KEY" >&2
    printf "%s" "$CA_CERT_CONTENTS_KEY" | base64 -d > "$CA_CERT_KEY"
fi

if [ -n "$CA_CERT_CONTENTS_PUB" ]; then
    echo "Loading CA cert file from env variable: CERT_CONTENTS_PUB" >&2
    printf "%s" "$CA_CERT_CONTENTS_PUB" | base64 -d > "$CA_CERT_PUB"
fi

if [ ! -f "$CA_CERT_KEY" ] || [ ! -f "$CA_CERT_PUB" ]; then
    echo "[cfssl] Initializing the CA" >&2
    cfssl genkey -initca "$dir/csr.json" | cfssljson -bare ca
fi

if [ -n "$MUTUAL_TLS_CA_CONTENTS" ]; then
    echo "Loading mutual TLS CA cert file from env variable: MUTUAL_TLS_CA_CONTENTS" >&2
    printf "%s" "$CA_CERT_CONTENTS_PUB" | base64 -d > "$MUTUAL_TLS_CA"
fi

if [ -f "$MUTUAL_TLS_CA" ]; then
    echo "[cfssl] Starting PKI server with mutual TLS client validation" >&2
    exec cfssl serve -ca-key "$CA_CERT_KEY" -ca "$CA_CERT_PUB" -mutual-tls-ca "$MUTUAL_TLS_CA" "$@"
else
    echo "[cfssl] Starting PKI server" >&2
    exec cfssl serve -ca-key "$CA_CERT_KEY" -ca "$CA_CERT_PUB" "$@"
fi
