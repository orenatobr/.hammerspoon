# Version

Current version: 0.3.0

This file is the single source of truth for the project version. Do not edit
it by hand: `scripts/bump.sh` updates it together with `CHANGELOG.md`.

## Versioning policy

The project follows [Semantic Versioning 2.0.0](https://semver.org/) and
[Conventional Commits](https://www.conventionalcommits.org/). The bump level
comes from the commit subjects (PR titles, because PRs are squash merged)
since the last tag:

| Commit                                   | Bump  |
| ---------------------------------------- | ----- |
| `type!:` or a `BREAKING CHANGE:` footer  | major |
| `feat`                                   | minor |
| `fix`, `perf`, `refactor`, `security`    | patch |
| `docs`, `test`, `chore`, `ci`, `build`   | none  |

While the major version is 0, a breaking change may be released as a minor
bump. Pass the level to `scripts/bump.sh` explicitly in that case.

## Release process

Every step goes through a pull request, because `main` requires review and a
green CI.

1. Branch from an up to date `main`: `git switch -c release/next`.
2. Run `scripts/bump.sh` (add `-n` for a dry run). It picks the level from the
   commits, moves them into a new `CHANGELOG.md` section and updates this file.
   Pass `major`, `minor` or `patch` to override the level.
3. Review the generated section and edit the wording if needed.
4. Commit as `chore(release): vX.Y.Z`, open the PR and merge it (squash).
5. From the merge commit on `main`, push the tag by hand:

   ```sh
   git switch main && git pull
   git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z
   ```

6. The `Release` workflow checks that the tag matches this file, that the
   commit is on `main`, and publishes the GitHub release using the matching
   `CHANGELOG.md` section as notes.

CI also runs `scripts/check_version.sh` on every PR, so this file and the
changelog cannot drift apart.

A published tag is never moved or deleted. A bad release is fixed by a new
patch version.
