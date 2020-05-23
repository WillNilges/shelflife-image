FROM alpine:latest

MAINTAINER Jeffery Bagirimvano <jeffery.rukundo@gmail.com>
MAINTAINER Will Nilges <will.nilges@gmail.com>

ENV SUMMARY="ShelfLife on Alpine Image." \
    DESCRIPTION="Alpine Linux is a security-oriented, lightweight Linux distribution based on musl libc and busybox."

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="https://github.com/jefferyb/openshift-base-images/alpine" \
      maintainer="jeffery.rukundo@gmail.com" \
      summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
### Required labels above - recommended below
      url="https://github.com/jefferyb/openshift-base-images/alpine" \
      help="For more information visit https://github.com/jefferyb/openshift-base-images/alpine" \
      run='docker run -itd --name ubuntu -u 123456 jefferyb/openshift-alpine' \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="${SUMMARY}" \
      io.openshift.expose-services="" \
      io.openshift.tags="alpine,starter-arbitrary-uid,starter,arbitrary,uid"

### Setup user for build execution and application runtime
ENV APP_ROOT=/opt/app-root
ENV PATH=/usr/local/bin:${APP_ROOT}/.local/bin:${PATH} HOME=${APP_ROOT}
COPY bin/ /usr/local/bin/
RUN mkdir -p ${APP_ROOT} && \
    chmod -R u+x /usr/local/bin && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT} /etc/passwd

### Containers should NOT run as root as a good practice
USER 10001
WORKDIR ${APP_ROOT}

### user name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
ENTRYPOINT [ "uid_entrypoint" ]
# VOLUME ${APP_ROOT}/logs ${APP_ROOT}/data
CMD run

FROM rust:1.40 as builder
WORKDIR /usr/src/shelflife
RUN apt-get update -y && apt-get install git
RUN git clone https://github.com/willnilges/shelflife ./shelflife-src
WORKDIR ./shelflife-src
# Unnecessary because we're working directly inside the git repo.
#COPY src ./src
#COPY Cargo.toml .
#COPY Cargo.lock .
RUN cargo install --path .
FROM debian:buster-slim
RUN apt-get update -y && apt-get install libssl-dev -y
WORKDIR /usr/local/bin
COPY --from=builder /usr/local/cargo/bin/shelflife .
#COPY .env . # FOOL! You assume there's a .env file?
#RUN apt-get update -y && apt-get install curl -y
#RUN curl https://raw.githubusercontent.com/WillNilges/ShelfLife/master/.env.sample -o .env

#ENTRYPOINT ["./shelflife"]

# ref: https://github.com/RHsyseng/container-rhel-examples/blob/master/starter-arbitrary-uid/Dockerfile.centos7

