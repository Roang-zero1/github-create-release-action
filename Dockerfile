FROM alpine:3.16 as base

RUN apk add --no-cache jq=1.6-r1 curl=7.83.1-r2

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN curl -s https://api.github.com/repos/dahlia/submark/releases/tags/0.3.1 |  jq -r '.assets[] | select(.browser_download_url | contains("linux-x86_64"))  | .browser_download_url' | xargs curl -o /usr/local/bin/submark -sSL &&  chmod +x /usr/local/bin/submark

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
