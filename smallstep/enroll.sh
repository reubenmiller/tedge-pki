#!/bin/sh
set -e

TOKEN=

if [ "$1" -gt 0 ]; then
    TOKEN="$1"
fi

if ! echo check | read -rs; then
    echo "No token was provided and your console does not support prompting for a password securely"
    echo "Please set the following variable instead:"
    echo "          TOKEN=<token>"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    printf "Token: "
    read -rs TOKEN
fi

DEVICE_ID=${DEVICE_ID:-}

if [ -z "$DEVICE_ID" ]; then
    if command -V hostname >/dev/null 2>&1; then
        echo "Using hostname as the device-id" >&2
        DEVICE_ID=$(hostname)
    fi
fi

# TODO: Add the --force option to the `tedge cert create-csr` which will overwrite any existing files
rm -f "$(tedge config get device.csr_path)"
tedge cert create-csr --device-id "$DEVICE_ID"

if [ -n "$TOKEN" ]; then
    step ca sign --token "$TOKEN" --not-after=24h "$(tedge config get device.csr_path)" "$(tedge config get device.cert_path)"
else
    step ca sign --not-after=24h "$(tedge config get device.csr_path)" "$(tedge config get device.cert_path)"
fi

# Set the paths to the certificates
tedge config set c8y.proxy.cert_path "$(tedge config get device.cert_path)"
tedge config set c8y.proxy.key_path "$(tedge config get device.key_path)"
tedge config set c8y.proxy.ca_path "$(tedge config get c8y.root_cert_path)"

tedge config set http.cert_path "$(tedge config get device.cert_path)"
tedge config set http.key_path  "$(tedge config get device.key_path)"
tedge config set http.ca_path   "$(tedge config get c8y.root_cert_path)"

tedge config set mqtt.client.auth.cert_file "$(tedge config get device.cert_path)"
tedge config set mqtt.client.auth.key_file "$(tedge config get device.key_path)"
tedge config set mqtt.client.auth.ca_dir "$(tedge config get c8y.root_cert_path)"

tedge config set mqtt.device_topic_id "device/$DEVICE_ID//"

# TODO: Verify each of the entrypoints

# Sta
if command -V systemctl >/dev/null 2>&1; then
    echo "Starting the tedge-agent as a service"
    systemctl enable tedge-agent
    systemctl start tedge-agent
fi
