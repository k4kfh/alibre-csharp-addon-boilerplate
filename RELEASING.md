# Releasing a new version

A release takes one command once your changes are ready. You update the changelog and push a version tag, and CI
compiles, tests and publishes the release. [BUILD-SYSTEM.md](BUILD-SYSTEM.md#how-a-release-works) explains what
happens behind the scenes.

## Before your first release

You only need to do these once:

1. Run `scripts/new-project.ps1`, as described in the [README](README.md#start-your-add-on).
2. Follow [Setting up compiling in CI](BUILD-SYSTEM.md#setting-up-compiling-in-ci). Releases can't run without it.

On the repository's **Actions** tab, the latest run on `main` should show **Compile Add-On** and **Installer Test**
both passing. If **Compile Add-On** says it was skipped, CI can't see your secrets yet.

## 1. Try the build in Alibre

CI can't start Alibre, so this is the one check only you can do. Use the files from your latest run on `main`:

1. On the **Actions** tab, open the latest **ci** run on `main`.
2. Under **Artifacts**, download **test-release-assets**. These are kept for seven days.
3. Close Alibre Design, then install using the Setup program inside.
4. Start Alibre and try your add-on.

These files are labeled version `0.0.0`, because only a release gets a real version number. A copy installed this way
is replaced by the Setup program from your real release.

## 2. Choose a version number

Versions are written `MAJOR.MINOR.PATCH`, such as `1.4.2`, following [Semantic Versioning](https://semver.org):

| Change since the last release | Update | Example |
|---|---|---|
| Bug fixes only | `PATCH` | `1.4.2` to `1.4.3` |
| New features that don't break anything | `MINOR` | `1.4.2` to `1.5.0` |
| Changes that break how people use it | `MAJOR` | `1.4.2` to `2.0.0` |

Versions starting with `0.`, such as `0.1.0`, are published as pre-releases. That's a good way to start.

## 3. Update the changelog

In `CHANGELOG.md`, add a section for the new version at the top, using the date you're releasing. If you've been
collecting changes under `## [Unreleased]`, rename that heading:

```markdown
## [1.5.0] - 2026-11-07

### Added

- A button that does something useful.

### Fixed

- A crash when no document is open.
```

This text becomes the release notes, so write it for the people using your add-on. The release stops if there's no
section for that version.

## 4. Commit and push to `main`

```bash
git switch main
git add CHANGELOG.md
git commit -m "Prepare the 1.5.0 release"
git push origin main
```

Wait for this push's CI run to pass before going on, so you don't release a broken build.

## 5. Start the release

From the top of the repository, in PowerShell:

```powershell
./scripts/publish-release.ps1 -Version 1.5.0
```

The script first checks that:

- You have no uncommitted changes.
- You're on `main`, and it matches GitHub.
- The tag `v1.5.0` doesn't already exist.
- The changelog has a `1.5.0` section.

Then it creates and pushes the tag `v1.5.0`, which starts the release.

## 6. Watch it run

On the **Actions** tab, open the new **release** run, which takes a few minutes:

1. **Compile Add-On** builds your add-on with the version from the tag.
2. **Package, Test and Publish** builds the installer, tests it, and publishes the release.

## 7. Check the result

On the repository's **Releases** page, the new release should have the changelog text as its notes, and these files:

| File | What it's for |
|---|---|
| `<AddOnName>-Setup-v1.5.0.exe` | The installer most people should use |
| `<AddOnName>-v1.5.0-portable.zip` | Files and scripts for a manual install |
| `SHA256SUMS.txt` | Checksums, so people can verify their downloads |

Download the Setup program, install it over your previous version, and try the add-on in Alibre once more. In Alibre's
Add-On Manager, the add-on's description should show the new version.

## If something goes wrong

**A check in the script failed:** nothing has happened yet. Its message says what to fix. Fix that and run it again.

**The release run failed:** nothing was published. Open the failed step to see why.

- If it looks like a temporary GitHub problem, choose **Re-run failed jobs** on the run.
- If you need to change something, delete the tag, push your fix to `main`, and go back to step 5:

  ```bash
  git push origin --delete v1.5.0
  git tag -d v1.5.0
  ```

**You found a problem after publishing:** don't delete the tag and reuse its number, because people may already have
that version. Fix the problem and release a new version, such as `1.5.1`. You can edit the old release's notes on
the **Releases** page to warn people about it.
