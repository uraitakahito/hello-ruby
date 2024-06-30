# Debian 12.5
FROM debian:bookworm-20240612

ARG user_id=501
ARG group_id=20
ARG user_name=developer
# The WORKDIR instruction can resolve environment variables previously set using ENV.
# You can only use environment variables explicitly set in the Dockerfile.
# https://docs.docker.com/engine/reference/builder/#/workdir
ARG home=/home/${user_name}
ARG ruby_version=3.1.4

RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    ca-certificates \
    git

#
# Add user.
#
#   Someone uses devcontainer, but the others don't.
#   That is why dockerfile calls `features` MANUALLY here without devcontainer.json.
#
RUN cd /usr/src && \
  git clone --depth 1 https://github.com/devcontainers/features.git && \
  USERNAME=${user_name} \
  UID=${user_id} \
  GID=${group_id} \
  CONFIGUREZSHASDEFAULTSHELL=true \
    /usr/src/features/src/common-utils/install.sh

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

COPY bin/docker-entrypoint.sh /usr/local/bin/

#
# Ruby
#
RUN apt-get update -qq && \
  apt-get upgrade -y -qq && \
  # apt-get install -y -qq --no-install-recommends \
  apt-get install -y -qq \
    # rbenv
    rbenv \
    # Ruby 3.1
    # require psych.h(libyaml-dev) to install debug gem
    libyaml-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY zshrc-entrypoint-init.d /etc/zshrc-entrypoint-init.d

USER ${user_name}
WORKDIR /home/${user_name}

RUN git clone --depth=1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build && \
  rbenv install ${ruby_version} && \
  rbenv global ${ruby_version}

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["tail", "-F", "/dev/null"]
