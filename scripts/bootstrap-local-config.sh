#!/bin/sh

set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

copy_if_missing() {
  src="$1"
  dst="$2"

  if [ -e "$dst" ]; then
    printf '%s exists, skipping\n' "$dst"
    return 0
  fi

  cp "$src" "$dst"
  printf 'created %s from %s\n' "$dst" "$src"
}

mkdir -p "$root_dir/configs/eventbox/certs"
mkdir -p "$root_dir/configs/ingress/certs"

copy_if_missing "$root_dir/configs/eventbox/.env.example" "$root_dir/configs/eventbox/.env.eventbox"
copy_if_missing "$root_dir/configs/ingress/.env.example" "$root_dir/configs/ingress/.env.nginx"
copy_if_missing "$root_dir/configs/monitor/.env.example" "$root_dir/configs/monitor/.env.grafana"
copy_if_missing "$root_dir/configs/eventbox/application.properties.example" "$root_dir/configs/eventbox/application.properties"
copy_if_missing "$root_dir/configs/eventbox/service-account-key.json.example" "$root_dir/configs/eventbox/service-account-key.json"

printf 'local config scaffold ready\n'
