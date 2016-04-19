FROM tykio/tyk-gateway:v2.0

COPY tyk.conf /opt/tyk-gateway/tyk.conf

COPY deployments-0.0.1.json /opt/tyk-gateway/apps/

# CMD ["/opt/tyk-gateway/tyk", "--conf=/opt/tyk-gateway/tyk.conf", "--debug"]
