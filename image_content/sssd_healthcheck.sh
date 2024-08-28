#!/bin/bash

###########################################################################
# COPYRIGHT Ericsson 2022

# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

# GLOBAL VARIABLES
_SSSD_PROCESS="sssd"

#//////////////////////////////////////////////////////////////
# Main Part of Script
#/////////////////////////////////////////////////////////////

pgrep -x "$_SSSD_PROCESS" > /dev/null
ret=$?

if [[ "$ret" -eq 0 ]]; then
  exit 0
else
  logger -p local0.err "Healthcheck error: sssd process not running"
  exit 1
fi
