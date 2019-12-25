FROM openresty/openresty:1.13.6.2-0-alpine

# forward request and error logs to docker log collector
RUN mkdir -p /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN apk update && \
apk add bind-tools curl bash

EXPOSE 443

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# copy optionally included config files
# create placeholder dir where they'll be linked
COPY tenantadm.nginx.conf /usr/local/openresty/nginx/conf/tenantadm.nginx.conf

RUN mkdir -p /usr/local/openresty/nginx/conf/optional/endpoints

COPY entrypoint.sh /entrypoint.sh

COPY reload-when-hosts-changed /reload-when-hosts-changed

RUN mkdir -p /data/nginx/cache/ui

HEALTHCHECK --interval=8s --timeout=15s --start-period=120s --retries=128 CMD nc -z 127.0.0.1:443
ENTRYPOINT ["/entrypoint.sh"]
