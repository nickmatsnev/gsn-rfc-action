FROM php:8.1-fpm-alpine

RUN apk add --no-cache bash

COPY . .

COPY entrypoint.sh /entrypoint.sh

RUN find . -type f -name "*.sh" -exec chmod +x {} \;

ENTRYPOINT ["/entrypoint.sh"]
