#!/usr/bin/env bash
# Fail when VERSION.md and CHANGELOG.md disagree.
# Usage: scripts/check_version.sh [vX.Y.Z]   (optional tag to match as well)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
semver='[0-9]+\.[0-9]+\.[0-9]+'
fail() { echo "check_version: $*" >&2; exit 1; }

version=$(grep -oE "^Current version: $semver\$" VERSION.md | awk '{print $3}') ||
    fail "VERSION.md has no 'Current version: X.Y.Z' line"

top=$(grep -oE "^## \[$semver\]" CHANGELOG.md | head -n 1 | tr -d '#[] ')
[ "$top" = "$version" ] ||
    fail "VERSION.md is $version but the newest CHANGELOG.md section is ${top:-missing}"

grep -q "^\[$version\]: " CHANGELOG.md ||
    fail "CHANGELOG.md has no link reference for [$version]"

if [ -n "${1:-}" ]; then
    [ "$1" = "v$version" ] || fail "tag $1 does not match VERSION.md ($version)"
    [ -n "$(scripts/changelog_section.sh "$version" | tr -d '[:space:]')" ] ||
        fail "CHANGELOG.md section $version is empty"
fi

echo "check_version: OK ($version)"
