FROM ruby:2.5-slim

LABEL OWNER="Brett Campbell" \
      TEAMNAME="Platform Engineering" \
      maintainer="Brett Campbell" \
      category="Web/Application"

# Throw error if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

# Install deps
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Run app
COPY helloworld.rb ./
CMD ["./helloworld.rb"]
