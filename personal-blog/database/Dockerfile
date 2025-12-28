# Hack: Use a temporary stage to prepare the directory structure
FROM alpine:latest AS image-preparer
WORKDIR /out
COPY ./posts ./
# Delete all files that are NOT .jpg AND NOT .png, then remove empty directories
RUN find . -type f ! -name '*.jpg' ! -name '*.png' -delete && \
    find . -type d -empty -delete   

FROM scratch
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo
COPY --from=image-preparer /out ./
COPY ./target/x86_64-unknown-linux-musl/release/database ./db.sqlite3 ./
ENV ROCKET_PORT=80
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_LOG_LEVEL=normal
EXPOSE 80
CMD [ "/database" ]
