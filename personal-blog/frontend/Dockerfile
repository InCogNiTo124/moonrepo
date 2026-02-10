FROM oven/bun:1.3.9-alpine AS base
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
WORKDIR /app

# ---
# install dependencies into temp directory
# this will cache them and speed up future builds
# FROM base AS install
# RUN mkdir -p /temp/dev
# COPY package.json bun.lock /temp/dev/
# install with --production (exclude devDependencies)
# RUN mkdir -p /temp/prod
# COPY package.json bun.lock /temp/prod/
# RUN cd /temp/prod && bun install --frozen-lockfile --production

FROM base AS release
# COPY --from=install /temp/prod/node_modules node_modules
COPY ./build ./build
# COPY --from=prerelease /app/build .
# COPY --from=prerelease /app/package.json .

# run the app
USER bun
EXPOSE 3000/tcp
ENV BLOG_DB="blog-db:80"
ENTRYPOINT [ "bun", "run", "/app/build/" ]