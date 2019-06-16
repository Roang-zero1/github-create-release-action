# GitHub Action for Factorio mod packaging

Create a new GitHub release whenever a tag is pushed.

## Usage

The following basic workflow will create a release whenever any tag is pushed.

```github-actions
workflow "Check & Release" {
  on = "push"
  resolves = ["Create GitHub release"]

  action "Create GitHub release" {
    uses = "Roang-zero1/github-create-release-action@master"
    secrets = [
      "GITHUB_TOKEN"
    ]
  }
}
```

### Limiting versions and creating pre-releases

If only certain tags should create releases or some releases should be created as pre-release you can set regular expression to achieve this.
These regular expression are evaluated with GNU grep, so these regexes need to be compatible with it.
Regular expressions containing `\` need them to be escaped with `\\`.

* `VERSION_REGEX` Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).
* `PRERELEASE_REGEX` Any version matching this regular expression will be marked as pre-release. Disabled by default.

```github-actions
action "Create GitHub release" {
  uses = "Roang-zero1/github-create-release-action@master"
  env = {
    VERSION_REGEX = "^v[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+",
    PRERELEASE_REGEX = "^v2\\.[[:digit:]]+\\.[[:digit:]]+",
  }
  secrets = [
    "GITHUB_TOKEN"
  ]
  needs = ["filter tag"]
}

```

### Switches

* `DRAFT` Create new releases as draft. Existing releases will not be unpublished.
* `UPDATE_EXISTING` Overwrite existing release data with the information from the tag

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

* `CHANGELOG_FILE` Select the file from where Changelog messages should be parsed
* `CHANGELOG_HEADING` Heading level at which the tag headings exist.

## Environment Variables

* `VERSION_REGEX` Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).
* `PRERELEASE_REGEX` Any version matching this regular expression will be marked as pre-release. Disabled by default.
* `DRAFT` Create the releases as draft (`true|false [default: false]`). Existing will not be updated from released to draft.
* `UPDATE_EXISTING` Controls whether an existing release should be updated with data from the latest push (`true|false [default: false]`).
* `CHANGELOG_FILE` File that contains the Markdown formatted changelog.
* `CHANGELOG_HEADING` Heading level at which the tag headings exist.

## Secrets

* `GITHUB_TOKEN` Provided by GitHub action, does not need to be set.
