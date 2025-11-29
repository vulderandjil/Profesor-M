# syntax = docker/dockerfile:1

# MÚDULO 1: Base
# Usamos una imagen ligera de Ruby
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Directorio de trabajo
WORKDIR /rails

# Variables de entorno base (ajustadas para desarrollo)
# - No activar modo deployment de Bundler y no excluir el grupo :development
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Instalar paquetes base necesarios para runtime
# libvips es para procesamiento de imágenes (ActiveStorage)
# curl es para healthchecks
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# MÚDULO 2: Build
FROM base AS build


# Instalar paquetes necesarios SOLO para construir la app
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config

# Copiar Gemfile y Gemfile.lock
RUN gem install bundler -v 2.7.2

COPY Gemfile Gemfile.lock ./

# Instalar gemas
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copiar el código de la aplicación
COPY . .

# Precompilar código de bootsnap para un arranque más rápido
RUN bundle exec bootsnap precompile app/ lib/

# Precompilar assets (Tailwind CSS)
# Nota: Si usas credenciales en assets, necesitarías pasar RAILS_MASTER_KEY como build-arg, 
# pero para Tailwind estándar usualmente no es necesario.

# MÚDULO 3: Imagen Final
FROM base

# Crear un usuario no-root por seguridad
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Copiar artefactos construidos desde la etapa 'build' y ajustar propietario
COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

# Asegurar que existen los directorios esenciales y tienen el propietario correcto
RUN mkdir -p /rails/tmp /rails/log /rails/storage /rails/db && \
    chown -R rails:rails /rails

USER rails:rails

# Entrypoint prepara la DB (si es necesario) y lanza el servidor
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Exponer el puerto 3000
EXPOSE 3000

# Comando por defecto
CMD ["./bin/rails", "server"]