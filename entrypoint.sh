#!/bin/sh

set -euo pipefail

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

RELEASE_DATA="{}"
RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --arg tag $TAG '.tag_name = $tag')
echo $RELEASE_DATA | jq
if [ $HTTP_STATUS -eq 200 ]; then
  echo "Release found"
  #TODO: Update existing release
fi

echo $HTTP_STATUS
exit 0
if [ $HTTP_STATUS -eq 200 ]; then
  echo "Release found"
  RELEASE_DATA=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
else
  echo "Creating release"
  HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
    -sSL \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "{\"tag_name\": \"${RELEASE_ID}\"}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases")

  HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  if [ $HTTP_STATUS -eq 201 ]; then
    echo "Release created"
    RELEASE_DATA=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
  else
    echo "Failed to create release"
    exit 1
  fi
fi
