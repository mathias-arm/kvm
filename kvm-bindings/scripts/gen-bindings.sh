#!/bin/bash
# Re-generate the bindings for each arch, from the given Linux tree

LINUX_SRC="$1"

set -eu

if [ -z "$LINUX_SRC" -o '!' -d "$LINUX_SRC" ]; then
    echo "Usage: $0 <linux source>"
    exit 1
fi

gen_bindings () {
    make -C "$LINUX_SRC" headers_install ARCH=$ARCH INSTALL_HDR_PATH=$(pwd)/"$ARCH"_headers
    pushd "$ARCH"_headers >/dev/null
    bindgen include/linux/kvm.h -o bindings.rs  \
        --impl-debug --with-derive-default  \
        --with-derive-partialeq  --impl-partialeq \
        -- -Iinclude
    popd >/dev/null

    # Find all struct names between "serde_impls!" and ")" lines
    structs=$(sed -nE -e "/^serde_impls\!/,/^\)/s/^ +([^,]+),?/\1/gp" src/$ARCH/serialize.rs)

    insert_text="#[cfg_attr(\n    feature = \"serde\",\n    derive(zerocopy::AsBytes, zerocopy::FromBytes, zerocopy::FromZeroes)\n)]\n"

    # Insert the $insert_text before each struct definition
    for struct in $structs; do
        sed -i "s/pub struct $struct {/$insert_text&/" "$ARCH"_headers/bindings.rs
    done

    cp -f "$ARCH"_headers/bindings.rs src/$ARCH/
}

for ARCH in arm64 x86_64; do
    gen_bindings
done
