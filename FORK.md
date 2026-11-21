# LiveContainer + SideStore (shibeeee fork)

This is a personal fork of [LiveContainer](https://github.com/LiveContainer/LiveContainer), the app
launcher that runs iOS apps inside itself without installing them, bundled with a built-in
[SideStore](https://github.com/SideStore/SideStore) for signing and refreshing.

The fork does three things on top of the official project:

1. **Fixes Apple ID sign-in in the built-in SideStore**, which has failed with HTTP 503 since
   2026-11-20.
2. **Builds SideStore from source** with a small set of fixes, instead of bundling the prebuilt nightly.
3. **Keeps itself up to date.** It merges new LiveContainer commits, rebuilds when LiveContainer or
   SideStore change, and publishes a nightly that the built-in SideStore installs as an update.

Everything else works like the official LiveContainer. For its features and guides, see the
[LiveContainer documentation](https://livecontainer.github.io/docs/intro).

## Install

1. Download [`LiveContainer+SideStore.ipa`](https://github.com/shibeeee/LiveContainer/releases/download/nightly/LiveContainer%2BSideStore.ipa)
   from the [nightly release](https://github.com/shibeeee/LiveContainer/releases/tag/nightly).
   A standalone `LiveContainer.ipa` without SideStore is there too.
2. Install it with [iloader](https://github.com/nab138/iloader) (Import IPA) or your usual sideloading tool.
3. Open the built-in SideStore, sign out, and sign in again with your Apple Account.

## Updates

The built-in SideStore checks this fork's source for new LiveContainer builds:

```
https://github.com/shibeeee/LiveContainer/releases/download/nightly/apps_fork.json
```

Every build gets a higher version number than the last (for example `3.8.14006`), so SideStore always
offers the newest nightly. If an older LiveContainer source from the official project is still listed
in SideStore, remove it so it doesn't offer the official build over this one.

## What's different from the official build

**Sign-in**
- Apple's sign-in server now rejects requests whose `X-Mme-Client-Info` header names the OS
  `macOS;`. The built-in SideStore's requests are rewritten to `Mac OS X;`, whichever source the
  value came from (built-in default, anisette server, or your own override). SideStore's version
  label shows "sign-in fix on" when it is active.
- When Apple still turns a sign-in away (HTTP 429 or 5xx), SideStore says what to do instead of
  "Invalid server response: unparseable format".

**SideStore**
- Built from [LiveContainer/SideStore](https://github.com/LiveContainer/SideStore) (branch
  `LiveContainerSupport`) with the patches in [`SideStorePatches/`](SideStorePatches/README.md).
- Free accounts keep the Increased Memory Limit capability
  ([SideStore#1616](https://github.com/SideStore/SideStore/issues/1616)).
- If the source build ever fails, the prebuilt SideStore nightly is used and the build run shows a warning.

**LiveContainer**
- Multitask: a terminated native window has a Restart App button, and "Skip terminated screen" and
  "Restart app automatically" now work for native windows too
  ([LiveContainer#1741](https://github.com/LiveContainer/LiveContainer/issues/1741)). A maximized
  window keeps its window bar after its app exits, so it can still be closed
  ([#1595](https://github.com/LiveContainer/LiveContainer/issues/1595),
  [#822](https://github.com/LiveContainer/LiveContainer/issues/822)).
- App list: a Show menu (in the sort menu) filters All, Shared, Private or JIT apps
  ([#1573](https://github.com/LiveContainer/LiveContainer/issues/1573)).
- Back Up Data Folder in an app's long-press menu copies its data folder to Files.
- Copy Diagnostics in Settings copies app, iOS and device versions for bug reports. Nothing about your
  account is included.
- A light haptic tap when you press Run.

## How the automation works

| Workflow | When | What it does |
|---|---|---|
| [`sync.yml`](.github/workflows/sync.yml) | Every 6 hours, or by hand | Merges new commits from LiveContainer/LiveContainer into `main`. Starts a build when `main`, SideStore's source or the SideStore nightly changed since the last release. |
| [`fork-release.yml`](.github/workflows/fork-release.yml) | Started by `sync.yml`, or by hand | Builds both IPAs, writes the AltSource (`apps_fork.json`) and `build-info.json`, and publishes the `nightly` release. |
| [`build.yml`](.github/workflows/build.yml) | Every push | Builds the IPAs as workflow artifacts and runs the sign-in fix test. Publishes nothing in this fork. |

If merging upstream conflicts, or upstream changes files in `.github/workflows` (which the workflow
token is not allowed to push), the sync opens an issue here with the commands to merge by hand. Builds
keep using the last merged version until then.

GitHub pauses scheduled workflows in repositories with no activity for 60 days. If updates stop, open
the Actions tab and re-enable "Fork - Sync Upstream".

## Build it yourself

Run "Fork - Build and Release Nightly" from the Actions tab. Pushing to any branch also builds both
IPAs as artifacts with "Xcode - Build". The build runs on GitHub's `xcode-27` macOS runner and needs
no secrets.

The build scripts are in [`.github/`](.github):
- `prepare_dependencies.sh` downloads OpenSSL (checked against a SHA-256) and gives fork builds their
  version number and update source.
- `build_github.sh` packages the IPAs (the `dylibify` download is checked against a SHA-256).
- `build_sidestore.sh` builds SideStore from source with `SideStorePatches/`.
- `tests/run_mme_client_info_test.sh` tests the sign-in header rewrite on Linux.

## Troubleshooting

- **Sign-in still says 503:** wait a few minutes, since repeated failed attempts cause a temporary 503
  of their own. Then reset adi.pb (with "keep headers" unchecked) and try again.
- **Other sign-in errors (-22410, 403, -45061):** these come from account or anisette state. Switch
  the anisette server to jkcoxson, and clear keychain items and refresh attempts in SideStore's
  Developer Options.
- **Reporting a problem:** tap Copy Diagnostics in LiveContainer's Settings and include the result.

## Credits and license

- [LiveContainer](https://github.com/LiveContainer/LiveContainer) by Duy Tran, hugeBlack and contributors.
- [SideStore](https://github.com/SideStore/SideStore) and SideSign by the SideStore team.
- The Increased Memory Limit patch is from SideStore/SideSign pull request 4 by playportdev.
- The 503 cause was tracked down in [SideStore#1745](https://github.com/SideStore/SideStore/issues/1745).

LiveContainer is licensed under the [GNU AGPL v3](LICENSE), and so is this fork. Its full source is
in this repository. This repository is public, like every fork of a public repository on GitHub.
