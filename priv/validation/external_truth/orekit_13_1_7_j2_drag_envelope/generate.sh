#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT_JSON" >&2
  exit 64
fi

bundle_dir="$(cd "$(dirname "$0")" && pwd)"
output_path="$1"
container_image="docker.io/library/maven@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/orekit-j2-drag-envelope.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

docker run --rm --platform=linux/arm64 \
  -v "$bundle_dir:/source:ro" \
  -w /source \
  "$container_image" \
  sha256sum -c source-manifest.sha256

source_identity="$({
  docker run --rm --platform=linux/arm64 \
    -v "$bundle_dir:/source:ro" \
    "$container_image" \
    sha256sum /source/source-manifest.sha256
} | awk '{print $1}')"

docker run --rm --platform=linux/arm64 --cpus=2 --memory=3g \
  -v "$bundle_dir:/source:ro" \
  -v "$work_dir:/work" \
  -w /work \
  "$container_image" \
  sh -euc '
    mkdir -p /work/dependencies /work/classes

    while IFS=" " read -r checksum url filename extra; do
      test -n "$checksum" && test -n "$url" && test -n "$filename" && test -z "${extra:-}"
      printf "%s\n" "$checksum" | grep -Eq "^[0-9a-f]{64}$"
      test ! -e "/work/dependencies/$filename"
      curl --fail --location --silent --show-error "$url" --output "/work/dependencies/$filename"
      printf "%s  %s\n" "$checksum" "/work/dependencies/$filename" | sha256sum -c -
    done < /source/dependencies.lock

    javac --release 21 \
      -cp "/work/dependencies/*" \
      -d /work/classes \
      /source/src/main/java/org/orbitaldynamics/validation/OrekitJ2DragEnvelopeGenerator.java

    java -cp "/work/classes:/work/dependencies/*" \
      org.orbitaldynamics.validation.OrekitJ2DragEnvelopeGenerator \
      /source/case.properties \
      /work/reference-output.json \
      "$1"
  ' sh "$source_identity"

mkdir -p "$(dirname "$output_path")"
cp "$work_dir/reference-output.json" "$output_path"
sha256sum "$output_path"
