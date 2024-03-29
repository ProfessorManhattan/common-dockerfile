FROM node:17-alpine AS codeclimate

WORKDIR /usr/src/app

ENV PREFIX "/usr/local/node_modules"
ENV PATH "$PREFIX/bin:$PATH"
ENV NODE_PATH "$PREFIX"
ENV NPM_CONFIG_PREFIX "$PREFIX"

COPY bin/docs ./bin/docs
COPY engine.json package.json yarn.lock ./

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN adduser --uid 9000 --gecos "" --disabled-password app \
    && mkdir $PREFIX \
    && apk --no-cache add --virtual build-dependencies \
      git=~2 \
      jq=~1 \
      yarn \
    && yarn config set prefix "$PREFIX" \
    && yarn install --modules-folder "$PREFIX" \
    && chown -R app:app "$PREFIX" \
    && VERSION="v$(pnpm list eslint | grep 'eslint ' | sed 's/^[^ ]*.//')" \
    && ./bin/docs "$VERSION" \
    && cat engine.json | jq --arg version "$VERSION" '.version = $version' > /engine.json \
    && apk del build-dependencies

COPY . ./

RUN chown -R app:app ./

USER app

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/eslint.js"]

ARG BUILD_DATE
ARG REVISION
ARG VERSION

LABEL maintainer="Megabyte Labs <help@megabyte.space>"
LABEL org.opencontainers.image.authors="Brian Zalewski <brian@megabyte.space>"
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.description="An ESLint 8 standalone slim container or a slim CodeClimate engine container for GitLab CI - take your pick"
LABEL org.opencontainers.image.documentation="https://github.com/ProfessorManhattan/codeclimate-eslint/blob/master/README.md"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.source="https://gitlab.com/megabyte-labs/docker/codeclimate/eslint.git"
LABEL org.opencontainers.image.url="https://megabyte.space"
LABEL org.opencontainers.image.vendor="Megabyte Labs"
LABEL org.opencontainers.image.version=$VERSION
LABEL space.megabyte.type="code-climate"

FROM codeclimate-eslint AS example

VOLUME /work
WORKDIR /work

RUN sudo rm -rf /code \
  && sudo rm -rf /usr/src/app \
  && sudo rm -f /engine.json

ENTRYPOINT ["pnpx", "eslint"]
CMD ["--version"]

LABEL space.megabyte.type="code-climate-standalone"
