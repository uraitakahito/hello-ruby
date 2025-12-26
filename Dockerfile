# ## Features of this Dockerfile
#
# - Not based on devcontainer; use by attaching VSCode to the container
# - Assumes host OS is Mac
#
# ## Preparation
#
# ### SSH Agent
#
# Uses ssh-agent. After a restart, if you have not yet initiated an SSH login from your Mac, run the following command on the Mac.
#
#   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
#
# For more details about ssh-agent, see:
#
#   https://github.com/uraitakahito/hello-docker/blob/c942ab43712dde4e69c66654eac52d559b41cc49/README.md
#
# ### Download the files required to build the Docker container
#
#   curl -L -O https://raw.githubusercontent.com/uraitakahito/hello-ruby/refs/heads/main/Dockerfile
#   curl -L -O https://raw.githubusercontent.com/uraitakahito/hello-ruby/refs/heads/main/docker-entrypoint.sh
#   chmod 755 docker-entrypoint.sh
#
# Build the Docker image:
#
# ```console
# % PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
# ```
#
# Create a volume to persist the command history executed inside the Docker container.
# It is stored in the volume because the dotfiles configuration redirects the shell history there.
#   https://github.com/uraitakahito/dotfiles/blob/b80664a2735b0442ead639a9d38cdbe040b81ab0/zsh/myzshrc#L298-L305
#
#   docker volume create $PROJECT-zsh-history
#
# Start the Docker container(/run/host-services/ssh-auth.sock is a virtual socket provided by Docker Desktop for Mac.):
#
# ```console
# % docker container run -d --rm --init --mount type=bind,src=/run/host-services/ssh-auth.sock,dst=/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume --name $PROJECT-container $PROJECT-image
# ```
#
# Use [fdshell](https://github.com/uraitakahito/dotfiles/blob/37c4142038c658c468ade085cbc8883ba0ce1cc3/zsh/myzshrc#L93-L101) to log in to Docker.
#
# ```console
# % fdshell /bin/zsh
# ```
#
# Only for the first startup, change the owner of the command history folder:
#
#   sudo chown -R $(id -u):$(id -g) /zsh-volume
#
# Run the following commands inside the Docker containers:
#
# ```console
# $ rbenv exec bundle install
# ```
#
# Select **[Dev Containers: Attach to Running Container](https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container)** through the **Command Palette (Shift + command + P)**
#
# Finally, open the `/app`.

# Debian 12.12
FROM debian:bookworm-20251208

ARG user_name=developer
ARG user_id
ARG group_id
ARG dotfiles_repository="https://github.com/uraitakahito/dotfiles.git"
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG extra_utils_repository="https://github.com/uraitakahito/extra-utils.git"
# Refer to the following URL for Ruby versions:
#   https://www.ruby-lang.org/ja/downloads/releases/
ARG ruby_version=3.4.8

# Avoid warnings by switching to noninteractive for the build process
ENV DEBIAN_FRONTEND=noninteractive

#
# Git
#
RUN apt-get update -qq && \
  apt-get install -y -qq --no-install-recommends \
    ca-certificates \
    git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

#
# clone features
#
RUN cd /usr/src && \
  git clone --depth 1 ${features_repository}

#
# Add user and install common utils.
#
RUN USERNAME=${user_name} \
    USERUID=${user_id} \
    USERGID=${group_id} \
    CONFIGUREZSHASDEFAULTSHELL=true \
    UPGRADEPACKAGES=false \
      /usr/src/features/src/common-utils/install.sh

#
# Install extra utils.
#
RUN cd /usr/src && \
  git clone --depth 1 ${extra_utils_repository} && \
  ADDEZA=true \
  ADDGRPCURL=true \
  UPGRADEPACKAGES=false \
    /usr/src/extra-utils/utils/install.sh

#
# Ruby
#
RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  apt-get install -y -qq --no-install-recommends \
    #
    # https://github.com/rbenv/ruby-build/wiki
    #
    autoconf \
    patch \
    build-essential \
    rustc \
    libssl-dev \
    # require psych.h(libyaml-dev) to install debug gem
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libgmp-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    libdb-dev \
    uuid-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/

USER ${user_name}

#
# dotfiles
#
RUN cd /home/${user_name} && \
  git clone --depth 1 ${dotfiles_repository} && \
  dotfiles/install.sh

#
# Claude Code
#
RUN curl -fsSL https://claude.ai/install.sh | bash

#
# rbenv
#
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
ENV PATH="/home/${user_name}/.rbenv/bin:${PATH}"
RUN git clone --depth=1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build && \
  rbenv install ${ruby_version} && \
  rbenv global ${ruby_version}

WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["tail", "-F", "/dev/null"]
