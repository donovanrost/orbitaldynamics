#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT_CSV" >&2
  exit 64
fi
bundle_dir="$(cd "$(dirname "$0")" && pwd)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/mission-baseline.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
image="docker.io/library/maven@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237"
docker run --rm --platform=linux/arm64 --cpus=2 --memory=2g \
  -v "$bundle_dir:/source:ro" -v "$work_dir:/work" -w /work "$image" sh -euc '
  mkdir dependencies classes
  while read -r checksum url filename; do
    curl --fail --location --silent --show-error "$url" -o "dependencies/$filename"
    printf "%s  %s\n" "$checksum" "dependencies/$filename" | sha256sum -c -
  done < /source/dependencies.lock
  javac --release 21 -cp "dependencies/*" -d classes /source/MissionBaseline.java
  java -cp "classes:dependencies/*" MissionBaseline /source /work/reference-output.csv
'
mkdir -p "$(dirname "$1")"
cp "$work_dir/reference-output.csv" "$1"
