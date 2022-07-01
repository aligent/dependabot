FROM dependabot/dependabot-core:0.196.2

ARG CODE_DIR=/home/dependabot/dependabot-pipeline
ENV CODE_DIR=${CODE_DIR}
RUN mkdir -p ${CODE_DIR}
COPY --chown=dependabot:dependabot Gemfile Gemfile.lock ${CODE_DIR}/
WORKDIR ${CODE_DIR}

RUN bundle config set --local path "vendor" \
  && bundle install --jobs 4 --retry 3

COPY --chown=dependabot:dependabot . ${CODE_DIR}
COPY --chown=dependabot:dependabot ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]