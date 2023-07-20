#!/bin/bash
set -xeuo pipefail
IFS=$'\n\t'

ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." &> /dev/null && pwd -P 2> /dev/null)"

ACTIONLINT_VERSION='1.6.25'
ACTIONLINT_FILENAME="actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz"
ACTIONLINT_URL="https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/${ACTIONLINT_FILENAME}"

if [[ $# > 0 && "$1" == '--base' ]]; then
  docker build --platform linux/amd64 -t 'bradfeehan/rails-template:local' - <<EOF
FROM ruby:latest

RUN mkdir -p /usr/share/keys && cat > /usr/share/keys/nodesource.gpg.asc <<KEYEOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1
Comment: GPGTools - https://gpgtools.org

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
=CLGF
-----END PGP PUBLIC KEY BLOCK-----
KEYEOF

RUN cat > /usr/share/keys/yarn.gpg.asc <<KEYEOF
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=e4wy
-----END PGP PUBLIC KEY BLOCK-----
KEYEOF


ENV BUNDLE_JOBS=32
ENV NODE_VERSION='20'
ENV DEBIAN_RELEASE=bullseye
ENV NODESOURCE_KEYRING='/usr/share/keyrings/nodesource.gpg'
ENV POSTGRESQL_KEYRING='/usr/share/keyrings/postgresql.gpg'
ENV YARN_KEYRING='/usr/share/keyrings/yarn.gpg'

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
  && gpg --dearmor --output "\${NODESOURCE_KEYRING}" < /usr/share/keys/nodesource.gpg.asc \
  && gpg --no-default-keyring --keyring "\${NODESOURCE_KEYRING}" --list-keys \
  && printf '%s\n' \
    "deb [signed-by=\${NODESOURCE_KEYRING}] https://deb.nodesource.com/node_\${NODE_VERSION%%.*}.x \${DEBIAN_RELEASE} main" \
    "deb-src [signed-by=\${NODESOURCE_KEYRING}] https://deb.nodesource.com/node_\${NODE_VERSION%%.*}.x \${DEBIAN_RELEASE} main" \
    > /etc/apt/sources.list.d/nodesource.list \
  && gpg --dearmor --output "\${YARN_KEYRING}" < /usr/share/keys/yarn.gpg.asc \
  && gpg --no-default-keyring --keyring "\${YARN_KEYRING}" --list-keys \
  && printf '%s\n' \
    "deb [signed-by=\${YARN_KEYRING}] http://dl.yarnpkg.com/debian/ stable main" \
    > /etc/apt/sources.list.d/yarn.list

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
  apt-get update --quiet \
  && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --quiet --no-install-recommends \
    nodejs="\${NODE_VERSION}*" \
    yarn='1.*' \
    shellcheck \
    yamllint \
  && gem update --system

RUN gem install rails && \
    gem install bundler:2.4.14
RUN yarn global add v8r && \
    curl -LSsO "${ACTIONLINT_URL}" && \
      tar -xzf "${ACTIONLINT_FILENAME}" && \
      mv actionlint /usr/local/bin/ && \
      chmod +x /usr/local/bin/actionlint && \
      rm -f "${ACTIONLINT_FILENAME}" && \
    curl -LSsO "https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64" && \
      mv hadolint-Linux-x86_64 /usr/local/bin/hadolint && \
      chmod +x /usr/local/bin/hadolint

WORKDIR /app
CMD ["/bin/bash"]
EOF
fi

root="${HOME}/Code/bradfeehan/new"
rm -rf "${root}"
sleep 0.3
mkdir "${root}"
sleep 0.3
cd "${root}"
printf '%s\n' '' rails-template-test ''
docker run --rm \
  -v "${root}:/app" \
  -v "${HOME}/Code/bradfeehan/rails-template:/template:ro" \
  --workdir '/app' \
  --platform linux/amd64 \
  -e DATABASE_URL='postgresql://postgres:postgres@192.168.248.244:5432' \
  --publish 3000:3000 \
  --name rails-template-test \
  -it bradfeehan/rails-template:local \
    bash -xc " \
      git config --global user.email 'git@bradfeehan.com' && \
      git config --global user.name 'Brad Feehan' && \
      export 'BUNDLE_JOBS=32' && \
      export 'DATABASE_URL=postgresql://postgres:postgres@192.168.248.244:5432' && \
      rails new --template '/template/template.rb' --database postgresql --css postcss --javascript esbuild --asset-pipeline propshaft --skip-test --skip-system-test . && \
      bin/dev"
