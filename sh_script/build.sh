# Copyright (c) 2022 - 2023 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

#!/bin/bash

ALGO="sha256,sha384"
BUILD_OPT="build"

usage() {
   echo "$0 [options]"
   echo "Available <commands>:"
   echo " -algo [sha256,sha384,sha512] Supported hash algorithm. (default supported algorithms are sha256 and sha384)"
   echo " -clean Clean the build objects"
  exit 1
}

function clean() {
  pushd deps/rust-tpm-20-ref
  /bin/bash sh_script/build.sh -clean
  popd

  pushd deps/td-shim
  cargo clean
  popd

  pushd deps/rust-spdm
  cargo clean
  popd

  cargo clean
}

function build() {
  SUPPORTED_HASH_ALGO=""
  [[ "${ALGO}" != "" ]] && SUPPORTED_HASH_ALGO=",${ALGO}"

  pushd deps/rust-tpm-20-ref
  /bin/bash sh_script/build.sh -algo ${ALGO}
  popd

  pushd deps/td-shim
  cargo xbuild -p td-shim \
    --target x86_64-unknown-none \
    --release --features=main,tdx \
    --no-default-features
  popd

  cargo xbuild \
    --target x86_64-unknown-none \
    --features=td-logger/tdx${SUPPORTED_HASH_ALGO} \
    -p vtpmtd --release

  pushd deps/td-shim
  cargo run -p td-shim-tools \
    --bin td-shim-ld --features=linker \
    --no-default-features \
    -- target/x86_64-unknown-none/release/ResetVector.bin target/x86_64-unknown-none/release/td-shim \
    -p ../../target/x86_64-unknown-none/release/vtpmtd \
    -t executable \
    -o ../../target/x86_64-unknown-none/release/vtpmtd.bin
  popd
}

while [[ $1 != "" ]]; do
  case "$1" in
    -algo)
      ALGO=$2
      shift
      ;;
    -clean)
      BUILD_OPT="clean"
      shift
      ;;
   *)        usage;;
   esac
   shift
done

set -ex

export CC=clang
export AR=llvm-ar

case "${BUILD_OPT}" in
    clean) clean ;;
    build) build ;;
    *) echo "unknown build option - ${BUILD_OPT}" ;;
esac
