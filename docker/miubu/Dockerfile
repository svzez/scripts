FROM ubuntu:bionic

# Avoid warnings
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG git_user_name
ARG git_user_email

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    # Verify git, process tools, lsb-release (common in install instructions for CLIs) installed
    && apt-get -y install git iproute2 procps lsb-release \
    vim net-tools python3.7 python3-pip sudo wget curl \
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Don't be root.
USER ${USERNAME}
ENV HOME /home/${USERNAME}
WORKDIR /home/${USERNAME}

RUN pip3 install --no-cache-dir requests

RUN git config --global user.name "${git_user_name}" \
    && git config --global user.email "${git_user_email}"

# Default editor
ENV EDITOR vim

# Configure bash prompt.
RUN echo "\n# Colored and git aware prompt." >> /home/${USERNAME}/.bashrc \
 && echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $ '" >> /home/${USERNAME}/.bashrc

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

CMD tail -f /dev/null
