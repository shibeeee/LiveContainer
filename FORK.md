# About this fork

This is a personal build of [LiveContainer](https://github.com/LiveContainer/LiveContainer)
with its built-in SideStore. It keeps up with both projects on its own and adds a few fixes.

## Install and get updates

1. Download `LiveContainer+SideStore.ipa` from the
   [nightly release](https://github.com/shibeeee/LiveContainer/releases/tag/nightly) and install it
   with iloader (Import IPA) or your usual sideloading tool.
2. Open the built-in SideStore. It already checks this fork's source for LiveContainer updates:
   `https://github.com/shibeeee/LiveContainer/releases/download/nightly/apps_fork.json`
3. If an older "LiveContainer" source from the official project is still listed in SideStore,
   remove it so it doesn't offer the official build over this one.

Each build gets a higher version number (for example `3.8.14005`), so SideStore always sees the
newest nightly as an update.

## How it stays up to date

- `.github/workflows/sync.yml` runs every 6 hours. It merges new commits from
  LiveContainer/LiveContainer into `main`, and starts a new build when LiveContainer, SideStore's
  source, or the SideStore nightly changed since the last release.
- If a merge conflicts, or upstream changes workflow files (which the workflow token may not push),
  it opens an issue here with the commands to merge by hand.
- `.github/workflows/fork-release.yml` builds everything and publishes the `nightly` release with the
  AltSource above.

## What's different

- **Apple ID sign-in fix.** Since 2026-11-20 Apple answers HTTP 503 when the `X-Mme-Client-Info`
  header says `macOS;`. The built-in SideStore's requests are rewritten to say `Mac OS X;`.
  SideStore's version label shows "sign-in fix on" when it is active.
- **SideStore built from source** with the patches in `SideStorePatches/` (a clear message when Apple
  rejects a sign-in, and the Increased Memory Limit capability for free accounts). If that build
  fails, the prebuilt SideStore nightly is used and the run shows a warning.
- **Multitask fixes:** terminated native windows can restart (and honour "Skip terminated screen" /
  "Restart app automatically"), and a maximized window keeps its bar after its app exits.
- **App list filter** for All, Shared, Private or JIT apps (in the Sort menu).
- **Refined app rows** (rounder corners, larger text, tinted Run and Install buttons), **Back Up Data
  Folder** in each app's menu, and **Copy Diagnostics** in Settings.
- Build downloads are checked against SHA-256 checksums, and the sign-in fix has a test that runs in CI.

This repository is public, like every fork of a public repository on GitHub.
