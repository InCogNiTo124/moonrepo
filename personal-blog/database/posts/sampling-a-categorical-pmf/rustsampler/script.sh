#!/usr/bin/env bash

set -euxo pipefail

# cargo run > "gumbel_direct_nobb.json"
cargo run --release > "gumbel_direct_release_nobb".json
