#!/bin/bash
set -xeuo pipefail
IFS=$'\n\t'

ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." &> /dev/null && pwd -P 2> /dev/null)"
if [[ $# > 0 && "$1" == '--base' ]]; then
  docker build --platform linux/amd64 -t 'bradfeehan/rails-template:local' - <<EOF
FROM ruby:latest
RUN gem install rails && \
    gem install bundler:2.4.14
WORKDIR /app
CMD ["/bin/bash"]
EOF
fi

root="${HOME}/Code/bradfeehan/new"
rm -rf "${root}"
mkdir "${root}"
cd "${root}"
docker run --rm \
  -v "${root}:/app" \
  -v "${HOME}/Code/bradfeehan/rails-template:/template:ro" \
  --workdir '/app' \
  --platform linux/amd64 \
  -e DATABASE_URL='postgresql://postgres:postgres@db:5432' \
  --publish 3000:3000 \
  -it bradfeehan/rails-template:local \
    bash -xc " \
      git config --global user.email 'git@bradfeehan.com' && \
      git config --global user.name 'Brad Feehan' && \
      export 'BUNDLE_JOBS=32' && \
      export 'DATABASE_URL=postgresql://postgres:postgres@198.19.192.3:5432' && \
      rails new --template '/template/template.rb' --database postgresql --css tailwind --skip-test --skip-system-test . && \
      bin/dev \
    "
