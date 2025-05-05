FROM jenkins/jenkins:lts

USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    python3-venv \
    awscli \
    docker.io \
    ansible \
    curl \
    git \
    unzip \
    sudo

# Add Jenkins user to docker group
RUN usermod -aG docker jenkins

RUN sudo curl -fsSL https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip -o terraform.zip && \
    sudo unzip terraform.zip && \
    sudo mv terraform /usr/local/bin/ && \
    sudo rm terraform.zip

USER jenkins

