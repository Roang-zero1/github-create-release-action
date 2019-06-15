#!/bin/sh

set -euo pipefail

create_release_data() {
  local CHANGELOG_FILE=${CHANGELOG_FILE:-"CHANGELOG.md"}
  local CHANGELOG_HEADING=${CHANGELOG_HEADING:-"h2"}

  RELEASE_DATA="{}"
  RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --arg tag $TAG '.tag_name = $tag')
  if [ -e ${CHANGELOG_FILE} ]; then
    RELEASE_BODY=$(submark -O --$CHANGELOG_HEADING $TAG $CHANGELOG_FILE)
    if [ -n "${RELEASE_BODY}" ]; then
      RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --arg body "${RELEASE_BODY}" '.body = $body')
    fi
  fi
  DRAFT=${DRAFT:-"n"}
  if [ "${DRAFT}" == "y" ]; then
    RELEASE_DATA=$(echo ${RELEASE_DATA} | jq '.draft = true')
  fi
  PRERELEASE_REGEX=${PRERELEASE_REGEX:-""}
  if [ -n "${PRERELEASE_REGEX}" ]; then
    if echo "${TAG}" | grep -qE "$PRERELEASE_REGEX"; then
      RELEASE_DATA=$(echo ${RELEASE_DATA} | jq '.prerelease = true')
    fi
  fi
}

TAG="$(echo ${GITHUB_REF} | grep tags | grep -o "[^/]*$" || true)"

if [ -z $TAG ]; then
  echo "This is not a tagged push." 1>&2
  exit 1
fi

V_REGEX=${VERSION_REGEX:-"^.*$"}

echo $TAG

if ! echo "${TAG}" | grep -qE "$V_REGEX"; then
  echo "Bad version in tag, needs to be adhere to the regex '$V_REGEX'" 1>&2
  exit 1
fi

AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
RELEASE_ID=$TAG

echo "Verifying release"
HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
  -sSL \
  -H "${AUTH_HEADER}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/${RELEASE_ID}")

HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ $HTTP_STATUS -eq 200 ]; then
  echo "Release found"
else
  echo "Creating release"
  create_release_data
  HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
    -sSL \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "${RELEASE_DATA}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases")

  HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  if [ $HTTP_STATUS -eq 201 ]; then
    echo "Release created"
  else
    echo "Failed to create release ($HTTP_STATUS):"
    echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g' | jq '.errors'
    exit 1
  fi
fi
