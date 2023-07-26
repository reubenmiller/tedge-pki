# PKI extensions

This project contains some implementations of some PKI providers in order to generate/sign device certificates for usage with thin-edge.io.

## Supported PKI Providers

### cfssl

Cloudflare's PKI tool which supports the generation of certificates via a HTTP endpoint.

**Pre-requisites**

The server and client have the following dependencies.

**Server**

* [cfssl](https://github.com/cloudflare/cfssl#installation)
* [cfssljson](https://github.com/cloudflare/cfssl#installation)

**Client**

* curl
* jq
* openssl

1. Start the cfssl PKI server

    ```sh
    ./cfssl/server/start.sh
    ```

2. Upload the CA certificate to Cumulocity IoT (if you have not already done so)

    Using [go-c8y-cli](https://goc8ycli.netlify.app/), you can upload the `ca.pem` certificate to Cumulocity IoT.

    ```sh
    c8y devicemanagement certificates create \
        --autoRegistrationEnabled \
        --file ./cfssl/server/ca.pem \
        --name "Local thin-edge.io CA" \
        --status ENABLED
    ```

    Alternatively, you can manually upload the `ca.pem` file using the Cumulocity IoT Device Management application under `Trusted Certificates`.

    **Note**

    * Uploading a trusted certificate requires the `ROLE_TENANT_MANAGEMENT_ADMIN` or `ROLE_TENANT_ADMIN` permissions.

3. In another console, run the client pki script to generate new cert pair (public and private key)

    ```sh
    ./cfssl/pki-cfssl new mycustomname
    ```

    Inspect the output files

    ```sh
    ls -l *.csr tedge*
    ```

    *Output*

    ```sh
    -rw-r--r--  1 cdundee  staff  2446 Jul 26 17:04 tedge-certificate.pem
    -rw-r--r--  1 cdundee  staff  1704 Jul 26 17:04 tedge-private-key.pem
    ```
