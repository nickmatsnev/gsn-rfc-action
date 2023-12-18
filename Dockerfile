FROM kfp-components-docker-dev-local.artifactory.dhl.com/alpine:latest

RUN apk add --no-cache bash pcre grep curl

COPY . .

RUN chmod u+x ./**/*.sh

ENTRYPOINT ["/entrypoint.sh"]
