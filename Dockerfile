FROM ruby:3.4.8-slim

ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

WORKDIR ${APP_HOME}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      default-libmysqlclient-dev \
      libyaml-dev \
      pkg-config \
      git \
      curl \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ARG BUNDLER_VERSION=4.0.8
RUN gem install bundler -v ${BUNDLER_VERSION}

COPY Gemfile Gemfile.lock ./
RUN bundle _${BUNDLER_VERSION}_ config set path "${BUNDLE_PATH}" && \
    bundle _${BUNDLER_VERSION}_ install --jobs ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY}

COPY . .
RUN sed -i 's/\r$//' bin/docker-entrypoint bin/rails && \
    cp bin/docker-entrypoint /usr/local/bin/qlpm-docker-entrypoint && \
    chmod +x /usr/local/bin/qlpm-docker-entrypoint bin/rails

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/qlpm-docker-entrypoint"]
CMD ["ruby", "./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
