FROM kfp-components-docker-dev-local.artifactory.dhl.com/alpine:latest

RUN apk add --no-cache bash

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN chmod u+x ./**/*.sh

RUN chmod +x client/gha_client.sh

RUN ls -la

ENTRYPOINT ["/entrypoint.sh"]
