#!/bin/sh

# Configure new relic
if [ "${NEW_RELIC_ENABLED}" ]; then
    echo "Enabling new relic"
    cp "${PHP_DBG_PATH}/newrelic.so" "${PHP_LIB_PATH}/newrelic.so"
    cp "${PHP_DBG_PATH}/newrelic.ini" "${PHP_CONF_D}/newrelic.ini"
    sed -i -e 's/"REPLACE_WITH_REAL_KEY"/"${NEW_RELIC_KEY}"/'

    cat "${PHP_CONF_D}/newrelic.ini"
else
    echo "Disabling new relic"
    rm "${PHP_LIB_PATH}/newrelic.so"
    rm "${PHP_CONF_D}/newrelic.ini"
fi

# Configure phpd debugger
if [ "${PHPED_ENABLED}" ]; then
    echo "Enabling Nusphere PHPed"
    cp "${PHP_DBG_PATH}/dbg-php-7.2.so" "${PHP_LIB_PATH}/"

    {
    echo "zend_extension=\"${PHP_LIB_PATH}/dbg-php-7.2.so\""
    echo "[debugger]"
    echo "debugger.hosts_allow=\"${PHP_DBG_ALLOWED_HOSTS}\""
    echo "debugger.hosts_deny=ALL"
    echo "debugger.ports=7869"
    }  >> "${PHP_CONF_D}/debugger.ini"
    cat "${PHP_CONF_D}/debugger.ini"

else
    echo "Disabling Nusphere PHPed"
    rm "${PHP_LIB_PATH}/dbg-php-7.2.so"
    rm "${PHP_CONF_D}/debugger.ini"
fi

source /usr/local/bin/docker-php-entrypoint-orig