FROM alpine:3.9 as base

RUN apk add --no-cache jq curl

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN curl -s https://api.github.com/repos/dahlia/submark/releases/latest |  jq -r '.assets[] | select(.browser_download_url | contains("linux-x86_64"))  | .browser_download_url' | xargs curl -o /usr/local/bin/submark -sSL &&  chmod +x /usr/local/bin/submark

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
