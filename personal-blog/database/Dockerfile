# NOTE: there are two stages because it's very hard to build a standalone rust binary
#### Build phase
FROM rust:1.89.0-alpine3.20 AS build
RUN apk add --no-cache musl-dev
WORKDIR /app
RUN rustup target add x86_64-unknown-linux-musl
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
RUN cargo build --release --target x86_64-unknown-linux-musl --locked

FROM scratch
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
COPY --from=build /app/target/x86_64-unknown-linux-musl/release/database ./
COPY db.sqlite3 ./
ENV ROCKET_PORT=80
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_LOG_LEVEL=normal
EXPOSE 80
CMD [ "/database" ]
