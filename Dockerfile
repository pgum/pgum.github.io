FROM jvconseil/jekyll-docker:4.3.3

COPY --chown=jekyll:jekyll Gemfile .
COPY --chown=jekyll:jekyll Gemfile.lock .

RUN bundle install --quiet

CMD ["jekyll", "serve", "--force_polling"]