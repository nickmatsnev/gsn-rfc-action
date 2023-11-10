FROM docker.artifactory.dhl.com/node:18-alpine

RUN apk add --no-cache bash

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN chmod u+x ./**/*.sh

RUN chmod +x client/gha_client.sh

ENTRYPOINT ["/entrypoint.sh"]
