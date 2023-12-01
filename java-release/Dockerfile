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
