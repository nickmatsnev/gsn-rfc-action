FROM artifactory.dhl.com/alpine:latest

RUN apk add --no-cache bash

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN chmod u+x ./**/*.sh

RUN chmod +x client/gha_client.sh

ENTRYPOINT ["/entrypoint.sh"]
