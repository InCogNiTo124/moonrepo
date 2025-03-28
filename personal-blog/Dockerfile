#### BASE
FROM node:22.2.0 AS base
WORKDIR /app

# Install moon binary
RUN npm install -g @moonrepo/cli


#### SKELETON
FROM base AS skeleton

# Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold personal-blog-database


#### BUILD
FROM base AS build

# Copy workspace skeleton
COPY --from=skeleton /app/.moon/docker/workspace .

# Install toolchain and dependencies
RUN moon docker setup

# Copy source files
COPY --from=skeleton /app/.moon/docker/sources .

# Build something (optional)
RUN moon run personal-blog:build

# CMD ["node", "/app/personal-blog/build/"]


#### PROD
FROM node:22.2.0

# Copy built files
COPY --from=build /app/personal-blog/build /build
CMD ["node", "/build/"]