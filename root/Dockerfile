# syntax=docker/dockerfile:1.4
ARG DEBIAN_RELEASE=bullseye

########################################
## ruby: The upstream ruby base image
########################################
FROM ruby:3.2-slim-bullseye@sha256:428867de4fe3a3d95eccb6bb09171cf28f55aca2b264dba433c1321a12100400 as ruby

########################################
## base: Our base with Ruby, Node, etc.
########################################
FROM ruby AS base
LABEL maintainer="Brad Feehan <git@bradfeehan.com>"

ARG BUNDLE_JOBS
ARG DEBIAN_RELEASE
ARG NODESOURCE_KEYRING='/usr/share/keyrings/nodesource.gpg'
ARG POSTGRESQL_KEYRING='/usr/share/keyrings/postgresql.gpg'
ARG YARN_KEYRING='/usr/share/keyrings/yarn.gpg'

ENV \
  BUNDLE_JOBS="${BUNDLE_JOBS:-32}" \
  BUNDLE_SILENCE_ROOT_WARNING='' \
  NODE_VERSION='20' \
  RAILS_LOG_TO_STDOUT=true

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

WORKDIR /app

# Configure APT to maintain its cache in a mount outside the container
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
  && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/keep-cache

COPY ./vendor/keys /usr/share/keys

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
  apt-get update --quiet \
  && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --quiet --no-install-recommends \
    build-essential='12.*' \
    ca-certificates='202*' \
    curl='7.*' \
    dirmngr='2.*' \
    git='1:2.*' \
    gnupg='2.*' \
    tzdata='202*' \
  && gpg --dearmor --output "${POSTGRESQL_KEYRING}" < /usr/share/keys/postgresql.gpg.asc \
  && gpg --no-default-keyring --keyring "${POSTGRESQL_KEYRING}" --list-keys \
  && printf '%s\n' \
    "deb [signed-by=${POSTGRESQL_KEYRING}] http://apt.postgresql.org/pub/repos/apt ${DEBIAN_RELEASE}-pgdg main" \
    > /etc/apt/sources.list.d/postgresql.list \
  && gpg --dearmor --output "${NODESOURCE_KEYRING}" < /usr/share/keys/nodesource.gpg.asc \
  && gpg --no-default-keyring --keyring "${NODESOURCE_KEYRING}" --list-keys \
  && printf '%s\n' \
    "deb [signed-by=${NODESOURCE_KEYRING}] https://deb.nodesource.com/node_${NODE_VERSION%%.*}.x ${DEBIAN_RELEASE} main" \
    "deb-src [signed-by=${NODESOURCE_KEYRING}] https://deb.nodesource.com/node_${NODE_VERSION%%.*}.x ${DEBIAN_RELEASE} main" \
    > /etc/apt/sources.list.d/nodesource.list \
  && gpg --dearmor --output "${YARN_KEYRING}" < /usr/share/keys/yarn.gpg.asc \
  && gpg --no-default-keyring --keyring "${YARN_KEYRING}" --list-keys \
  && printf '%s\n' \
    "deb [signed-by=${YARN_KEYRING}] http://dl.yarnpkg.com/debian/ stable main" \
    > /etc/apt/sources.list.d/yarn.list

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
  apt-get update --quiet \
  && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --quiet --no-install-recommends \
    libpq-dev='15.*' \
    nodejs="${NODE_VERSION}*" \
    postgresql-client-15='15.*' \
    yarn='1.*' \
  && gem update --system

RUN mkdir -p '/app/vendor/cache' \
  && groupadd --gid 1000 ruby \
  && useradd --uid 1000 --gid ruby --shell /bin/bash --create-home ruby \
  && chown -R ruby:ruby '/app' "${GEM_HOME}" \
  && chmod u+rwX,go+rX-w '/app' "${GEM_HOME}"

USER ruby


########################################
## rubygems: Install Ruby dependencies
########################################
FROM base as rubygems
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY --chown=ruby:ruby .ruby-version ./
COPY --chown=ruby:ruby Gemfile* ./
COPY --chown=ruby:ruby vendor/cache/*.gem ./vendor/cache/

RUN bundle install --local --verbose \
  && find '/usr/local/bundle/cache' -name '*.gem' -delete


########################################
## app: Contains only app code at /app
########################################
FROM ruby AS app
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

WORKDIR /app

COPY . ./
RUN rm -rf \
    /app/log \
    /app/spec \
    /app/test \
    /app/tmp \
    /app/.rspec \
    /app/.rubocop.yml \
    /app/.stylelint* \
  && find /app -name '*.gem' -delete


########################################
## production: Final complete image
########################################
FROM base AS production
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY --from=rubygems "${GEM_HOME}" "${GEM_HOME}"
COPY --from=app --chown=ruby:ruby /app /app

RUN env \
  SECRET_KEY_BASE="$(bin/rake secret)" \
  RAILS_ENV=production \
  bin/rails assets:precompile

EXPOSE 3000/tcp

CMD ["bash"]


########################################
## development: VS Code dev container
########################################
FROM production AS development
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

USER root

# Create docker-socat script -- adapted from:
# https://github.com/microsoft/vscode-dev-containers/tree/52784a9f19b9f3de2a30a802c2881d95adfdc127/containers/docker-from-docker-compose
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
  echo 'deb [signed-by=/usr/share/keys/packages.cloud.google.com-apt-key.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' \
    > '/etc/apt/sources.list.d/kubernetes.list' \
  && apt-get update --quiet \
  && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --quiet --no-install-recommends \
    kubectl='1.24.*' \
    socat='1.*' \
    sudo='1.*' \
  && printf '%s\n' > /etc/sudoers.d/docker-socat \
    '%docker ALL=(root) NOPASSWD: /usr/local/bin/docker-socat.sh' \
  && chmod 440 /etc/sudoers.d/docker-socat \
  && printf '%s\n' > /usr/local/bin/docker-entrypoint.sh \
    '#!/bin/sh -x' \
    'if id -Gn | grep -qw "docker"; then' \
    '  sudo /usr/local/bin/docker-socat.sh &' \
    'fi' \
    'exec "$@"' \
  && chmod 555 /usr/local/bin/docker-entrypoint.sh \
  && printf '%s\n' > /usr/local/bin/docker-socat.sh \
    '#!/bin/sh' \
    "if [ \"\$(id -u)\" -ne 0 ]; then" \
    '  echo >&2 "Error: must be root"' \
    '  exit 1' \
    'fi' \
    'rm -rf /var/run/docker.sock' \
    "socat \\" \
    "  UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=ruby \\" \
    '  UNIX-CONNECT:/var/run/docker-host.sock' \
  && chmod 544 /usr/local/bin/docker-socat.sh \
  && chown root \
    /etc/sudoers.d/docker-socat \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/docker-socat.sh

USER ruby

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sleep", "infinity"]


########################################
## default: Use production image
########################################
FROM production AS default
