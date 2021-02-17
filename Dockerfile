FROM alpine:latest
RUN apk --no-cache add curl python3 bash
RUN  ln -sf python3 /usr/bin/python
COPY terraform-cloud-connect /usr/sbin/
RUN chmod +x /usr/sbin/terraform-cloud-connect
ENTRYPOINT ["terraform-cloud-connect"]
