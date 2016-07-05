# API Gateway

Below are a handful of technical details regarding the solution, with tips on
extension/modification, possible TODOs, etc.

# Components

## Dockerfile

This is a copy of the `mainline/debian/jessie` official nginx image, with:
- `nginx` replaced with `nginx-extras`
- removed unnecessary dependencies

The original idea was to use the offical micro `alpine` image, however it doesn't
contain some useful extensions (e.g. embedded lua). They would have to be obtained
and compiled manually, since `apk` doesn't provide them either.

Debian has a very convenient package `nginx-extras` with a lot of useful extensions
prebuilt, so this distro was used instead.

### Port mapping
When run inside a container, nginx does not know about the external port mappings
assigned by Docker. The mapped port number is therefore passed via the `MAPPED_PORT`
environment variable, so that URLs can be handled and translated correctly.

The only port currently supported is 80, so this is what `MAPPED_PORT` points to.
In the near future, all http communication will be disabled, so this will be
moved to 443.

The mapping problem can be solved with a more sophisticated approach (mounting docker's
daemon socket + introspection), but the simplest solution was selected for now.

## nginx.conf

This is the single place where proxying, authentication and URL rewriting happens.
This file is based on a default nginx.conf added to official nginx docker images, with the
following customizations:

- removed parts concerning static content serving
- added Mender-specific locations, proxy directives, etc.
- keeping the original logging settings, as they seem sane
    - note that access.log and error.log are not real files - in the Dockerfile
      they are linked to /dev/stdout and /dev/stderr

# Operation

## Proxying and routing

The external/public URL scheme translation is accomplished through a set of
locations containing the built-in `proxy_pass` directive.

Depending on the required granularity, locations specify anything from an
exact resource/method, e.g.:

`/api/devices/0.1/authentication/auth_requests`

to a catch-all regex matching all possible resources of a given service:

`/api/integrations/0.1/deployments(?<endpoint>/.*)`

Locations are split according to the target - `devices` or `integrations`.
Since the target indicates the auth method (different for device- and ui-originating
requests) it is not uncommon to have the same or similar service locations duplicated.
Example:

- `/api/devices/0.1/deployments/devices/(?<devid>.*)/update`
    - authenticate devices when they ask for updates
- `/api/integrations/0.1/deployments(?<endpoint>/.*)`
    - pass all UI-originating requests(including the `update` request) directly
      to the service (no auth)

### Header transformation

Some service methods return headers containing URLs to other resources.It is the
 gateway's responsibility to translate these URLs back to the external schema, so
they can be readily navigated to by the client.

Currently supported headers:

- `Location`
    - supported OOTB via the builtin `proxy_redirect` directive (contrary to its
      name, its only responsibility is rewriting `Location` and `Refresh` headers)

- `Link`
    - transformed via a custom lua script, since nginx can't handle multi-valued
      headers (even though it's legal according to RFCs) - only the first value is
      taken into account
    - it should be noted that even with single-valued headers, upstream header
      rewriting is problematic:
        - in vanilla nginx, one can only add/remove headers - no builtin parse + replace
        - headers *can* be replaced via the `headers_more` extension, but this
          extension doesn't help with parsing them according to a regex (it must
          be done with a cleverly written `map` directive, decomposing the builtin
          `$http_sent_<header_name>` variable - see docs)

## Authentication

Requests to the `devices` target are first authenticated against the `tokens/verify`
method of the Device Auth service (exception: `POST /auth_requests`, which requests
the token). This happens transparently to the client thanks to the `auth_request` directive.

Requests to the `integrations` target are not authenticated at all. In the future
they will have a dedicated auth verification endpoint.

# Extension/modification

## Bump a service's internal version

- find all locations accessing the service (esp. note it might be included twice
  for different targets)

- in every location, change the internal service version to the desired one
  (e.g. 0.1.0 -> 0.2.0)

## Add a new service

- determine if the service should be accessible to devices and/or UIs - possibly
  its location will need to be duplicated for different targets

- add new locations, based on existing ones - a couple of notes:
    - regex locations need a `rewrite` directive before a `proxy_pass`
    - `devices` locations need the `auth_request` directive

- if the service returns URL-containing headers (Link, Location), include the
  `proxy_redirect` directive or custom processing as outlined above

# Possible TODOs:
- adapt a smaller base docker image (alpine, iron.io, etc.) or research existing
  nginx micro-containers

- make the inline lua block for `Link` rewriting accessible to
  other locations

- use introspection to get container's port mappings
