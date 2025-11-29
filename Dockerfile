# syntax = docker/dockerfile:1

# MÚDULO 1: Base
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# --- CAMBIO CRÍTICO AQUÍ ---
# Configuramos entorno de PRODUCCIÓN
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Instalar paquetes base
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# MÚDULO 2: Build
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config

# Instalar Bundler
RUN gem install bundler -v 2.7.2

COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Precompilar bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Precompilar assets (IMPORTANTE: Usamos un dummy key porque no necesitamos la real para compilar assets en este punto)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# MÚDULO 3: Imagen Final
FROM base

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

RUN mkdir -p /rails/tmp /rails/log /rails/storage /rails/db && \
    chown -R rails:rails /rails

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

# --- CAMBIO IMPORTANTE ---
# Forzamos binding a 0.0.0.0 por seguridad, aunque production suele hacerlo por defecto.
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]