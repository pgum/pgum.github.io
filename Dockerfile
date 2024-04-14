FROM jvconseil/jekyll-docker

COPY --chown=jekyll:jekyll Gemfile .
COPY --chown=jekyll:jekyll Gemfile.lock .

RUN bundle install --quiet

CMD ["jekyll", "serve", "--force_polling", "--trace"]