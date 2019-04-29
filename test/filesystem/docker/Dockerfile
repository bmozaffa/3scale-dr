FROM docker.io/centos:7
MAINTAINER Red Hat Systems Engineering <refarch-feedback@redhat.com>

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="oc-centos7" \
      maintainer="refarch-feedback@redhat.com" \
      vendor="Acme Corp" \
      version="0.1" \
      release="1" \
      summary="Container with OpenShift client" \
      description="Basic Cent OS image with OpenShift Client installed and scripts to perform remote rsync from the pod"

### Setup user for build execution and application runtime
ENV APP_ROOT=/opt/app-root \
    USER_NAME=default \
    USER_UID=10001
ENV APP_HOME=${APP_ROOT}/src  PATH=$PATH:${APP_ROOT}/bin
RUN mkdir -p ${APP_HOME}
COPY bin/ ${APP_ROOT}/bin/
RUN chmod -R ug+x ${APP_ROOT}/bin && sync && \
    useradd -l -u ${USER_UID} -r -g 0 -d ${APP_ROOT} -s /sbin/nologin -c "${USER_NAME} user" ${USER_NAME} && \
    chown -R ${USER_UID}:0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

####### Add app-specific needs below. #######
### Containers should NOT run as root as a good practice
### Versions for application binaries

ENV OC_VERSION v3.11.0
ENV OC_HASH 0cbc58b
ENV KUBECONFIG=${APP_ROOT}/.kube/config

RUN curl -Ls https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_HASH}-linux-64bit.tar.gz -o ${APP_ROOT}/bin/oc-client.tar.gz
RUN tar -xzf ${APP_ROOT}/bin/oc-client.tar.gz -C ${APP_ROOT}/bin --strip-components=1
RUN rm ${APP_ROOT}/bin/oc-client.tar.gz

USER 10001
WORKDIR ${APP_ROOT}