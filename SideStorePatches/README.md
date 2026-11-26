# SideStore patches

Fork builds compile LiveContainer's SideStore fork
([`LiveContainer/SideStore`](https://github.com/LiveContainer/SideStore), branch `LiveContainerSupport`)
from source with the patches in this folder, using [`.github/build_sidestore.sh`](../.github/build_sidestore.sh):

- `*.patch` in this folder apply to the SideStore repository root.
- `SideSign/*.patch` apply inside `Dependencies/SideSign`, the signing library SideStore builds from a
  submodule.

Patches apply in name order with `git apply --3way`.

## Current patches

| Patch | What it does |
|---|---|
| `001-refresh-all-apps-never-hangs.patch` | The Refresh All Apps action could hang forever when SideStore failed to start the refresh (`try?` dropped the error and never finished). It now reports the error. Inside LiveContainer's background process it also waits for the refresh to finish instead of asking to continue in the foreground after 27 seconds, which failed the shortcut there. |
| `002-reject-incomplete-downloads.patch` | A download that dropped partway, or a server error page, was accepted and failed later as "Archive appears to be corrupt" ([SideStore#1757](https://github.com/SideStore/SideStore/issues/1757)). Incomplete downloads and HTTP errors now fail with a clear message, and dropped connections are retried up to 3 times. |
| `003-self-refresh-and-single-source.patch` | Refreshing LiveContainer itself failed with "FetchProvisioningProfilesOperation: context.targetAppBundle is nil" (and its icon was blank in My Apps) when SideStore's cached copy of the running app was missing, which happened after updating ([SideStore#1763](https://github.com/SideStore/SideStore/issues/1763)). SideStore now caches the running app again and refreshes it. It also removes, once, the sources that used to be built in (upstream LiveContainer's and SideStore's), so the fork's source is the only one Browse and Updates use for LiveContainer. |
| `004-safe-app-cache.patch` | The cause behind 003. SideStore re-caches its own app at every launch and records the new copy only once startup finishes, while a cleanup routine deletes copies the database doesn't list. Coming back to the foreground ran that cleanup before startup finished, deleting the new copy. The cleanup now waits for startup. Copies are written next to their final place and moved in, so one cut off when SideStore is closed is never mistaken for a complete copy. A cached copy whose version doesn't match is replaced, because the cache key only covers file names and sizes and two builds can match on those, which would make a refresh reinstall the older build. |
| `SideSign/001-clear-sign-in-rejection-error.patch` | When Apple's sign-in server answers with an HTML error page (HTTP 429 or 5xx), show what to do instead of "Invalid server response: unparseable format". |
| `SideSign/002-increased-memory-limit-for-free-teams.patch` | Enable the Increased Memory Limit capability for free accounts ([SideStore#1616](https://github.com/SideStore/SideStore/issues/1616)). From SideStore/SideSign pull request 4 by playportdev. |
| `SideSign/003-anisette-v3-identifier-base64.patch` | Send the device identifier to anisette v3 servers as Base64, as the protocol expects, instead of hex. Strict servers such as anisette-server-rs rejected hex with "InvalidIdentifier" ([SideStore#1778](https://github.com/SideStore/SideStore/issues/1778)). anisette data set up with hex keeps using hex until it's reset, so nobody signed in today is affected. |
| `SideSign/004-explain-error-22410.patch` | Error -22410 means the saved anisette data (adi.pb) was set up under an older device identity. Say to use Repair SideStore Sign-In instead of showing only the code. |

The Apple ID sign-in 503 fix is not a patch here: it lives in
[`SideStoreSupport/SideStoreHooks.m`](../SideStoreSupport/SideStoreHooks.m), so it also covers the
prebuilt SideStore used when the source build fails.

## Adding or changing a patch

1. Clone the source: `git clone --branch LiveContainerSupport --recurse-submodules https://github.com/LiveContainer/SideStore.git`
2. Make the change. For SideStore itself, run `git diff > NNN-short-name.patch` in the repository root.
   For SideSign, run it inside `Dependencies/SideSign` and put the file in `SideSign/`.
3. Add the file here, list it in the table above, and push. Any change in this folder makes the next
   build recompile SideStore instead of reusing the cached one.

## When a patch stops applying

If upstream SideStore changes make a patch fail, the build falls back to the prebuilt SideStore nightly
without these patches. The build run shows a warning, and the release notes, SideStore's update screen and
Copy Diagnostics in LiveContainer's Settings say the patches are missing. Update the patch against the new
source to fix it.
