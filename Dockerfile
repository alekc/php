FROM php:7.2-fpm-alpine as base

ENV PHP_LIB_PATH "/usr/local/lib/php/extensions/no-debug-non-zts-20170718"
ENV PHP_DBG_PATH "/usr/local/php-dbg"
ENV PHP_CONF_D "/usr/local/etc/php/conf.d"


FROM base as builder
ARG NEW_RELIC_URL

#prepare debugging environment
RUN mkdir ${PHP_DBG_PATH}
RUN apk add --no-cache $PHPIZE_DEPS
RUN yes | pecl install xdebug \
    && apk del $PHPIZE_DEPS

RUN echo "Installing Newrelic" \
ARG NEW_RELIC_URL="https://download.newrelic.com/php_agent/release/newrelic-php5-8.3.0.226-linux.tar.gz"

RUN echo "${NEW_RELIC_URL}"
RUN wget -O - https://download.newrelic.com/php_agent/release/newrelic-php5-8.3.0.226-linux.tar.gz | tar -C /tmp -zx && \
        NR_INSTALL_USE_CP_NOT_LN=1 /tmp/newrelic-php5-*/newrelic-install install && \
        rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*
#        \
#        -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "${NEW_RELIC_APP_NAME}"/' \
#        ${PHP_CONF_D}newrelic.ini

RUN ls -l /usr/local/lib/php/extensions/no-debug-non-zts-20170718


#Final image construction
FROM base as final
COPY --from=builder ${PHP_LIB_PATH}/xdebug.so ${PHP_DBG_PATH}/xdebug.so
COPY --from=builder ${PHP_LIB_PATH}/newrelic.so ${PHP_DBG_PATH}/newrelic.so
COPY --from=builder ${PHP_CONF_D}/newrelic.ini ${PHP_DBG_PATH}/newrelic.ini

RUN echo "zend_extension=${PHP_LIB_PATH}/xdebug.so" > ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_host=docker" >> ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_enable=1" >> ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> ${PHP_CONF_D}/xdebug.ini \
    && echo "xdebug.remote_port=9000" >> ${PHP_CONF_D}/xdebug.ini \
    && mv ${PHP_CONF_D}/xdebug.ini ${PHP_DBG_PATH}/xdebug.ini

RUN echo "Installing Nusphere dbg"

COPY ./dbg-php-7.2.so ${PHP_DBG_PATH}/dbg-php-7.2.so

RUN docker-php-ext-install \
    pdo_mysql \
    sockets

#
RUN mv /usr/local/bin/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint-orig
COPY ./docker-php-entrypoint.sh /usr/local/bin/docker-php-entrypoint
RUN chmod +x /usr/local/bin/docker-php-entrypoint

ENV NEW_RELIC_ENABLED false
ENV NEW_RELIC_KEY  "xxxxx"
ENV NEW_RELIC_APP_NAME "MyAPP"

ENV PHPED_ENABLED false
ENV DEBUG_CONFIG_FILES false
ENV PHP_DBG_ALLOWED_HOSTS "172.18.0.0/24 localhost 127.0.0.1 .alekc.org host.docker.internal .localhost"
