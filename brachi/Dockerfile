#### BASE
FROM node:22.15.0 AS base
WORKDIR /app

# Install moon binary
RUN npm install -g @moonrepo/cli


#### SKELETON
FROM base AS skeleton

# Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold brachi


#### BUILD
FROM base AS build

# Copy workspace skeleton
COPY --from=skeleton /app/.moon/docker/workspace .

# Install toolchain and dependencies
RUN moon docker setup

# Copy source files
COPY --from=skeleton /app/.moon/docker/sources .

# Install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Setup wasm-pack
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# Build something (optional)
RUN moon run brachi:build


#### PROD
FROM nginx:1.25.4-alpine3.18-slim AS prod-stage
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo

# Copy built files
COPY --from=build /app/brachi/build /usr/share/nginx/html
EXPOSE 80