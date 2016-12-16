FROM openresty/openresty:alpine


# forward request and error logs to docker log collector
RUN mkdir -p /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 443

COPY ./cert/cert.pem /var/www/mendersoftware/cert/cert.pem
COPY ./cert/key.pem /var/www/mendersoftware/cert/key.pem

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
