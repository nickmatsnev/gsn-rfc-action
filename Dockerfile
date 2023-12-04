FROM kfp-components-docker-dev-local.artifactory.dhl.com/alpine:latest

RUN apk add --no-cache bash pcre grep curl

ENV NO_PROXY=https://servicenow-uat.dhl.com

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN chmod u+x ./**/*.sh

RUN chmod +x client/gha_client.sh

ENTRYPOINT ["/entrypoint.sh"]
