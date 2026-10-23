FROM ruby:4.0.6 AS base

# Install Node.js 22 rather than the Debian default (Node.js 18).
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Install packages
RUN apt-get update && apt-get install -y build-essential nodejs libpq-dev libjemalloc2 fop=1:2.* libsaxon-java libsaxonb-java chromium \
    && apt-get -y install libx11-xcb1 libxcomposite1 libasound2 libatk1.0-0 libatk-bridge2.0-0 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6

# Enable jemalloc for reduced memory usage and latency (Rails 8 default).
RUN ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so
ENV LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Setup FOP to use saxon xslt parser, the JDK one rejects XPath in some slovensko.sk form templates (JAXP0801001).
# Debian's fop runs fop-core.jar with -jar, which ignores an added classpath, so run its main class instead.
# The grep fails the build when a new fop package changes the script and the sed stops matching.
RUN sed -i 's#-jar /usr/share/java/fop-core.jar#-Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl -cp /usr/share/java/fop-core.jar:/usr/share/java/saxonb.jar org.apache.fop.cli.Main#' /usr/bin/fop \
    && grep -q net.sf.saxon.TransformerFactoryImpl /usr/bin/fop

# Fail the build unless FOP actually runs on Saxon, not only names it in the launcher.
COPY bin/check-fop-saxon /usr/local/bin/check-fop-saxon
RUN /usr/local/bin/check-fop-saxon

FROM base

# Set working directory
RUN mkdir /app
WORKDIR /app

# Bundle and cache Ruby gems
COPY Gemfile* ./
RUN bundle config set deployment true
RUN bundle config set without development:test
RUN bundle install

# Install Node dependencies (puppeteer, used by Grover for PDF rendering)
COPY package.json package-lock.json ./
RUN npm ci

# Cache everything
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

RUN SECRET_KEY_BASE=NONE RAILS_ENV=production bundle exec rails assets:precompile

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
CMD ["./bin/rails", "server"]
