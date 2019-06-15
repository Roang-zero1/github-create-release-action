# GitHub Action for Factorio mod packaging

Create a Factorio mod package that can be used locally or uploaded to the mod portal

## Usage

This action can be used with a repository contain a Factorio mod at base level.

All the relevant information for naming are taken from the `info.json`

The action can be used as follows:

```github-actions
action "package mod" {
  uses = "Roang-zero1/factorio-mod-package@main"
}
```

## Environment Variables

Regular expression below have to be in GNU grep extended regular expression format. `\` need to be escaped as `\\`.

* `VERSION_REGEX` Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).
* `PRERELEASE_REGEX` Any version matching this regular expression will be marked as pre-release. Disabled by default.
* `DRAFT` Create the releases as draft (`true|false [default: false]`). Existing will not be updated from released to draft.
* `UPDATE_EXISTING` Controls whether an existing release should be updated with data from the latest push (`true|false [default: false]`).
* `CHANGELOG_FILE` File that contains the Markdown formatted changelog.
* `CHANGELOG_HEADING` Heading level at which the tag headings exist.

## Secrets

* `GITHUB_TOKEN` Provided by GitHub action, does not need to be set.
