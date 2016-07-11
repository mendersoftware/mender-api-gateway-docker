FROM debian:jessie

ENV NGINX_EXTRAS_VERSION 1.6.2-5+deb8u2+b1

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
                        ca-certificates \
                        nginx-extras=${NGINX_EXTRAS_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

COPY ./cert/cert.pem /var/www/mendersoftware/cert/cert.pem
COPY ./cert/key.pem /var/www/mendersoftware/cert/key.pem

CMD ["nginx", "-g", "daemon off;"]

COPY nginx.conf /etc/nginx/nginx.conf
