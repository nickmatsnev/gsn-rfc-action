FROM docker-dhl-local.artifactory.dhl.com/ubuntu:18.04

RUN apk add --no-cache bash

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN chmod u+x ./**/*.sh

RUN chmod +x client/gha_client.sh

ENTRYPOINT ["/entrypoint.sh"]
