FROM centos:centos7
MAINTAINER Xianfeng Yuan <xianfeng.yuan@menlosecurity.com>

# install dev tools
RUN yum install -y \
    tar \
    wget && \
    yum clean all && rm -rf /var/cache/yum/*

# this envs are for maintaining java updates.
ENV JAVA_MAJOR_VERSION=8
ENV JAVA_UPDATE_VERSION=60
ENV JAVA_BUILD_NUMER=27
# install java
ENV JAVA_VERSION=1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
ENV JAVA_TARBALL=jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz
ENV JAVA_HOME=/opt/java/jre${JAVA_VERSION}
RUN wget --no-check-certificate --directory-prefix=/tmp \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMER}/${JAVA_TARBALL} && \
    mkdir -p /opt/java && \
    tar -xzf /tmp/${JAVA_TARBALL} -C /opt/java/ && \
    alternatives --install /usr/bin/java java /opt/java/jre${JAVA_VERSION}/bin/java 100 && \
    rm -rf /tmp/* && rm -rf /var/log/*
