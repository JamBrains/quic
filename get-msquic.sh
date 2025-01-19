#!/usr/bin/env bash

set -euo pipefail

VERSION="$1"

patch_dir="patches"

do_patch()
{
    patch_source="$1"
    patch_file="${patch_dir}/$(basename ${patch_source})"
    curl -f -L -o "${patch_file}" "$patch_source"
    if patch -p1 -f --dry-run -s < "${patch_file}" 2>/dev/null; then
        patch -p1 < "${patch_file}"
    else
        echo "Skip patching ${patch_file}, already applied"
    fi
}

patch_2_2_3()
{
    local patch_1="https://github.com/microsoft/msquic/commit/73a11d7bdc724432964a2d4bdc4211ed29823380.patch"
    local patch_2="https://github.com/microsoft/msquic/commit/d7a3658cea2bee4a1873623c772dc193165433a6.patch"
    mkdir -p "$patch_dir"
    echo "Patching Msquic 2.2.3"
    do_patch "$patch_1"
    do_patch "$patch_2"
}

patch_2_3_5()
{
    local patch_1="https://github.com/microsoft/msquic/commit/12edf3725475d4a99e5598df3289bace47b8f56e.patch"
    mkdir -p "$patch_dir"
    echo "Patching Msquic 2.3.5"
    do_patch "$patch_1"
}

patch_2_3_8()
{
    local patch_1="https://github.com/microsoft/msquic/commit/12edf3725475d4a99e5598df3289bace47b8f56e.patch"
    local patch_2="https://github.com/microsoft/msquic/commit/e0201eb4e007e7524aef007be67f2281f949f102.patch"
    local patch_3="https://github.com/microsoft/msquic/commit/b16a14a72e8c74407ee4a079a1f57efe0246f739.patch"
    local patch_4="https://github.com/microsoft/msquic/pull/4717/commits/9261dacc1dd9a67f6fa8d5fbe663082508b4c605.patch"
    local patch_5="https://gist.githubusercontent.com/ggwpez/c179bcd5f45bbc54c98cb0f9c7a8201f/raw/804f77444658ec1bb337f087f98886d2ebe2e563/msquic.patch"
    local patch_6="https://gist.githubusercontent.com/ggwpez/8cc1ec2f2b0f0947758e03a687c1097b/raw/ad1af1d7a311de2b746c39a3899dbbfe15352e41/patch2"
    mkdir -p "$patch_dir"
    echo "OTY Patching Msquic 2.3.8"
    for p in patch_1 patch_2 patch_3 patch_4 patch_5 patch_6; do
        do_patch "${!p}"
    done
}

if [ ! -d msquic ]; then
    git clone https://github.com/microsoft/msquic.git -b "$VERSION" --recursive --depth 1 --shallow-submodules msquic
fi

cd msquic

CURRENT_VSN="$(git describe --tags --exact-match 2>/dev/null || echo 'unknown')"

if [ "$CURRENT_VSN" = 'unknown' ]; then
    CURRENT_VSN="$(git rev-parse HEAD)"
fi

if [ "$CURRENT_VSN" != "$VERSION" ]; then
    echo "undesired_msquic_version, required=$VERSION, got=$CURRENT_VSN"
    exit 1
fi

## Patching
case $VERSION in
    v2.2.3)
        patch_2_2_3
        ;;
    v2.3.5)
        patch_2_3_5
        ;;
    v2.3.8)
        patch_2_3_8
        ;;
esac
