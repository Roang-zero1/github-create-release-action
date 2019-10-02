#!/bin/sh

# Backwards compability mapping
if [ -z $VERSION_REGEX ]; then :; else
  INPUT_VERSION_REGEX=$VERSION_REGEX
fi
if [ -z $PRERELEASE_REGEX ]; then :; else
  INPUT_PRERELEASE_REGEX=$PRERELEASE_REGEX
fi
if [ -z $DRAFT ]; then :; else
  INPUT_CREATE_DRAFT=$DRAFT
fi
if [ -z $UPDATE_EXISTING ]; then :; else
  INPUT_UPDATE_EXISTING=$UPDATE_EXISTING
fi
if [ -z $CHANGELOG_FILE ]; then :; else
  INPUT_CHANGELOG_FILE=$CHANGELOG_FILE
fi
if [ -z $CHANGELOG_HEADING ]; then :; else
  INPUT_CHANGELOG_HEADING=$CHANGELOG_HEADING
fi

set -euo pipefail

create_release_data() {
  RELEASE_DATA="{}"
  RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --arg tag $TAG '.tag_name = $tag')
  if [ -e $INPUT_CHANGELOG_FILE ]; then
    RELEASE_BODY=$(submark -O --$INPUT_CHANGELOG_HEADING $TAG $INPUT_CHANGELOG_FILE)
    if [ -n "${RELEASE_BODY}" ]; then
      RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --arg body "${RELEASE_BODY}" '.body = $body')
    fi
  fi
  RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --argjson value ${INPUT_CREATE_DRAFT} '.draft = $value')
  local PRERELEASE_VALUE="false"
  if [ -n "${INPUT_PRERELEASE_REGEX}" ]; then
    if echo "${TAG}" | grep -qE "$INPUT_PRERELEASE_REGEX"; then
      PRERELEASE_VALUE="true"
    fi
  fi
  RELEASE_DATA=$(echo ${RELEASE_DATA} | jq --argjson value $PRERELEASE_VALUE '.prerelease = $value')
}

TAG="$(echo ${GITHUB_REF} | grep tags | grep -o "[^/]*$" || true)"

if [ -z $TAG ]; then
  echo "This is not a tagged push." 1>&2
  exit 1
fi

if ! echo "${TAG}" | grep -qE "$INPUT_VERSION_REGEX"; then
  echo "Bad version in tag, needs to be adhere to the regex '$INPUT_VERSION_REGEX'" 1>&2
  exit 1
fi

AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
RELEASE_ID=$TAG

echo "Starting release process for tag '$TAG'"
HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
  -sSL \
  -H "${AUTH_HEADER}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/${RELEASE_ID}")

HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ $HTTP_STATUS -eq 200 ]; then
  echo "Existing release found"

  if [ "${INPUT_UPDATE_EXISTING}" == "true" ]; then
    echo "Updating existing release"
    create_release_data
    RECEIVED_DATA=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')

    RELEASE_DATA=$(echo $RELEASE_DATA | jq --argjson r_value $(echo $RECEIVED_DATA | jq '.draft') '.draft = if ( $r_value != true or .draft != true ) then false else true end ')
    RELEASE_DATA=$(echo $RELEASE_DATA | jq --argjson r_value $(echo $RECEIVED_DATA | jq '.draft') '.draft = if ( $r_value != true or .draft != true ) then false else true end ')

    HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
      -sSL \
      -X PATCH \
      -H "${AUTH_HEADER}" \
      -H "Content-Type: application/json" \
      -d "${RELEASE_DATA}" \
      "$(echo ${RECEIVED_DATA} | jq -r '.url')")

    HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    if [ $HTTP_STATUS -eq 200 ]; then
      echo "Release updated"
    else
      echo "Failed to update release ($HTTP_STATUS):"
      echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g' | jq '.errors'
      exit 1
    fi
  else
    echo "Updating disabled, finishing workflow"
  fi
else
  echo "Creating new release"
  create_release_data
  HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
    -sSL \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "${RELEASE_DATA}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases")

  HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  if [ $HTTP_STATUS -eq 201 ]; then
    echo "Release successfully created"
  else
    echo "Failed to create release ($HTTP_STATUS):"
    echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g' | jq '.errors'
    exit 1
  fi
fi
