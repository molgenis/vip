#!/bin/bash
set -euo pipefail

cleanup() {
  rm -rf "${TMP_WORK_DIR}"
}

if [ -z "${TMPDIR+x}" ]; then
  TMPDIR=/tmp
fi

if [ -z "${TMP_WORK_DIR+x}" ]; then
  TMP_WORK_DIR=$(mktemp -d)
  export TMP_WORK_DIR
  trap cleanup EXIT
fi

if [ -z "${SINGULARITY_TMPDIR+x}" ]; then
  SINGULARITY_TMPDIR="${TMPDIR}"
  export SINGULARITY_TMPDIR
fi

if [ -z "${SINGULARITY_CACHEDIR+x}" ]; then
  SINGULARITY_CACHEDIR="${TMPDIR}"
  export SINGULARITY_CACHEDIR
fi

declare -A VIP_CFG_MAP

VIP_VERSION="3.3.1"
