FROM jenkins/jenkins:lts

USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    awscli \
    unzip \
    docker.io \
    ansible \
    curl \
    git \
    sudo

# Add Jenkins user to docker group
RUN groupmod -g 984 docker && usermod -aG docker jenkins

# Copy plugin list and install them
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

USER jenkins

