# The release is NOT built here. `moon run jaja:build` builds it on the host into
# _build/prod/rel/jaja, and this image just copies it in - the same shape as the
# other projects in the monorepo (see personal-blog-database/Dockerfile).
#
# That works because the release is built with include_erts: false (see the
# releases/0 block in mix.exs), so it contains no ERTS and no OTP applications,
# only portable BEAM bytecode. The runtime image therefore has to supply the
# Erlang runtime, and its OTP version MUST match the one that compiled the
# bytecode. Keep OTP_VERSION below in lockstep with "asdf:erlang" in
# .prototools.
#
# https://hub.docker.com/r/hexpm/erlang/tags
ARG OTP_VERSION=29.0.5
ARG DEBIAN_VERSION=trixie-20260803

ARG RUNNER_IMAGE="hexpm/erlang:${OTP_VERSION}-debian-${DEBIAN_VERSION}-slim"

FROM ${RUNNER_IMAGE}
LABEL org.opencontainers.image.source=https://github.com/incognito124/moonrepo

# The erlang image already provides openssl, libstdc++ and ca-certificates;
# locales is the only thing missing for the LANG settings below.
RUN apt-get update -y && apt-get install -y locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app
RUN mkdir -p /app/data && chmod 0777 /app/data

# Expose the standard Phoenix port
EXPOSE 4000

# set runner ENV
ENV MIX_ENV="prod"
ENV PHX_SERVER="true"

COPY --chown=nobody:root ./_build/prod/rel/jaja ./

USER nobody

CMD ["/app/bin/jaja", "start"]
