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
