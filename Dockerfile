FROM kfp-components-docker-dev-local.artifactory.dhl.com/alpine:latest

RUN apk add --no-cache bash

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN find . -type f -name "*.sh" -exec chmod +x {} \;

ENTRYPOINT ["/entrypoint.sh"]
