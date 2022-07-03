# CHANGELOG

## v2.3.1

- Fix bug in INPUT_RELEASE_TEXT check
- Improve action stability by pinning alpine package versions

## v2.3.0

- Add input parameter release_text which can be used instead of the parsed change log (Addresses [#5](https://github.com/Roang-zero1/github-create-release-action/issues/5))

## v2.2.0

- Add output parameter for parsed change log content (Fixes [#6](https://github.com/Roang-zero1/github-create-release-action/issues/6))
- Add output parameter for received release metadata (id, html_url, upload_url) (Fixes [#4](https://github.com/Roang-zero1/github-create-release-action/issues/4))
- Updated to latest submark version (Fixes [#1](https://github.com/Roang-zero1/github-create-release-action/issues/1))
- Fix parsing for tags with slashes (Pull Request #9)

## v2.1.0

- Add option to pass tag from another action (Fixes [#2](https://github.com/Roang-zero1/github-create-release-action/issues/2)).
- Add option to pass release title.

## v2.0.2

- Add additional output for the change log parsing process
- Add required fields to the input parameters

## v2.0.1

- Update `README.md`

## v2.0.0

- Add `action.yml` file
- Switch from using `env` to `inputs`

## v1.0.3

- Migrate to Actions V2 yml files

## v1.0.2

- Update workflow

## v1.0.1

- Change Action name to be unique

## v1.0.0

Initial Release

- Create release from tag
- Verify release version format with regular expression
- Create releases as draft
- Create pre-releases with regular expression matching
- Update existing releases
- Parse release body from a changelog file
