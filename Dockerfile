FROM alpine:3.9 as base

LABEL "com.github.actions.name"="GitHub Create Release"
LABEL "com.github.actions.description"="Create a GitHub release from a pushed Tag."
LABEL "com.github.actions.icon"="zap"
LABEL "com.github.actions.color"="white"

LABEL "repository"="https://github.com/Roang-zero1/github-create-release-action"
LABEL "homepage"="https://github.com/Roang-zero1/github-create-release-action"
LABEL "maintainer"="Roang_zero1 <lucas@brandstaetter.tech>"

RUN apk add --no-cache jq curl

RUN curl -s https://api.github.com/repos/dahlia/submark/releases/latest | \
    jq -r '.assets[] | select(.browser_download_url | contains("linux-x86_64")) \
    | .browser_download_url' | xargs curl -o /usr/local/bin/submark -sSL && \
    chmod +x /usr/local/bin/submark

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
