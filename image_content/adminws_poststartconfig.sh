#!/bin/bash
/sbin/rsyslogd -i /tmp/rsyslogd.pid
/opt/ericsson/fmx/tools/bin/nmx.sh
/ericsson/3pp/jboss/bin/pre-start/fmx_preconfig.sh
