FROM jenkins/jenkins:lts-jdk11
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG /var/jenkins_conf
USER root
RUN apt-get update && apt-get install -y lsb-release && rm -rf /var/lib/apt/lists/*
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*
USER jenkins
COPY files/plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins-data /var/jenkins_home
# job DSL
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
