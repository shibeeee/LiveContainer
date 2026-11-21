# download openssl
curl -LO https://github.com/krzyzanowskim/OpenSSL/releases/download/3.6.5000/OpenSSL.xcframework.zip
echo "f50188506490c643715489217d32e458d06cee5579399ff616f0ce2038169fea  OpenSSL.xcframework.zip" | shasum -a 256 -c - || exit 1
unzip OpenSSL.xcframework.zip
rm OpenSSL.xcframework.zip
mv OpenSSL.xcframework Dependencies/OpenSSL.xcframework

# Fork builds: built-in SideStore updates LC from the fork's own AltSource.
if [ -n "$GITHUB_REPOSITORY" ] && [ "$GITHUB_REPOSITORY" != "LiveContainer/LiveContainer" ]; then
    PLIST=LiveContainer/Info.plist
    /usr/libexec/PlistBuddy -c "Add :LCUpdateSourceURL string https://github.com/$GITHUB_REPOSITORY/releases/download/nightly/apps_fork.json" "$PLIST"
    # Only the nightly release gets a version that always goes up. Test builds keep the upstream
    # version, which is lower, so installing one never hides a newer nightly from SideStore.
    if [ "$FORK_RELEASE" = "true" ]; then
        BASE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
        MAJOR_MINOR=${BASE%.*}
        PATCH=${BASE##*.}
        FORK_VERSION="$MAJOR_MINOR.$((PATCH * 1000 + GITHUB_RUN_NUMBER))"
        echo "Fork nightly: version $BASE -> $FORK_VERSION"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $FORK_VERSION" "$PLIST"
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $FORK_VERSION" "$PLIST"
    fi
fi
