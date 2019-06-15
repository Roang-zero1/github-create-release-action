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

* `VERSION_REGEX` Regular expression to verify that the version is in a correct format. Defaults to `.*` (accept everything).
* `DRAFT` Create the releases as draft (`y|n [default: n]`). Existing will not be updated from released to draft.
* `UPDATE_EXISTING` Controls whether an existing release should be updated with data from the latest push (`y|n [default: n]`).

## Secrets

* `GITHUB_TOKEN` Provided by GitHub action, does not need to be set.
