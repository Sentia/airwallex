# Releasing the gem to RubyGems

How to publish a new version of `airwallex` to [rubygems.org/gems/airwallex](https://rubygems.org/gems/airwallex).

Releases are cut from `main` with Bundler's `rake release` task, which comes from `require "bundler/gem_tasks"` in the [Rakefile](../Rakefile). Run `bundle exec rake -T` to see it alongside `build` and `install`.

## Before your first release

You need:

- **Owner access to the gem on RubyGems.** Check with `gem owner airwallex`. An existing owner can add you with `gem owner airwallex --add you@sentia.com.au`.
- **MFA on your RubyGems account.** The gemspec sets `rubygems_mfa_required = "true"`, so pushes without an MFA code are refused.
- **A RubyGems session on your machine:**

  ```bash
  gem signin
  ```

  This only needs doing once per machine. The credentials are stored in `~/.gem/credentials`.
- **Push access to `Sentia/airwallex` on GitHub.** The release pushes a tag.

## 1. Prepare the release in your PR

Do this as part of the feature PR, or in a separate release PR.

1. **Bump the version** in [lib/airwallex/version.rb](../lib/airwallex/version.rb), following [Semantic Versioning](https://semver.org/):
   - patch (`0.12.0` → `0.12.1`) for bug fixes only
   - minor (`0.12.0` → `0.13.0`) for new features, or breaking changes while the gem is below 1.0
2. **Update `Gemfile.lock`** so it picks up the new version:

   ```bash
   bundle install
   ```

   Check that `Gemfile.lock` now shows `airwallex (X.Y.Z)`.
3. **Add a CHANGELOG entry.** Add a dated section under `## [Unreleased]` in [CHANGELOG.md](../CHANGELOG.md), using the same `### Added` / `### Fixed` / `### Changed` headings as earlier entries:

   ```markdown
   ## [Unreleased]

   ## [0.13.0] - 2026-10-20

   ### Added

   - ...
   ```

4. **Check everything passes:**

   ```bash
   bundle exec rake    # rspec + rubocop, the same as CI
   ```

5. **Merge the PR into `main`.** CI ([.github/workflows/main.yml](../.github/workflows/main.yml)) runs the same `rake` task on every PR and on `main`.

## 2. Release from `main`

```bash
git checkout main
git pull
git status          # must be clean
bundle exec rake    # one last check
bundle exec rake release
```

`rake release` does four things, in order:

1. Builds `pkg/airwallex-X.Y.Z.gem`.
2. Creates the git tag `vX.Y.Z`.
3. Pushes the current branch and the tag to `origin`.
4. Pushes the gem to RubyGems. It prompts for your MFA code here.

A successful run ends with:

```
Successfully registered gem: airwallex (X.Y.Z)
Pushed airwallex X.Y.Z to https://rubygems.org
```

## 3. Check the release

```bash
gem list airwallex --remote --exact     # should show the new version
git ls-remote --tags origin vX.Y.Z      # the tag should be on GitHub
```

It can take a few minutes before `bundle update` in other apps sees the new version.

Optionally, create a GitHub release for the tag, using that version's CHANGELOG notes as the description:

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --notes "<paste the CHANGELOG section>"
```

## 4. Update the apps that use the gem

In each consuming app (e.g. winboard-web):

1. If you tested against a local checkout with `gem "airwallex", path: "../airwallex"`, replace it with a version constraint, e.g. `gem "airwallex", "~> 0.13"`.
2. Update the gem:

   ```bash
   bundle update airwallex
   ```

3. Check `Gemfile.lock` shows the new version and run the app's tests.

## Releasing by hand

If `rake release` isn't an option (for example, you want to inspect the package first), the same steps by hand are:

```bash
gem build airwallex.gemspec                 # writes airwallex-X.Y.Z.gem
gem push airwallex-X.Y.Z.gem                # prompts for MFA
git tag vX.Y.Z
git push origin vX.Y.Z
```

To see exactly which files would ship, build the gem and list its contents:

```bash
gem build airwallex.gemspec && tar -xOf airwallex-X.Y.Z.gem data.tar.gz | tar -tz
```

## Troubleshooting

| Problem | Cause and fix |
|---|---|
| A new file is missing from the published gem | The gemspec only packages files tracked by git (`git ls-files`). Commit the file, then release again with a new version. |
| `There are files that need to be committed first.` | `rake release` refuses to run with uncommitted changes. Commit or stash them. |
| `Tag vX.Y.Z has already been created.` | Not an error: Bundler skips tagging and carries on with the push. If that version is already on RubyGems, the push then fails with "Repushing of gem versions is not allowed" (below). |
| `You have enabled multi-factor authentication. Please enter OTP code.` | Expected. Enter the code from your authenticator app. |
| `Access Denied. Please sign up for an account` or `You do not have permission to push to this gem` | You're not signed in, or not an owner. Run `gem signin`, and ask an existing owner to add you. |
| `Repushing of gem versions is not allowed` | Each version number can only be published once. Bump the version and release again. |
| The tag was pushed but the gem push failed (wrong MFA code, network error) | Fix the cause and run `bundle exec rake release` again. It sees the existing tag, skips it, and pushes the gem. Or push the already-built gem directly: `gem push pkg/airwallex-X.Y.Z.gem`. |

## Pulling a bad release

If a published version is broken, release a fixed version as soon as you can. You can also remove the broken version from RubyGems:

```bash
gem yank airwallex -v X.Y.Z
```

Yanking stops new installs of that version, but apps that already locked it in `Gemfile.lock` will fail to install it again. Let the app teams know, and never reuse a yanked version number.
