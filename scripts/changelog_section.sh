#!/usr/bin/env bash
# Print the body of one CHANGELOG.md section (without its heading).
# Usage: scripts/changelog_section.sh X.Y.Z
set -euo pipefail

version="${1:?usage: changelog_section.sh X.Y.Z}"
cd "$(git rev-parse --show-toplevel)"

awk -v v="$version" '
    /^## \[/ { if (on) exit; on = index($0, "## [" v "]") == 1; next }
    /^\[[^]]+\]: / { if (on) exit }
    on { print }
' CHANGELOG.md
