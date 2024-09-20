#!/bin/sh
set -e

ROOT_DIR="/opt/homebrew"
export STEPPATH="$ROOT_DIR/etc/smallstep"
export PASSWORD_FILE="$STEPPATH/password.txt"

mkdir -p "$STEPPATH"

if [ ! -f "$PASSWORD_FILE" ]; then
    printf "asdf" > "$PASSWORD_FILE"
fi

CURRENT_USER=$(id -u)
if [ "$CURRENT_USER" = 0 ]; then
    chown root:root "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
fi

# TODO: Add password file
step ca init --key-password-file="$PASSWORD_FILE" --deployment-type=standalone --provisioner=tedge --name tedge-local --dns 127.0.0.1 --dns "$(hostname)" --address=:8443

tedge config set mqtt.external.ca_path "$(step path)/certs/root_ca.crt"
tedge config set mqtt.external.cert_file "$(step path)/certs/intermediate_ca.crt"
tedge config set mqtt.external.key_file "$(step path)/secrets/intermediate_ca_key"

# FIXME: should thin-edge.io support the external listener insteaf of having to edit the mosquitto configure directly
cat << EOF > ".tmp/tls-listener.conf"
listener 8883 0.0.0.0
allow_anonymous false
require_certificate true
use_identity_as_username true
use_username_as_clientid false
cafile $(step path)/certs/root_ca.crt
certfile $(step path)/certs/intermediate_ca.crt
keyfile $(step path)/secrets/intermediate_ca_key
EOF

    # TODO: Where can the tls listener be added to, conf.d, or /etc/tedge/mosquitto-conf/?
    mv ".tmp/tls-listener.conf" "$ROOT_DIR/etc/mosquitto/conf.d./tls-listener.conf"

# Run the process
if command -V systemctl >/dev/null 2>&1; then
    systemctl enable step-ca
    systemctl start step-ca
else
    echo "WARNING: Could not find a compatible service manager"
    if ! pgrep -f step-ca; then
        step-ca &
    fi
fi

# Show instructions
cat <<EOT
Getting started with smallstep pki

#DEVICE_ID=$(hostname)
#step ca certificate "$(hostname)" tmp/svc.crt tmp/svc.key

# 1. Get a token for bootstrapping (requires the provisioning password)

DEVICE_ID=$(tedge config get device.id)
step ca token "$DEVICE_ID"

# 2. On the child device, run:
enroll.sh <token>
EOT


verify() {
    # TODO: Add a test client to check all of the available services, MQTT, file transfer service, local c8y proxy
    mkdir .tmp/
    step ca certificate --force "test_client" .tmp/svc.crt .tmp/svc.key

    # TEDGE_MQTT_CLIENT_AUTH_CA_DIR=
    TEDGE_MQTT_CLIENT_PORT=8883 TEDGE_MQTT_CLIENT_AUTH_CERT_FILE=.tmp/svc.crt TEDGE_MQTT_CLIENT_AUTH_KEY_FILE=.tmp/svc.key  tedge mqtt sub '#'
}

verify
