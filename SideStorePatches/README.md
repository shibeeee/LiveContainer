# SideStore patches

Fork builds compile LiveContainer's SideStore fork
(`LiveContainer/SideStore`, branch `LiveContainerSupport`) from source and apply every
`*.patch` file in this folder, in name order, with `git apply --3way`.

To make a patch, change a checkout of that branch, then run `git diff > NNN-short-name.patch`
from its root and put the file here. Patches for SideSign (the signing library at
`Dependencies/SideSign`) go in `SideSign/` and are made with `git diff` inside that folder. If a patch stops applying after upstream changes,
the fork build falls back to the prebuilt SideStore nightly and shows a warning in the run summary.

## Current patches

- `SideSign/001-clear-sign-in-rejection-error.patch`: when Apple's sign-in server answers with an
  HTML error page (HTTP 429 or 5xx), show what to do instead of "unparseable format".
- `SideSign/002-increased-memory-limit-for-free-teams.patch`: enable the Increased Memory Limit
  capability for free accounts (SideStore issue 1616). From SideStore/SideSign pull request 4 by playportdev.
