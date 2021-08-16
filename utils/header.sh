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

declare -A VIP_CFG_MAP

VIP_VERSION="2.4.3"
