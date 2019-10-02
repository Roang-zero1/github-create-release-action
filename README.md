# GitHub Action for Creating a Release on Tag push

Create a new GitHub release whenever a tag is pushed.

## Usage

The following basic workflow will create a release whenever any tag is pushed.

```yaml
on: push
name: Release
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - name: Create GitHub release
      uses: Roang-zero1/github-create-release-action@master
      with:
        version_regex: ^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Limiting versions and creating pre-releases

If only certain tags should create releases or some releases should be created as pre-release you can set regular expression to achieve this.
These regular expression are evaluated with GNU grep, so these regular expressions need to be compatible with it.
Regular expressions containing `\` need them to be escaped with `\\`.

* `version_regex` Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).
* `prerelease_regex` Any version matching this regular expression will be marked as pre-release. Disabled by default.

```yaml
- name: Create GitHub release
  uses: Roang-zero1/github-create-release-action@master
  with:
    version_regex: ^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+
    prerelease_regex: "^v2\\.[[:digit:]]+\\.[[:digit:]]+"
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Changelog parsing

This action makes it possible to extract the release description from a Markdown changelog.

By default the `CHANGELOG.md` file is searched for a `##` (h2) heading matching the tag text.

If it is found the section is passed as body to the release API.

If for example we release the tag `v1.0.0` with a `CHANGELOG.md` as follows:

```Markdown
# Changelog

## v1.0.0

Initial Release
```

Then the text `Initial Release` will be passed as body.
Markdown restrictions for release bodies still apply.

## Inputs

### `VERSION_REGEX`

Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).

### `PRERELEASE_REGEX`

Any version matching this regular expression will be marked as pre-release. Disabled by default.

### `DRAFT`

Create the releases as draft (`true|false [default: false]`). Existing will not be updated from released to draft.

### `UPDATE_EXISTING`

Controls whether an existing release should be updated with data from the latest push (`true|false [default: false]`).

### `CHANGELOG_FILE`

File that contains the Markdown formatted changelog. Defaults to `CHANGELOG.md`.

### `CHANGELOG_HEADING`

Heading level at which the tag headings exist. Defaults to `h2`, this parses headings at the markdown level `##`.

## Secrets

* `GITHUB_TOKEN` Provided by GitHub action, does not need to be set.
