#!/bin/bash

_RSYNC=/usr/bin/rsync

for app in 'fmx' 'fmxmodmgt' 'fmxmonitor' 'fmxtrace' 'fmxparam' 'fmxstats' 'fmxeditor' 'fmxeventsim' 'fmxtimeperiod' 'fmxedd' 'fmxdatalib' 'fmxcommonlib' 'fmxlogin' 'fmxadminws'
do
    mkdir -m 775 -p /ericsson/httpd/data/apps/${app}/locales/en-us/
    $_RSYNC -avz --perms --chmod=D775,F664 --no-times --no-perms --no-group "/var/www/html/locales/en-us/${app}/app.json" "/ericsson/httpd/data/apps/${app}/locales/en-us"
done




