"""Write the AltSource for a fork's nightly LiveContainer+SideStore build.

Built-in SideStore in fork builds reads this file (see LCUpdateSourceURL in
prepare_dependencies.sh), so each new nightly shows up as an update on the device.

Usage: python fork_source.py <ipa> <out.json>
Env: GITHUB_REPOSITORY, COMMIT_SHA, COMMIT_MSG, RUN_URL, UPSTREAM_SHA, SIDESTORE_SOURCE,
     CHANGES (one "- line" per change since the last release, optional)
"""
import json
import os
import plistlib
import sys
import zipfile
from datetime import datetime, timezone


def read_info_plist(ipa_path):
    with zipfile.ZipFile(ipa_path) as ipa:
        name = next(n for n in ipa.namelist()
                    if n.startswith("Payload/") and n.endswith(".app/Info.plist") and n.count("/") == 2)
        return plistlib.loads(ipa.read(name))


def main():
    ipa_path, out_path = sys.argv[1], sys.argv[2]
    repo = os.environ["GITHUB_REPOSITORY"]
    info = read_info_plist(ipa_path)
    version = info["CFBundleShortVersionString"]
    # an unstamped build keeps the upstream version, which would look older than an installed nightly
    if not info.get("LCForkNightly"):
        sys.exit(f"Refusing to publish {version}: the nightly version was not stamped (is fork_release set?)")
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    commit = os.environ.get("COMMIT_SHA", "")[:7]
    message = os.environ.get("COMMIT_MSG", "").strip()

    changes = os.environ.get("CHANGES", "").strip()
    if info.get("LCSideStoreFromSource", True):
        sidestore = f"SideStore source: {os.environ.get('SIDESTORE_SOURCE', 'unknown')[:7]}, with this fork's patches"
    else:
        sidestore = "Warning: SideStore could not be built from source, so this build has the prebuilt SideStore without this fork's patches."
    description = "\n".join(part for part in [
        f"What's new:\n{changes}" if changes else "",
        f"Nightly build of {repo} from {commit}: {message}",
        f"Upstream LiveContainer: {os.environ.get('UPSTREAM_SHA', 'unknown')[:7]}",
        sidestore,
        f"Built by {os.environ.get('RUN_URL', '')}",
    ] if part)
    release = {
        "version": version,
        "buildVersion": info.get("CFBundleVersion", version),
        "date": now,
        "localizedDescription": description,
        "downloadURL": f"https://github.com/{repo}/releases/download/nightly/LiveContainer%2BSideStore.ipa",
        "size": os.path.getsize(ipa_path),
    }
    raw = f"https://raw.githubusercontent.com/{repo}/main/screenshots"
    # reuse the permissions upstream declares, so SideStore accepts the entitlements LC asks for
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "apps_ss_lc.json")) as f:
        permissions = json.load(f)["apps"][0].get("appPermissions", {})
    source = {
        "name": f"LiveContainer + SideStore ({repo})",
        "identifier": f"com.livecontainer.source.fork.{repo.replace('/', '.').lower()}",
        "website": f"https://github.com/{repo}",
        "subtitle": "Nightly builds of LiveContainer + SideStore from this fork.",
        "description": "Nightly builds from this fork. Each build includes the latest LiveContainer and SideStore.",
        "tintColor": "#0784FC",
        "iconURL": f"{raw}/AppIcon1024.png",
        "apps": [{
            "beta": False,
            "name": "LiveContainer + SideStore",
            "bundleIdentifier": "com.kdt.livecontainer",
            "developerName": "LiveContainer Team",
            "subtitle": "Run iOS apps without actually installing them!",
            "localizedDescription": "Run iOS apps without actually installing them!",
            "iconURL": f"{raw}/AppIcon1024.png",
            "tintColor": "#0784FC",
            "category": "utilities",
            "screenshotURLs": [f"{raw}/1.png"],
            "appPermissions": permissions,
            **{k: release[k] for k in ("version", "downloadURL", "size")},
            "versionDate": now,
            "versionDescription": description,
            "versions": [release],
            # list the build on both tracks so it shows whether or not beta updates are on
            "releaseChannels": [
                {"track": "stable", "releases": [release]},
                {"track": "nightly", "releases": [release]},
            ],
        }],
        "news": [],
    }
    with open(out_path, "w") as f:
        json.dump(source, f, indent=2)
    print(f"Wrote {out_path} for version {version}")
    github_env = os.environ.get("GITHUB_ENV")
    if github_env:
        with open(github_env, "a") as f:
            f.write(f"NIGHTLY_VERSION={version}\n")
            f.write(f"SIDESTORE_FROM_SOURCE={str(info.get('LCSideStoreFromSource', True)).lower()}\n")


if __name__ == "__main__":
    main()
