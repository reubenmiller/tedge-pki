
package_dir := "dist"

# Build packages
build:
    mkdir -p dist
    nfpm package --config cfssl/nfpm.yaml -p apk -t "{{package_dir}}/"
    nfpm package --config cfssl/nfpm.yaml -p rpm -t "{{package_dir}}/"
    nfpm package --config cfssl/nfpm.yaml -p deb -t "{{package_dir}}/"

    nfpm package --config openssl/nfpm.yaml -p apk -t "{{package_dir}}/"
    nfpm package --config openssl/nfpm.yaml -p rpm -t "{{package_dir}}/"
    nfpm package --config openssl/nfpm.yaml -p deb -t "{{package_dir}}/"

# Publish packages
publish *args="":
    ./ci/publish.sh --path "{{package_dir}}" {{args}}

# Start a cfssl server
start-cfssl-server *ARGS:
    docker compose -f cfssl/server/docker-compose.yaml up --build {{ARGS}}
