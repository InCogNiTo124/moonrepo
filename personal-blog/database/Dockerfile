FROM scratch
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
COPY ./target/x86_64-unknown-linux-musl/release/database ./db.sqlite3 ./
ENV ROCKET_PORT=80
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_LOG_LEVEL=normal
EXPOSE 80
CMD [ "/database" ]
