FROM jvconseil/jekyll-docker:4.3.3

COPY --chown=jekyll:jekyll src/Gemfile .
COPY --chown=jekyll:jekyll src/Gemfile.lock .

RUN bundle install --quiet

CMD ["jekyll", "serve", "--force_polling"]