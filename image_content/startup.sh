#!/bin/bash

## removes any backup of standalone xml
rm -rf /ericsson/3pp/jboss/standalone/configuration/standalone_xml_history
mkdir -p /ericsson/3pp/jboss/standalone/configuration/standalone_xml_history

## initializes jboss
JBOSS_ENV_FILE="/ericsson/3pp/jboss/jboss.env"
echo "Initializing jboss ..."
/ericsson/3pp/jboss/bin/jboss initialize &

while [ ! -f "$JBOSS_ENV_FILE" ]
do
        echo "Waiting for jboss environment file $JBOSS_ENV_FILE"
        sleep 1
done

#Sleeping here to give time for the file to be fully prepared.
sleep 5

source /ericsson/3pp/jboss/jboss.env
echo "$JBOSS_ENV_FILE available, going to start the jboss process"

## removes all the logs
echo "JBOSS LOG DIR $JBOSS_LOG_DIR"
echo "" > ${JBOSS_LOG_DIR}/server.log


if [ -d /var/run/jboss ]; then
	rm -rf /var/run/jboss
fi

## starts jboss
mkdir -p /var/run/jboss

exec /usr/bin/java -D[Standalone] $JAVA_OPTS \
-Dorg.jboss.boot.log.file="$JBOSS_LOG_DIR"/server.log \
-Dlogging.configuration=file:"$JBOSS_CONFIG_DIR"/logging.properties \
-jar "$JBOSS_HOME"/jboss-modules.jar \
-mp ${JBOSS_MODULEPATH} -jaxpmodule "javax.xml.jaxp-provider" org.jboss.as.standalone \
-Djboss.home.dir="$JBOSS_HOME" -Djboss.server.base.dir="$JBOSS_BASE_DIR" -c "$JBOSSEAP7_CONFIG" &

JBOSS_PID=$(/usr/java/default/bin/jps | grep jboss* | awk '{print $1;}')
echo $JBOSS_PID > /var/run/jboss/jboss.pid
exit 0