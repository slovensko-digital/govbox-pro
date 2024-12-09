FROM ruby:3.3.6

# Install packages
RUN apt-get update && apt-get install -y build-essential nodejs libpq-dev npm fop=1:2.* libsaxon-java libsaxonb-java chromium \
    && apt-get -y install libx11-xcb1 libxcomposite1 libasound2 libatk1.0-0 libatk-bridge2.0-0 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6

# Setup FOP to use saxon xslt parser
RUN sed -i '/find_jars/i \
find_jars saxon saxonb' /usr/bin/fop
RUN sed -i 's/^run_java /run_java -Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl /' /usr/bin/fop

# Set working directory
RUN mkdir /app
WORKDIR /app

RUN npm i -g yarn

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Cache everything
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Run application by default
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
