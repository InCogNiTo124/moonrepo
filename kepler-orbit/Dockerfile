# FROM node:20.13.1-alpine3.18 AS build-stage
# WORKDIR /orbit
# ADD . .
# RUN yarn install
# RUN yarn build

# FROM node:20.13.1-alpine3.18 AS prod-stage
# RUN yarn global add serve
# COPY package.json yarn.lock ./
# RUN yarn install --prod
# COPY --from=build-stage /orbit/dist /dist
# EXPOSE 6090
# CMD serve -l 6090 /dist


#### BASE
FROM node:22.16.0 AS base
WORKDIR /app

# Install moon binary
RUN npm install -g @moonrepo/cli


#### SKELETON
FROM base AS skeleton

# Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold kepler-orbit


#### BUILD
FROM base AS build

# Copy workspace skeleton
COPY --from=skeleton /app/.moon/docker/workspace .

# Install toolchain and dependencies
RUN moon docker setup

# Copy source files
COPY --from=skeleton /app/.moon/docker/sources .

# Build something (optional)
RUN moon run kepler-orbit:build

FROM node:22.2.0-alpine3.18 AS prod
LABEL org.opencontainers.image.source="https://github.com/InCogNiTo124/moonrepo"
WORKDIR /app
COPY --from=build /app/kepler-orbit/dist ./dist/
COPY --from=build /app/kepler-orbit/node_modules ./node_modules/
COPY --from=build /app/kepler-orbit/package.json .
EXPOSE 6090
CMD ["yarn", "run", "serve", "-n", "-l", "6090", "/app/dist"]
