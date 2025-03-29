#### BASE
FROM node:22.2.0 AS base
WORKDIR /app

# Install moon binary
RUN npm install -g @moonrepo/cli


#### SKELETON
FROM base AS skeleton

# Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold personal-website


#### BUILD
FROM base AS build

# Copy workspace skeleton
COPY --from=skeleton /app/.moon/docker/workspace .

# Install toolchain and dependencies
RUN moon docker setup

# Copy source files
COPY --from=skeleton /app/.moon/docker/sources .

# Build something (optional)
RUN moon run personal-website:build


#### PROD
FROM nginx:1.25.4-alpine3.18-slim AS prod-stage
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo

# Copy built files
COPY --from=build /app/personal-website/build /usr/share/nginx/html

# Configure routing
RUN sed -i -E '9i \        try_files $uri $uri/ $uri.html =404;' /etc/nginx/conf.d/default.conf
