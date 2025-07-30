# This template builds two images, to optimise caching:
# builder: builds gems and node modules
# production: runs the actual app

# Build builder image
FROM ruby:3.4.4-alpine3.22 AS builder

WORKDIR /app

# Add the timezone (builder image) as it's not configured by default in Alpine
RUN apk add --update --no-cache tzdata && \
    cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
    echo "Europe/London" > /etc/timezone

# build-base: dependencies for bundle
# yarn: node package manager
# postgresql-dev: postgres driver and libraries
# yaml-dev: psych issues
RUN apk add --no-cache build-base yarn postgresql16-dev yaml-dev

# Install gems defined in Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems and remove gem cache
RUN bundler -v && \
    bundle config set no-cache 'true' && \
    bundle config set no-binstubs 'true' && \
    bundle config set without 'development test' && \
    bundle install --retry=5 --jobs=4 && \
    rm -rf /usr/local/bundle/cache

RUN yarn global add corepack
RUN corepack enable && corepack prepare yarn@4.9.1 --activate

# Install node packages defined in package.json
COPY package.json yarn.lock ./
RUN yarn install --immutable

# Copy all files to /app (except what is defined in .dockerignore)
COPY . .

# Precompile assets
RUN RAILS_ENV=production SECRET_KEY_BASE=required-to-run-but-not-used \
    bundle exec rails assets:precompile

# Cleanup to save space in the production image
RUN rm -rf node_modules log/* tmp/* /tmp && \
    rm -rf /usr/local/bundle/cache && \
    rm -rf .env && \
    find /usr/local/bundle/gems -name "*.c" -delete && \
    find /usr/local/bundle/gems -name "*.h" -delete && \
    find /usr/local/bundle/gems -name "*.o" -delete && \
    find /usr/local/bundle/gems -name "*.html" -delete

# Build runtime image
FROM ruby:3.4.4-alpine3.22 AS production

# The application runs from /app
WORKDIR /app

# Add the timezone (prod image) as it's not configured by default in Alpine
RUN apk add --update --no-cache tzdata && \
    cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
    echo "Europe/London" > /etc/timezone

# Create non-root user and group
RUN addgroup -S appgroup -g 20001 && adduser -S appuser -G appgroup -u 10001

# libpq: required to run postgres
RUN apk add --no-cache libpq

# Copy files generated in the builder image
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Change ownership only for directories that need write access
RUN chown -R appuser:appgroup /app/tmp

ARG COMMIT_SHA
ENV COMMIT_SHA=$COMMIT_SHA

# Use non-root user
USER 10001

ENTRYPOINT ["./bin/rails", "server"]

CMD ["-b", "0.0.0.0"]
