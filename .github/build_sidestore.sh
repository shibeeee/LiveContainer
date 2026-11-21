#!/bin/bash
# Builds LiveContainer's SideStore fork from source, with the patches in SideStorePatches/ applied.
# Usage: build_sidestore.sh <output.ipa>
# Env: SIDESTORE_REF (branch or commit, default LiveContainerSupport)
set -eo pipefail

OUT="$1"
REF="${SIDESTORE_REF:-LiveContainerSupport}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

rm -rf "$ROOT/sidestore-src"
git clone --quiet --branch "$REF" --depth 1 https://github.com/LiveContainer/SideStore.git "$ROOT/sidestore-src"
cd "$ROOT/sidestore-src"
git submodule update --init --recursive --depth 1
echo "SideStore source: $(git rev-parse HEAD)"

git config user.name "fork-build"
git config user.email "fork-build@localhost"
for patch in "$ROOT"/SideStorePatches/*.patch; do
    [ -e "$patch" ] || continue
    echo "Applying $(basename "$patch")"
    git apply --3way --whitespace=nowarn "$patch"
done

# Same binary artifacts SideStore's own CI pre-fetches for Swift Package Manager.
ART="$HOME/Library/Caches/org.swift.swiftpm/artifacts"
mkdir -p "$ART"
OPENSSL="$ART/https___github_com_krzyzanowskim_OpenSSL_releases_download_3_6_2000_OpenSSL_xcframework_zip"
[ -f "$OPENSSL" ] || curl -fsSL https://github.com/krzyzanowskim/OpenSSL/releases/download/3.6.2000/OpenSSL.xcframework.zip -o "$OPENSSL"
UNICORN="$ART/https___github_com_mahee96_unicorn_releases_download_2_1_4_multiarch_Unicorn_xcframework_zip"
[ -f "$UNICORN" ] || curl -fsSL https://github.com/mahee96/unicorn/releases/download/2.1.4-multiarch/Unicorn.xcframework.zip -o "$UNICORN"

rm -rf AltStore/Resources/Icons.xcassets/Modern/*
mkdir -p build/logs
NSUnbufferedIO=YES make -B build 2>&1 | tee build/logs/build.log | xcpretty
make fakesign
make ipa
cp SideStore.ipa "$OUT"
echo "Built $OUT"
