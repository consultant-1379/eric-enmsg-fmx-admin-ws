ARG ERIC_ENM_SLES_EAP7_IMAGE_NAME=eric-enm-sles-eap7
ARG ERIC_ENM_SLES_EAP7_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_EAP7_IMAGE_TAG=1.64.0-32

FROM ${ERIC_ENM_SLES_EAP7_IMAGE_REPO}/${ERIC_ENM_SLES_EAP7_IMAGE_NAME}:${ERIC_ENM_SLES_EAP7_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified

LABEL \
com.ericsson.product-number="CXC Placeholder" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM Adminws Service Group" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

RUN /usr/sbin/groupadd -g 5004 "fmexportusers" > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "fmexportusers" jboss_user > /dev/null 2>&1 && \
    /usr/sbin/groupadd -g 5000 "mm-smrsusers" > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "mm-smrsusers" jboss_user > /dev/null 2>&1  && \
    /usr/sbin/groupadd -g 210 "nmx" > /dev/null 2>&1 && \
    /usr/sbin/useradd -m -g nmx -u 210 nmxadm > /dev/null 2>&1

COPY image_content/repos/*.repo /etc/zypp/repos.d/

RUN zypper clean --all && zypper ref

RUN zypper install -y systemd-sysvinit \
    mozilla-nss-sysinit \
    mozilla-nss-tools && \
    (cd /usr/lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /usr/lib/systemd/system/local-fs.target.wants/*; \
    rm -f /usr/lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /usr/lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /usr/lib/systemd/system/basic.target.wants/*;\
    rm -f /usr/lib/systemd/system/anaconda.target.wants/* && \
    rm -f /ericsson/3pp/jboss/bin/cli/common/configure_modcluster.cli && \
    zypper install -y \
    ERICpamopenam_CXP9039073 \
    sssd-ldap \
    sssd-dbus \
    ERICserviceframework4_CXP9037454 \
    ERICserviceframeworkmodule4_CXP9037453 \
    ERICmodelserviceapi_CXP9030594 \
    ERICmodelservice_CXP9030595 \
    ERICvaultloginmodule_CXP9036201 \
    ERICfmxadminws_CXP9032450 \
    ERICfmxgui_CXP9032509 \
    ERICfmxenmutilbasic_CXP9031802 \
    ERICfmxutilbasic_CXP9031797 && \
    zypper download    ERICfmxtools_CXP9031793 \
                       ERICfmxenmcfg_CXP9032402 \
                       ERIClitpvmmonitord_CXP9031644 \
                       ERICfmxeditor_CXP9031795 \
                       ERICenmsgfmx_CXP9031866 && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/*.rpm --nodeps --noscripts && \
    zypper clean -a

ARG _INSTALL_PATH_=/ericsson/3pp/jboss
RUN rm -rf /etc/systemd/system/jboss.service; rm -rf /usr/lib/systemd/system/jboss.service
COPY --chown=root:root image_content/jboss.service /usr/lib/systemd/system
COPY --chown=root:jboss image_content/startup.sh $_INSTALL_PATH_
RUN chmod -R 770 $_INSTALL_PATH_/standalone/tmp/deployments && \
    chmod 550 $_INSTALL_PATH_/startup.sh && \
    systemctl enable jboss && \
    systemctl enable rsyslog

ENV JBOSS_CONF="/ericsson/3pp/jboss/jboss-as.conf" \
    GLOBAL_CONFIG="/ericsson/tor/data/global.properties"

COPY --chown=root:root image_content/sssd_override.conf /etc/systemd/system/sssd.service.d/override.conf
COPY --chown=root:root image_content/journald/00-journal-size.conf /etc/systemd/journald.conf.d/
RUN mkdir -p /var/log/journal

RUN sed -i 's/localhost:7001,localhost:7002,localhost:7003/eric-data-key-value-database-rd-operand:6379/g' $(find /etc/opt/ericsson/fmx/adminws/redis-config.properties )

COPY image_content/rabbitmq-env.conf /etc/rabbitmq/
COPY image_content/sssd_healthcheck.sh /usr/lib/ocf/resource.d/
COPY image_content/fmx_preconfig.sh /ericsson/3pp/jboss/bin/pre-start/
COPY image_content/adminws_poststartconfig.sh /ericsson/3pp/jboss/bin/post-start/

RUN rm -f /ericsson/3pp/jboss/bin/post-start/update_management_credential_permissions.sh /ericsson/3pp/jboss/bin/post-start/update_standalone_permissions.sh

RUN sed -i 's/port="514"/port="5140"/g' /etc/opt/ericsson/fmx/adminws/log4j2.xml && \
    sed -i 's/port="514"/port="5140"/g' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i 's/<File name="MyFile" fileName="${logFolder}\/editor.log" append="false"/<RollingRandomAccessFile name="allLogRollingFileAppender" fileName="${logFolder}\/editor.log" filePattern="${logFolder}\/editor-%d{yyyy-MM-dd}T%d{HH-mm}_%i.log.gz" immediateFlush="false"/g' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i 's/<\/File/<\/RollingRandomAccessFile/g' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '13 i \\t\t\t<Policies>\n\t\t\t\t<CronTriggeringPolicy schedule="0 0 0 * * ?"/>\n\t\t\t\t<SizeBasedTriggeringPolicy size="20 MB" />' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '16 i \\t\t\t</Policies>' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '17 i \\t\t\t<DefaultRolloverStrategy>\n\t\t\t\t\<Delete basePath="${logFolder}" maxDepth="1">\n\t\t\t\t\t\<IfFileName glob="editor-*.gz">\n\t\t\t\t\t\t\<IfAccumulatedFileSize exceeds="100 MB" />' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '21 i \\t\t\t\t\t</IfFileName>' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '22 i \\t\t\t\t</Delete>' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '23 i \\t\t\t</DefaultRolloverStrategy>' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '43 i \\t\t<Logger name="com.ericsson" level="info" additivity="true">\n\t\t\t<AppenderRef ref="allLogRollingFileAppender"/>' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '45 i \\t\t</Logger>' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i '49d' /etc/opt/ericsson/fmx/editor/log4j2.xml && \
    sed -i 's/ref="sysLogAppender" level="warn"/ref="sysLogAppender" level="info"/g' /etc/opt/ericsson/fmx/editor/log4j2.xml

RUN sed -i 's/SAVED="`pwd`"/SAVED="\/"/g' /opt/ericsson/fmx/editor/bin/editor.sh

RUN sed -i 's/Defaults env_keep = "LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_ATIME LC_ALL LANGUAGE LINGUAS XDG_SESSION_COOKIE"/Defaults env_keep = "LANG LC_ADDRESS LC_CTYPE LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_ATIME LC_ALL LANGUAGE LINGUAS XDG_SESSION_COOKIE COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS"/g' /etc/sudoers && \
    sed -i 's/Defaults env_reset/Defaults !env_reset/g' /etc/sudoers

RUN chmod -R 775 /etc/rabbitmq

ENV ENM_JBOSS_SDK_CLUSTER_ID="fmxadminws" \
    ENM_JBOSS_BIND_ADDRESS="0.0.0.0" \
    CLOUD_DEPLOYMENT="true" \
    GLOBAL_CONFIG="/gp/global.properties"

EXPOSE 3528 4447 8009 8080 9990 9999 12987 54200 56127 56142 56145 56185 56193 56199 56203 56214 56216 56219 56227 56235

CMD ["/sbin/init"]
ENTRYPOINT []
