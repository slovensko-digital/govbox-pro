FROM ruby:3.3.0

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
RUN npm i npx

# Bundle and cache Ruby gems
COPY Gemfile* ./
RUN bundle config set deployment true
RUN bundle config set without development:test
RUN bundle install

# Cache everything
COPY . .

RUN SECRET_KEY_BASE=NONE RAILS_ENV=production bundle exec rails assets:precompile

# Run application by default
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
