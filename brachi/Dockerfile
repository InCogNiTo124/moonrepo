FROM nginx:1.25.4-alpine3.18-slim AS prod-stage
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo

# Copy built files
COPY ./build /usr/share/nginx/html
EXPOSE 80