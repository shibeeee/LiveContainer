# SideStore patches

Fork builds compile LiveContainer's SideStore fork
(`LiveContainer/SideStore`, branch `LiveContainerSupport`) from source and apply every
`*.patch` file in this folder, in name order, with `git apply --3way`.

To make a patch, change a checkout of that branch, then run `git diff > NNN-short-name.patch`
from its root and put the file here. If a patch stops applying after upstream changes,
the fork build falls back to the prebuilt SideStore nightly and shows a warning in the run summary.
