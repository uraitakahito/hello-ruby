# Debian 12.6
FROM debian:bookworm-20240812

ARG user_name=developer
ARG user_id
ARG group_id
ARG ruby_version=3.3.4
ARG dotfiles_repository="https://github.com/uraitakahito/dotfiles.git"
ARG features_repository="https://github.com/uraitakahito/features.git"

# Avoid warnings by switching to noninteractive for the build process
ENV DEBIAN_FRONTEND=noninteractive

#
# Install packages
#
RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  apt-get install -y -qq --no-install-recommends \
    # Basic
    ca-certificates \
    git \
    iputils-ping \
    # Editor
    vim \
    # Utility
    tmux \
    # fzf needs PAGER(less or something)
    fzf \
    trash-cli && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

#
# eza
# https://github.com/eza-community/eza/blob/main/INSTALL.md
#
RUN apt-get update -qq && \
  apt-get install -y -qq --no-install-recommends \
    gpg \
    wget && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir -p /etc/apt/keyrings && \
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
  chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
  apt update && \
  apt install -y eza && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/

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

#
# Add user and install basic tools.
#
RUN cd /usr/src && \
  git clone --depth 1 ${features_repository} && \
  USERNAME=${user_name} \
  USERUID=${user_id} \
  USERGID=${group_id} \
  CONFIGUREZSHASDEFAULTSHELL=true \
    /usr/src/features/src/common-utils/install.sh
USER ${user_name}

#
# dotfiles
#
RUN cd /home/${user_name} && \
  git clone --depth 1 ${dotfiles_repository} && \
  dotfiles/install.sh

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
