workflow "Check & Release" {
  on = "push"
  resolves = ["Create GitHub release"]
}

action "lint" {
  uses = "docker://cdssnc/docker-lint-github-action"
  args = "--ignore DL3007 --ignore DL3018"
}

action "shfmt" {
  uses = "roang-zero1/actions/shfmt@master"
  secrets = ["GITHUB_TOKEN"]
  env = {
    SHFMT_ARGS="-i 2 -ci",
  }
}

action "filter tag" {
  uses = "actions/bin/filter@3c0b4f0e63ea54ea5df2914b4fabf383368cd0da"
  args = "tag"
  needs = [
    "lint",
    "shfmt",
  ]
}

action "Create GitHub release" {
  uses = "Roang-zero1/github-create-release-action@master"
  env = {
    VERSION_REGEX = "^v[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+",
    UPDATE_EXISTING = "y",
  }
  secrets = [
    "GITHUB_TOKEN"
  ]
  needs = ["filter tag"]
}
