ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_PATH=/usr/local/bundle

# Dependencias base
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libvips \
    curl \
    git \
    postgresql-client && \
    rm -rf /var/lib/apt/lists/*

FROM base AS build

COPY Gemfile Gemfile.lock ./

RUN gem install bundler && bundle install

COPY . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM base

# Crear usuario no-root
RUN addgroup --system --gid 1000 rails && \
    adduser --system --uid 1000 --gid 1000 --home /home/rails rails

USER rails

WORKDIR /app

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /app /app

# Crear carpetas necesarias
RUN mkdir -p tmp log storage && \
    chmod -R 755 tmp log storage

# ---- Cloud Run usa PORT ----
EXPOSE 8080

ENTRYPOINT ["bin/docker-entrypoint"]

# ---- Puma config ----
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

CMD ["bash", "-c", "bundle exec puma -C config/puma.rb"]
