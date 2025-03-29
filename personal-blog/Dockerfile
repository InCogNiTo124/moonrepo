#### BASE
FROM node:22.2.0-alpine3.20 AS base
ENV MOON_TOOLCHAIN_FORCE_GLOBALS=true
WORKDIR /app

# Install moon binary
RUN npm install -g @moonrepo/cli

#### SKELETON STAGE
#### Scaffolds repository skeleton structures.

FROM base AS skeleton

# Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold personal-blog

#### BUILD STAGE
#### Builds the project.

FROM base AS build
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo

# Copy workspace configs
COPY --from=skeleton /app/.moon/docker/workspace .

# Install dependencies
RUN moon docker setup

# Copy project sources
COPY --from=skeleton /app/.moon/docker/sources .

# Build the project
# Prune extraneous dependencies
# prune breaks the build so I'm doing it myself until I figure out how to utilize it
RUN moon run personal-blog:build
# && rm -rf /app/personal-website /app/personal-blog/database

RUN yarn install --prod --cwd /app/personal-reusables && yarn install --prod --cwd /app/personal-blog
# RUN [ "rm", "-rf", "/app/.moon", "/app/personal-website", "/app/personal-blog/database", "/usr/local/share/.cache" ]

CMD ["node", "/app/personal-blog/build/"]

#### PROD STAGE
#### Runs the project.

FROM node:22.2.0-alpine3.20 AS prod
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
WORKDIR /app
# Copy built sources
COPY --from=build /app/personal-blog/build build/
COPY --from=build /app/personal-blog/package.json .
COPY --from=build /app/personal-blog/node_modules node_modules/
COPY --from=build /app/personal-reusables /personal-reusables

# Run node 
EXPOSE 3000
CMD node /app/build

