# LiveContainer + SideStore (shibeeee fork)

This is a personal fork of [LiveContainer](https://github.com/LiveContainer/LiveContainer), the app
launcher that runs iOS apps inside itself without installing them, bundled with a built-in
[SideStore](https://github.com/SideStore/SideStore) for signing and refreshing.

On top of the official project, this fork:

1. **Fixes Apple ID sign-in in the built-in SideStore**, which has failed with HTTP 503 since
   2026-11-20, and adds a one-tap **Repair SideStore Sign-In**.
2. **Builds SideStore from source** with a small set of fixes, instead of bundling the prebuilt nightly.
3. **Fixes several LiveContainer bugs** and adds a few conveniences (listed below).
4. **Keeps itself up to date.** It merges new LiveContainer commits, rebuilds when LiveContainer or
   SideStore change, and publishes builds that the built-in SideStore installs as updates.

Everything else works like the official LiveContainer. For its features and guides, see the
[LiveContainer documentation](https://livecontainer.github.io/docs/intro).

## Download

| Build | What it is | Link |
|---|---|---|
| **Latest release** | A build picked as a full release. | [LiveContainer+SideStore.ipa](https://github.com/shibeeee/LiveContainer/releases/latest/download/LiveContainer%2BSideStore.ipa) ([release page](https://github.com/shibeeee/LiveContainer/releases/latest)) |
| **Nightly** | The newest automatic build. | [LiveContainer+SideStore.ipa](https://github.com/shibeeee/LiveContainer/releases/download/nightly/LiveContainer%2BSideStore.ipa) ([release page](https://github.com/shibeeee/LiveContainer/releases/tag/nightly)) |
| **Older builds** | The 5 most recent nightlies, for rolling back. | `build-<version>` on the [releases page](https://github.com/shibeeee/LiveContainer/releases) |

Each release also has a standalone `LiveContainer.ipa` without SideStore.

## Install

1. Download `LiveContainer+SideStore.ipa` from the table above.
2. Install it with [iloader](https://github.com/nab138/iloader) (Import IPA) or your usual sideloading tool.
3. Open the built-in SideStore, sign out, and sign in again with your Apple Account.
4. If an older LiveContainer source from the official project is listed in SideStore, remove it so it
   doesn't offer the official build over this one.

## Updates

The built-in SideStore checks this fork's source for new LiveContainer builds:

```
https://github.com/shibeeee/LiveContainer/releases/download/nightly/apps_fork.json
```

- Every nightly gets a higher version number than the last (for example `3.8.14006`), so SideStore
  always offers the newest one. Its update screen lists what changed since the previous nightly.
- LiveContainer's Settings shows **Update Available** when a newer nightly is out; tap it to open
  SideStore and install it from My Apps.
- To roll back, install an older `build-<version>` release with iloader.

## What's different from the official build

### Sign-in
- Apple's sign-in server now rejects requests whose `X-Mme-Client-Info` header names the OS
  `macOS;`. The built-in SideStore's requests are rewritten to `Mac OS X;`, whichever source the value
  came from (built-in default, anisette server, or your own override). SideStore's version label
  shows "sign-in fix on" when it is active.
- When Apple still turns a sign-in away (HTTP 429 or 5xx), SideStore says what to do instead of
  "Invalid server response: unparseable format".
- **Repair SideStore Sign-In** (LiveContainer Settings) signs the built-in SideStore out and clears its
  anisette data (adi.pb). Your apps and signing certificate are kept. SideStore opens so you can sign in
  again.

### SideStore
- Built from [LiveContainer/SideStore](https://github.com/LiveContainer/SideStore) (branch
  `LiveContainerSupport`) with the patches in [`SideStorePatches/`](SideStorePatches/README.md).
- Free accounts keep the Increased Memory Limit capability
  ([SideStore#1616](https://github.com/SideStore/SideStore/issues/1616)).
- If the source build ever fails, the prebuilt SideStore nightly is used. The release notes, SideStore's
  update screen and Copy Diagnostics then say the patches are missing.

### LiveContainer
- **Multitask windows:** a terminated native window has a **Restart App** button, and "Skip terminated
  screen" and "Restart app automatically" work for native windows too
  ([LiveContainer#1741](https://github.com/LiveContainer/LiveContainer/issues/1741)). A maximized window
  keeps its window bar after its app exits, so it can still be closed
  ([#1595](https://github.com/LiveContainer/LiveContainer/issues/1595),
  [#822](https://github.com/LiveContainer/LiveContainer/issues/822)).
- **Multitask dock:** long-press an app for Bring to Front, Minimize or Close
  ([#1473](https://github.com/LiveContainer/LiveContainer/issues/1473)). The hidden dock swipes back in
  reliably when several windows are open
  ([#1683](https://github.com/LiveContainer/LiveContainer/issues/1683)).
- **App list:** a **Show** menu inside the sort menu filters All, Shared, Private or JIT apps
  ([#1573](https://github.com/LiveContainer/LiveContainer/issues/1573)). It resets to All each launch.
- **Update check** in Settings ([#336](https://github.com/LiveContainer/LiveContainer/issues/336)).
- **Back Up Data Folder** in an app's long-press menu copies its data folder to Files.
- **Copy Diagnostics** in Settings copies LiveContainer, iOS, device and SideStore versions for bug
  reports. Nothing about your account is included.
- A light haptic tap when you press Run.

### Where to find things

| Feature | Where |
|---|---|
| Repair SideStore Sign-In, update check, Copy Diagnostics | LiveContainer → Settings |
| Show filter | Apps tab → sort menu (top right) → Show |
| Back Up Data Folder | Long-press an app in the Apps tab |
| Restart App | The "This app has been terminated" screen of a native multitask window |
| Skip terminated screen, Restart app automatically | Settings → Multitask |
| Bring to Front, Minimize, Close | Long-press an app in the multitask dock |

### Known issues not fixed here
- Status bar not hiding in full-screen multitask
  ([#729](https://github.com/LiveContainer/LiveContainer/issues/729)) and apps that find no windows in
  multitask ([#1195](https://github.com/LiveContainer/LiveContainer/issues/1195)): the cause couldn't be
  confirmed without a device, so they are left as in the official build.
- Crashes on iOS 27.2 betas and iPhone 18 Pro
  ([#1745](https://github.com/LiveContainer/LiveContainer/issues/1745),
  [#1735](https://github.com/LiveContainer/LiveContainer/issues/1735)) need crash logs. For #1735,
  Reset Symbol Offsets has helped some users: tap the version text at the bottom of Settings five
  times to show the developer options, where it is listed.

## How the automation works

| Workflow | When | What it does |
|---|---|---|
| [`sync.yml`](.github/workflows/sync.yml) | Every 6 hours, or by hand | Merges new commits from LiveContainer/LiveContainer into `main`. Starts a release when `main` (anything but Markdown files), SideStore's source or the SideStore nightly changed since the last release. |
| [`fork-release.yml`](.github/workflows/fork-release.yml) | Started by `sync.yml`, or by hand | Builds both IPAs, writes the AltSource (`apps_fork.json`) and `build-info.json`, publishes the `nightly` release and a `build-<version>` copy, and removes builds older than the last 5. With **stable** ticked it also publishes a full `v<version>` release marked Latest. If it fails, it opens a "Nightly build failed" issue (which emails you); the next successful build closes it. |
| [`build.yml`](.github/workflows/build.yml) | Every push | Builds both IPAs as workflow artifacts and runs the sign-in fix test. Publishes nothing in this fork. These test builds keep the official version number, which is lower than any nightly, so installing one never stops SideStore from offering the next nightly. |

If merging upstream conflicts, or upstream changes files in `.github/workflows` (which the workflow token
is not allowed to push), the sync opens an issue here with the commands to merge by hand. Builds keep
using the last merged version until then.

GitHub pauses scheduled workflows in repositories with no activity for 60 days. If updates stop, open the
Actions tab and re-enable "Fork - Sync Upstream".

## Build it yourself

Run "Fork - Build and Release Nightly" from the Actions tab; tick **stable** to also publish a full
release. Pushing to any branch builds both IPAs as artifacts with "Xcode - Build". Builds run on
GitHub's `xcode-27` macOS runner and need no secrets.

A build takes about 8 minutes when SideStore has to be compiled, and should take about 3 minutes otherwise: the built
SideStore is cached by its commit plus the files in `SideStorePatches/`, so it is only recompiled when one
of those changes.

The build scripts are in [`.github/`](.github):
- `prepare_dependencies.sh` downloads OpenSSL (checked against a SHA-256), sets the update source, and
  gives nightlies their version number.
- `build_github.sh` packages the IPAs (the `dylibify` download is checked against a SHA-256).
- `build_sidestore.sh` builds SideStore from source with `SideStorePatches/`.
- `fork_source.py` writes the AltSource and refuses to publish a build whose version wasn't raised.
- `tests/run_mme_client_info_test.sh` tests the sign-in header rewrite on Linux.

## Troubleshooting

- **Sign-in still says 503:** wait a few minutes, since repeated failed attempts cause a temporary 503 of
  their own. Then use **Repair SideStore Sign-In** and sign in again.
- **Other sign-in errors (-22410, 403, -45061):** these come from account or anisette state. Use
  **Repair SideStore Sign-In**, or switch the anisette server to jkcoxson.
- **A nightly misbehaves:** install the previous `build-<version>` release with iloader.
- **Reporting a problem:** tap **Copy Diagnostics** in LiveContainer's Settings and include the result.

## Credits and license

- [LiveContainer](https://github.com/LiveContainer/LiveContainer) by Duy Tran, hugeBlack and contributors.
- [SideStore](https://github.com/SideStore/SideStore) and SideSign by the SideStore team.
- The Increased Memory Limit patch is from SideStore/SideSign pull request 4 by playportdev.
- The 503 cause was tracked down in [SideStore#1745](https://github.com/SideStore/SideStore/issues/1745).

LiveContainer is licensed under the [GNU AGPL v3](LICENSE), and so is this fork. Its full source is in
this repository. This repository is public, like every fork of a public repository on GitHub.
