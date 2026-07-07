#!/usr/bin/env bash
# One-time: create a locally-trusted CA (mkcert) and the wildcard cert that
# the VM's Traefik serves as its default certificate.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v mkcert >/dev/null; then
  echo "mkcert is not installed. Run:  sudo pacman -S mkcert nss" >&2
  exit 1
fi

mkcert -install
mkdir -p certs
mkcert \
  -cert-file certs/wildcard.pem \
  -key-file certs/wildcard-key.pem \
  "*.msmetko.test" msmetko.test \
  "*.terra-incognita.test" terra-incognita.test

echo "OK: certs/wildcard{,-key}.pem written."
