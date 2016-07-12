# API Gateway

Dockerfile for the API Gateway based on NGINX, plus the relevant server configuration.

It is a slightly customized version of the official nginx `mainline/debian/jessie` docker image:
- using `nginx-extras` instead of the basic `nginx` (e.g. for embedded lua scripting)
- removed unused packages from `apt-get install`

The gateway has two responsibilities:

- proxying requests to Mender services while rewriting URLs from a public API scheme to an internal one
- automatically routing selected requests to auth verification endpoints before passing them on

# Proxying and URL rewriting

Mender APIs are accessible via the following public URL scheme:

`/api/<target>/<version>/<service>/<resource>...`

where:
- `target` selects the internally enforced auth method and is one of:
    - `devices` - for device-originating requests
    - `integrations` - for web UIs

- `version` is of the `maj.min` format

- `service` is the service selector, currently supported:
    - `admission`
    - `authentication`
    - `deployments`

- `resource` is the service resource/method, basically the 'rest' of the URL, and is passed verbatim to the selected service

Examples:

`POST /api/devices/0.1/authentication/auth_requests`

`GET /api/integrations/0.1/admission/devices`

As a consequence of URL rewriting, the gateway also rewrites all URLs in headers returned from services to the public scheme, so that they can be readily followed by the client.

# HTTPS

The gateway enforces HTTPS-only traffic; a self-signed Mender Software certificate, embedded in the gateway image, is used for this purpose by default.
The user can retrieve this certificate to make it available to devices, or override it with a custom certificate (self-signed or otherwise); both procedures are described below.

## Obtaining the certificate

The certificate file path inside the running container is:

`/var/www/mendersoftware/cert/cert.pem`

To copy this file to the local filesystem, run the [docker cp](https://docs.docker.com/engine/reference/commandline/cp/) command:

`sudo docker cp integration_mender-api-gateway_1:/var/www/mendersoftware/cert/cert.pem /local/path/to/cert/`

## Substituting the certificate

A custom certificate and key can be provided to the container via a mounted Docker volume.
The relevant paths inside the container are as follows:

- `/var/www/mendersoftware/cert/cert.pem`
- `/var/www/mendersoftware/cert/key.pem`

Override these files by adding the following volumes into `docker-compose.yaml`:

```
    mender-api-gateway:
        ...
        volumes:
            - /local/path/to/cert.pem:/var/www/mendersoftware/cert/cert.pem
            - /local/path/to/key.pem:/var/www/mendersoftware/cert/key.pem
        ...
```
The gateway must be restarted for these changes to take effect.

### Generating a self-signed certificate

A self-signed certificate can be generated with the `openssl` command e.g. as follows:

`openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes`

For details consult the openssl manual.

# Authentication

The gateway enforces authentication by first routing requests to a dedicated auth verification endpoint (via the `auth_request` module):

- `devices` requests are verified via devauth's `tokens/verify` endpoint
- `integrations` requests are currently not authenticated at all; they will have a dedicated auth service in the future

# Requirements
- the image requires all services to be up and running and accessible by their domain names; the name resolution happens at nginx startup, if it fails - the container exits (it only makes sense to run the container in `integration`)

- as usual it's useful to map some ports:
    - `80` for `http` (this is used for now)
    - `443` for `https`

- the `MAPPED_PORT` env var, containing the number of the mapped `http` port, must be passed to the container (nginx doesn't know the outside port and will use 80 for all header rewriting otherwise)
