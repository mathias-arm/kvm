#!/usr/bin/env bash
# Re-generate the bindings for each arch, from the given Linux tree

LINUX_SRC="$1"

set -eu

if [ -z "$LINUX_SRC" -o '!' -d "$LINUX_SRC" ]; then
    echo "Usage: $0 <linux source>"
    exit 1
fi

gen_bindings () {
    rm -rf "${ARCH}_headers"
    if [ "$ARCH" = "riscv64" ] ; then
        make -C "$LINUX_SRC" headers_install ARCH=riscv INSTALL_HDR_PATH=$(pwd)/"${ARCH}_headers" ; \
    else \
        make -C "$LINUX_SRC" headers_install ARCH=$ARCH INSTALL_HDR_PATH=$(pwd)/"${ARCH}_headers" ; \
    fi
    pushd "${ARCH}_headers" >/dev/null
    bindgen include/linux/kvm.h -o bindings.rs  \
        --impl-debug --with-derive-default  \
        --with-derive-partialeq  --impl-partialeq \
        -- -Iinclude
    popd >/dev/null

    perl scripts/fix-serde.pl "${ARCH}_headers/bindings.rs" "src/$ARCH/serialize.rs" "src/$ARCH/bindings.rs"
}

for ARCH in arm64 x86_64 riscv64; do
    gen_bindings
done
