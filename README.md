# GitHub Action for Creating a Release on Tag push

Creates a new GitHub release whenever a tag is pushed.

## Example Usage

The following basic workflow will create a release whenever any tag is pushed that matches the version_regex.

```yaml
name: Release

on:
  push:
    tags:
      - "v[0-9]+.[0-9]+.[0-9]+"

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Create GitHub release
        uses: Roang-zero1/github-create-release-action@v3
        with:
          version_regex: ^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Limiting versions and creating pre-releases

If only certain tags should create releases or some releases should be created as pre-release you can set regular expression to achieve this.
These regular expression are evaluated with GNU grep, so these regular expressions need to be compatible with it.
Regular expressions containing `\` need them to be escaped with `\\`.

- `version_regex` Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).
- `prerelease_regex` Any version matching this regular expression will be marked as pre-release. Disabled by default.

```yaml
- name: Create GitHub release
  uses: Roang-zero1/github-create-release-action@v3
  with:
    version_regex: ^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+
    prerelease_regex: "^v2\\.[[:digit:]]+\\.[[:digit:]]+"
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Passing a tag to not rely on manual tag pushes

If you want to create a tag automatically and create the release in the same workflow you can set `created_tag` to achieve this.
This allows you to create a fully automated release in one workflow file (workaround because one workflow/action can not trigger another workflow/action).  
The example below uses `K-Phoen/semver-release-action` to create the tag whenever a pull request is closed, merged, and the head_ref starts with RC.
After the tag is created it is passed to the create-release-action via the CREATED_TAG env variable using the output of the `semver-release-action`.

```yaml
on:
  pull_request:
    types: closed

jobs:
  build:
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged && startsWith(github.head_ref, 'RC')
    steps:
      - uses: actions/checkout@v3
      - name: Tag and prepare release
        id: tag_and_prepare_release
        uses: K-Phoen/semver-release-action@v1.3.1
        with:
          release_branch: master
          release_strategy: tag
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Upload release notes
        if: steps.tag_and_prepare_release.outputs.tag
        uses: Roang-zero1/github-create-release-action@v3
        with:
          created_tag: ${{ steps.tag_and_prepare_release.outputs.tag }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Using the tag message as release body

If you have tag messages that you want to use as a release body you can pass them from the workflow with the `release_text` parameter.

```yaml
- uses: actions/checkout@v3
- name: "Refresh tags"
  id: tag
  run: git fetch --tags --force # Is currently required for v3 due to https://github.com/actions/checkout/issues/290
- uses: ericcornelissen/git-tag-annotation-action@v3
  id: tag-data
- name: Create GitHub release
  uses: Roang-zero1/github-create-release-action@v3
  with:
    version_regex: ^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+
    release_text: ${{ steps.tag-data.outputs.git-tag-annotation }}
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Change log parsing

This action makes it possible to extract the release description from a Markdown change log.

By default, the `CHANGELOG.md` file is searched for a `##` (h2) heading matching the tag text.

If it is found the section is passed as body to the release API.

If for example we release the tag `v1.0.0` with a `CHANGELOG.md` as follows:

```Markdown
# Changelog

## v1.0.0

Initial Release
```

Then the text `Initial Release` will be passed as body.
Markdown restrictions for release bodies still apply.

_Parsed change logs with will have the new lines (/r, /n) and percent symbols (%) escaped._

## Inputs

### `version_regex`

Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).

### `prerelease_regex`

Any version matching this regular expression will be marked as pre-release. Disabled by default.

### `create_draft`

Create the releases as draft (`true|false [default: false]`). Existing will not be updated from released to draft.

### `update_existing`

Controls whether an existing release should be updated with data from the latest push (`true|false [default: false]`).

### `created_tag`

Allows to pass an already created tag.

### `release_title`

Allows to pass a release title.

### `changelog_file`

File that contains the Markdown formatted change log. Defaults to `CHANGELOG.md`.

### `changelog_heading`

Heading level at which the tag headings exist. Defaults to `h2`, this parses headings at the markdown level `##`.

## Outputs

### `id`

ID number of the created or updated release.

### `html_url`

HTML access URL for the created or updated release.

### `upload_url`

Artifact upload URL for the created or updated release.

### `changelog`

Text of the parsed change log entry.

## Secrets

- `GITHUB_TOKEN` Provided by GitHub action, does not need to be set.
