#!/usr/bin/env bash
# Prepare a release: pick the next SemVer from Conventional Commits, add a
# CHANGELOG.md section and update VERSION.md. Nothing is committed or tagged.
# Usage: scripts/bump.sh [-n] [major|minor|patch|auto]
#   -n   dry run: print the new section and touch nothing
set -euo pipefail

dry=0
if [ "${1:-}" = "-n" ]; then dry=1; shift; fi
level="${1:-auto}"

cd "$(git rev-parse --show-toplevel)"
repo_url="https://github.com/orenatobr/.hammerspoon"
fail() { echo "bump: $*" >&2; exit 1; }

[ "$dry" = 1 ] || [ -z "$(git status --porcelain)" ] || fail "working tree is not clean"
scripts/check_version.sh >/dev/null

current=$(grep -oE '^Current version: [0-9]+\.[0-9]+\.[0-9]+' VERSION.md | awk '{print $3}')
prev_tag="v$current"
git rev-parse -q --verify "refs/tags/$prev_tag" >/dev/null || fail "tag $prev_tag not found (git fetch --tags)"

subjects=$(git log --no-merges --format=%s "$prev_tag..HEAD" | grep -v '^chore(release)' || true)
[ -n "$subjects" ] || fail "no commits since $prev_tag"
bodies=$(git log --no-merges --format=%b "$prev_tag..HEAD")

if [ "$level" = auto ]; then
    if echo "$subjects" | grep -qE '^[a-z]+(\([^)]*\))?!:' || echo "$bodies" | grep -q '^BREAKING CHANGE:'; then
        level="major"
    elif echo "$subjects" | grep -qE '^feat(\([^)]*\))?:'; then
        level="minor"
    elif echo "$subjects" | grep -qE '^(fix|perf|refactor|security)(\([^)]*\))?:'; then
        level="patch"
    else
        fail "only docs/test/chore/ci commits since $prev_tag, nothing to release"
    fi
fi

IFS=. read -r major minor patch <<EOF
$current
EOF
case "$level" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    *) fail "level must be major, minor, patch or auto" ;;
esac
next="$major.$minor.$patch"

# "type(scope): text (#N)" -> "- scope: text (#N)"
entries() { # $1 = type regex
    echo "$subjects" | grep -E "^($1)(\([^)]*\))?!?:" |
        sed -E 's/^[a-z]+\(([^)]*)\)!?: /- \1: /; s/^[a-z]+!?: /- /' || true
}
section=""
add() { # $1 = heading, $2 = type regex
    local body
    body=$(entries "$2")
    [ -z "$body" ] || section="$section### $1"$'\n\n'"$body"$'\n\n'
}
add Added 'feat'
add Changed 'perf|refactor'
add Fixed 'fix|security'
[ -n "$section" ] || section=$'### Changed\n\n- Maintenance release.\n\n'

block="## [$next] - $(date +%F)"$'\n\n'"$section"
if [ "$dry" = 1 ]; then
    echo "$current -> $next ($level)"; echo; printf '%s' "$block"; exit 0
fi

tmp=$(mktemp)
BLOCK="$block" awk -v next_v="$next" -v cur="$current" -v url="$repo_url" '
    /^## \[Unreleased\]/ { print; print ""; printf "%s", ENVIRON["BLOCK"]; skip = 1; next }
    skip && /^$/ { skip = 0; next }
    /^\[Unreleased\]: / {
        print "[Unreleased]: " url "/compare/v" next_v "...HEAD"
        print "[" next_v "]: " url "/compare/v" cur "...v" next_v
        next
    }
    { print }
' CHANGELOG.md > "$tmp"
cat "$tmp" > CHANGELOG.md
rm "$tmp"

tmp=$(mktemp)
sed -E "s/^Current version: .*/Current version: $next/" VERSION.md > "$tmp"
cat "$tmp" > VERSION.md
rm "$tmp"

scripts/check_version.sh
echo "bump: $current -> $next ($level). Review CHANGELOG.md, then commit 'chore(release): v$next'."
