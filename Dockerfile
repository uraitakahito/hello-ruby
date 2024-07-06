# Debian 12.5
FROM debian:bookworm-20240612

ARG user_name=developer
ARG user_id
ARG group_id
# The WORKDIR instruction can resolve environment variables previously set using ENV.
# You can only use environment variables explicitly set in the Dockerfile.
# https://docs.docker.com/engine/reference/builder/#/workdir
ARG home=/home/${user_name}
ARG ruby_version=3.1.4

RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    ca-certificates \
    git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

#
# Install packages
#
RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    # Basic
    iputils-ping \
    # Editor
    vim emacs \
    # Utility
    tmux \
    # fzf needs PAGER(less or something)
    fzf \
    exa \
    trash-cli && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/

#
# Ruby
#
RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  # apt-get install -y -qq --no-install-recommends \
  apt-get install -y -qq \
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
COPY zshrc-entrypoint-init.d /etc/zshrc-entrypoint-init.d

#
# Add user and install basic tools.
#
RUN cd /usr/src && \
  git clone --depth 1 https://github.com/uraitakahito/features.git && \
  USERNAME=${user_name} \
  USERUID=${user_id} \
  USERGID=${group_id} \
  CONFIGUREZSHASDEFAULTSHELL=true \
    /usr/src/features/src/common-utils/install.sh
USER ${user_name}

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN git clone --depth=1 https://github.com/rbenv/ruby-build.git "$($HOME/.rbenv/bin/rbenv root)"/plugins/ruby-build && \
  $HOME/.rbenv/bin/rbenv install ${ruby_version} && \
  $HOME/.rbenv/bin/rbenv global ${ruby_version}

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["tail", "-F", "/dev/null"]
