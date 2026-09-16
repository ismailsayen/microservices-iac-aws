FROM alpine:latest

# Install dependencies, AWS CLI, session manager, kubectl, and core utilities
RUN apk add --no-cache \
    curl \
    unzip \
    bash \
    aws-cli \
    aws-session-manager-plugin \
    kubectl \
    openssh-client \
    git \
    wget \
    make \
    jq \
    hey \
    nano
    

# Install Terraform CLI dynamically
RUN TER_VER=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | grep -oE '"current_version":"[^"]+"' | cut -d'"' -f4) && \
    curl -LO "https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip" && \
    unzip "terraform_${TER_VER}_linux_amd64.zip" && \
    mv terraform /usr/local/bin/ && \
    rm "terraform_${TER_VER}_linux_amd64.zip"

RUN export AWS_PROFILE="ismail.sayen"

WORKDIR /workspace

CMD ["/bin/bash"]