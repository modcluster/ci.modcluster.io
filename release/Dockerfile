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

FROM centos:7
LABEL Author="Radoslav Husar <rhusar@redhat.com>"

ARG TAG=master
ARG JAVA_VERSION=1.8.0
ARG GITHUB_ORGANIZATION=modcluster
ARG JBOSS_USERNAME
ARG JBOSS_PASSWORD

RUN yum install -y git which java-${JAVA_VERSION}-openjdk-devel

RUN useradd -s /sbin/nologin modcluster
USER modcluster
WORKDIR /home/modcluster

COPY --chown=modcluster:modcluster settings.xml .

RUN git clone -b ${TAG} --single-branch --depth 1 https://github.com/${GITHUB_ORGANIZATION}/mod_cluster mod_cluster && \
    cd mod_cluster && \
    echo "scm.tag=${TAG}" >> release.properties && \
    echo "scm.url=scm:git:https://github.com/${GITHUB_ORGANIZATION}/mod_cluster.git" >> release.properties && \
    ./mvnw -s ../settings.xml release:perform --batch-mode
