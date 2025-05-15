# NOTE: there are two stages because it's very hard to build a standalone rust binary +
# compile my blog which has Katex in the same environment.

#### Build phase
FROM rust:1.87.0-alpine3.20 AS build
RUN apk add --no-cache musl-dev bash curl xz git
RUN rustup target add x86_64-unknown-linux-musl
# this is so painful I can't believe I have to do this
RUN wget https://moonrepo.dev/install/proto.sh && bash proto.sh --yes
RUN /root/.proto/bin/proto install moon
COPY . .
RUN /root/.proto/bin/moon docker scaffold personal-blog-database
RUN /root/.proto/bin/moon run personal-blog-database:build  # creates a target/release/database binary

FROM python:3.13.3 AS sqlite
RUN wget https://moonrepo.dev/install/proto.sh && bash proto.sh --yes
RUN /root/.proto/bin/proto install moon && /root/.proto/bin/proto install uv
COPY . .
RUN /root/.proto/bin/moon docker scaffold personal-blog-database
RUN /root/.proto/bin/moon run personal-blog-database:compile  # creates db.sqlite3 and feed.rss

FROM scratch
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
COPY --from=build /personal-blog/database/target/release/database ./
COPY --from=sqlite /personal-blog/database/db.sqlite3 /personal-blog/database/feed.rss ./
ENV ROCKET_PORT=80
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_LOG_LEVEL=normal
EXPOSE 80
CMD [ "./database" ]