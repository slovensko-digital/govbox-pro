FROM ruby:3.3.0

# Install packages
RUN apt-get update && apt-get install -y build-essential nodejs libpq-dev npm

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
