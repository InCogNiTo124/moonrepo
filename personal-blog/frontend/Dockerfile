FROM node:24.8.0-alpine3.22 AS prod
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --prod

# Copy built sources
COPY build ./build

# Run node 
EXPOSE 3000
ENV BLOG_DB="blog-db:80"
CMD ["node", "/app/build"]