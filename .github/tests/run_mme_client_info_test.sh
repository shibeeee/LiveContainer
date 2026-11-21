#!/bin/sh
# Compiles the X-Mme-Client-Info rewrite from SideStoreHooks.m against GNUstep Foundation and runs it.
# Needs: clang, libgnustep-base-dev, gobjc (for the GNU ObjC runtime headers).
set -e
cd "$(dirname "$0")"
sed -n '/BEGIN MME_CLIENT_INFO_FIX/,/END MME_CLIENT_INFO_FIX/p' ../../SideStoreSupport/SideStoreHooks.m > mme_client_info_fix.inc
[ -s mme_client_info_fix.inc ] || { echo "markers not found in SideStoreHooks.m"; exit 1; }
OBJC_INC=$(dirname "$(dirname "$(find /usr/lib/gcc -path '*objc/objc.h' | head -1)")")
clang $(gnustep-config --objc-flags) -I"$OBJC_INC" -fobjc-runtime=gcc -fno-blocks -Wno-unused-function \
    mme_client_info_test.m -o mme_client_info_test $(gnustep-config --base-libs)
./mme_client_info_test
