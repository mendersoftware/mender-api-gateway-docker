[![Build Status](https://travis-ci.org/mendersoftware/mender-api-gateway-docker.svg?branch=master)](https://travis-ci.org/mendersoftware/mender-api-gateway-docker)
[![Docker pulls](https://img.shields.io/docker/pulls/mendersoftware/api-gateway.svg?maxAge=3600)](https://hub.docker.com/r/mendersoftware/api-gateway/)

Mender API Gateway
==============================================

Mender is an open source over-the-air (OTA) software updater for embedded Linux
devices. Mender comprises a client running at the embedded device, as well as
a server that manages deployments across many devices.

This repository contains the Mender API Gateway, which is part of the
Mender server. The Mender server is designed as a microservices architecture
and comprises several repositories.

The API Gateway serves as an entrypoint for all HTTP communication with Mender. Its main responsibility is the proxying of requests to Mender services, while rewriting URLs from a public API scheme to an internal one. The gateway also enforces authentication upon every request.

![Mender logo](https://mender.io/user/pages/04.resources/_logos/logoS.png)


## Getting started

To start using Mender, we recommend that you begin with the Getting started
section in [the Mender documentation](https://docs.mender.io/).


## Building from source

As the Mender server is designed as microservices architecture, it requires several
repositories to be built to be fully functional. If you are testing the Mender server it
is therefore easier to follow the getting started section above as it integrates these
services.

If you would like to build th Mender API Gateway independently, you can follow
these steps:

```
git clone https://github.com/mendersoftware/mender-api-gateway-docker.git
cd mender-api-gateway-docker
sudo docker build -t mendersoftware/api-gateway .
```

## Contributing

We welcome and ask for your contribution. If you would like to contribute to Mender, please read our guide on how to best get started [contributing code or
documentation](https://github.com/mendersoftware/mender/blob/master/CONTRIBUTING.md).

## License

Mender is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/mendersoftware/mender-api-gateway-docker/blob/master/LICENSE) for the
full license text.

## Security disclosure

We take security very seriously. If you come across any issue regarding
security, please disclose the information by sending an email to
[security@mender.io](security@mender.io). Please do not create a new public
issue. We thank you in advance for your cooperation.

## Connect with us

* Join our [Google
  group](https://groups.google.com/a/lists.mender.io/forum/#!forum/mender)
* Follow us on [Twitter](https://twitter.com/mender_io?target=_blank). Please
  feel free to tweet us questions.
* Fork us on [Github](https://github.com/mendersoftware)
* Email us at [contact@mender.io](mailto:contact@mender.io)
