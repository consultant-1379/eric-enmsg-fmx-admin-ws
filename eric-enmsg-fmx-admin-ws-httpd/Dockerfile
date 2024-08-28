ARG ERIC_ENM_SLES_APACHE2_IMAGE_NAME=eric-enm-sles-apache2
ARG ERIC_ENM_SLES_APACHE2_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_APACHE2_IMAGE_TAG=1.59.0-33

FROM ${ERIC_ENM_SLES_APACHE2_IMAGE_REPO}/${ERIC_ENM_SLES_APACHE2_IMAGE_NAME}:${ERIC_ENM_SLES_APACHE2_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified

LABEL \
com.ericsson.product-number="CXC Placeholder" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM FMService UI SideCar" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"


RUN zypper install -y ERICfmxgui_CXP9032509  \
   ERICnetworkviewerapp_CXP9034876 && \
   zypper clean -a


COPY addAppsToLauncher.sh /var/tmp/
RUN chmod 775 /var/tmp/addAppsToLauncher.sh
RUN sed -i "9 a bash /var/tmp/addAppsToLauncher.sh" entry-point.sh

ENV CREDM_CONTROLLER_MNG="TRUE"
ENV PROXY_PASS_RULES="fmxadminws"

EXPOSE 8080 8444 443 9090 80 2042 500
