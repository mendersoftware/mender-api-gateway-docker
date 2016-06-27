FROM tykio/tyk-gateway:v2.1.0.2

COPY tyk.conf /opt/tyk-gateway/tyk.conf

COPY deployments-0.0.1.json /opt/tyk-gateway/apps/
COPY deviceauth-0.1.0.json /opt/tyk-gateway/apps/

# CMD ["/opt/tyk-gateway/tyk", "--conf=/opt/tyk-gateway/tyk.conf", "--debug"]
