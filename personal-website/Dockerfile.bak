FROM node:22.2.0-alpine3.18 AS build-stage
WORKDIR /app
COPY . .
RUN yarn install
RUN yarn build

FROM nginx:1.25.4-alpine3.18-slim AS prod-stage
COPY --from=build-stage /app/build /usr/share/nginx/html
RUN sed -i -E '9i \        try_files $uri $uri/ $uri.html =404;' /etc/nginx/conf.d/default.conf
