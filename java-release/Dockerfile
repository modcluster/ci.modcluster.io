#
# JBoss, Home of Professional Open Source.
# Copyright 2019, Red Hat, Inc., and individual contributors
# as indicated by the @author tags. See the copyright.txt file in the
# distribution for a full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
#

FROM centos:latest
LABEL Author="Radoslav Husar <radosoft@gmail.com>"

RUN yum update -y && \
    yum install -y git which java-1.7.0-openjdk-devel java-1.8.0-openjdk-devel && \
    yum clean all && \
    useradd -s /sbin/nologin jboss

USER jboss
WORKDIR /home/jboss
COPY --chown=jboss:jboss settings.xml .

ENV TAG=master
ENV JAVA_VERSION=1.8.0
ENV GITHUB_ORGANIZATION=modcluster
ENV GITHUB_REPOSITORY=mod_cluster

ENTRYPOINT export JAVA_HOME=/etc/alternatives/java_sdk_${JAVA_VERSION} && \
    export PATH=$JAVA_HOME/bin:$PATH && \
    java -version 2>&1 | grep -q ${JAVA_VERSION} && \
    git clone -b ${TAG} --single-branch --depth 1 https://github.com/${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY} ${GITHUB_REPOSITORY} && \
    cd ${GITHUB_REPOSITORY} && \
    echo "scm.tag=${TAG}" >> release.properties && \
    echo "scm.url=scm:git:https://github.com/${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}.git" >> release.properties && \
    ./mvnw -s ../settings.xml release:perform --batch-mode
