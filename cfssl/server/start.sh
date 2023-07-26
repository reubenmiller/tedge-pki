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

start_server() {
    if [ ! -f "$dir/ca-key.pem" ] && [ ! -f "$dir/ca.pem" ]; then
        echo "[cfssl] Initializing the CA" >&2
        cfssl genkey -initca "$dir/csr.json" | cfssljson -bare ca
    fi
    echo "[cfssl] Starting PKI server" >&2
    cfssl serve -ca-key "$dir/ca-key.pem" -ca "$dir/ca.pem" "$@"
}

start_server "$@"
