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
