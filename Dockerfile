# syntax=docker/dockerfile:1
# check=error=true

# Make sure this matches the version in .ruby-version.
ARG RUBY_VERSION=4.0.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here.
WORKDIR /app

# Install Node.js 22 rather than the Debian default for Puppeteer/Grover.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Install runtime packages. Chromium is used by Grover for PDF rendering; FOP with
# Saxon renders UPVS form templates; tini reaps orphaned Chromium processes.
RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs \
        libjemalloc2 \
        libpq5 libyaml-0-2 \
        fop=1:2.* libsaxon-java libsaxonb-java \
        chromium \
        tini \
        libx11-xcb1 libxcomposite1 libasound2 libatk1.0-0 libatk-bridge2.0-0 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libxcb1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
    && ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Setup FOP to use saxon xslt parser, the JDK one rejects XPath in some slovensko.sk form templates (JAXP0801001).
# Debian's fop runs fop-core.jar with -jar, which ignores an added classpath, so run its main class instead.
# The grep fails the build when a new fop package changes the script and the sed stops matching.
RUN sed -i 's#-jar /usr/share/java/fop-core.jar#-Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl -cp /usr/share/java/fop-core.jar:/usr/share/java/saxonb.jar org.apache.fop.cli.Main#' /usr/bin/fop \
    && grep -q net.sf.saxon.TransformerFactoryImpl /usr/bin/fop

# Fail the build unless FOP actually runs on Saxon, not only names it in the launcher.
COPY bin/check-fop-saxon /usr/local/bin/check-fop-saxon
RUN /usr/local/bin/check-fop-saxon

# Enable jemalloc, point Puppeteer at the system Chromium and disable its sandbox,
# which is not available in this container (same as needed by the previous root image).
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so" \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium" \
    GROVER_NO_SANDBOX="true"

# Throw-away build stage to reduce size of the final image.
FROM base AS build

# Install packages needed to build gems.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git libpq-dev libyaml-dev pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems.
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

# Install Node dependencies (puppeteer, used by Grover for PDF rendering). The
# browser comes from the system Chromium installed above.
COPY package.json package-lock.json ./
RUN PUPPETEER_SKIP_DOWNLOAD=true npm ci

# Copy application code.
COPY . .

# Precompile bootsnap code for faster boot times.
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompile assets without requiring a real secret key.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image.
FROM base

# Run and own only the runtime files as a non-root user for security.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Copy built artifacts: gems, application.
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /app /app

USER 1000:1000

# Entrypoint prepares the database.
# Tini runs as PID 1 and reaps orphaned Chromium processes left by PDF rendering,
# otherwise they pile up as zombies until the container hits its pids limit.
ENTRYPOINT ["/usr/bin/tini", "--", "/app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime.
EXPOSE 3000
CMD ["./bin/rails", "server"]
