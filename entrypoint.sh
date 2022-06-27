#!/bin/sh

# Backwards compatibility mapping
if [ -z "$VERSION_REGEX" ]; then :; else
  INPUT_VERSION_REGEX=$VERSION_REGEX
fi
if [ -z "$PRERELEASE_REGEX" ]; then :; else
  INPUT_PRERELEASE_REGEX=$PRERELEASE_REGEX
fi
if [ -z "$DRAFT" ]; then :; else
  INPUT_CREATE_DRAFT=$DRAFT
fi
if [ -z "$UPDATE_EXISTING" ]; then :; else
  INPUT_UPDATE_EXISTING=$UPDATE_EXISTING
fi
if [ -z "$CHANGELOG_FILE" ]; then :; else
  INPUT_CHANGELOG_FILE=$CHANGELOG_FILE
fi
if [ -z "$CHANGELOG_HEADING" ]; then :; else
  INPUT_CHANGELOG_HEADING=$CHANGELOG_HEADING
fi

set -euo pipefail

set_tag() {
  if [ -n "${INPUT_CREATED_TAG}" ]; then
    TAG=${INPUT_CREATED_TAG}
  else
    TAG="$(echo "${GITHUB_REF}" | grep tags | sed --regexp-extended 's/^\w+\/\w+\///g' || true)"
  fi
}

create_release_data() {
  RELEASE_DATA="{}"
  RELEASE_DATA=$(echo "${RELEASE_DATA}" | jq --arg tag "$TAG" '.tag_name = $tag')
  if [ -e "$INPUT_CHANGELOG_FILE" ]; then
    RELEASE_BODY=$(submark -O --"$INPUT_CHANGELOG_HEADING" "$TAG" "$INPUT_CHANGELOG_FILE")
    if [ -n "${RELEASE_BODY}" ]; then
      echo "::notice::Changelog entry found, adding to release"
      echo "::set-output name=changelog::${RELEASE_BODY}"
      RELEASE_DATA=$(echo "${RELEASE_DATA}" | jq --arg body "${RELEASE_BODY}" '.body = $body')
    else
      echo "::warning::Changelog entry not found!"
    fi
  else
    echo "::warning::Changelog file not found! ($INPUT_CHANGELOG_FILE)"
  fi
  RELEASE_DATA=$(echo "${RELEASE_DATA}" | jq --argjson value "${INPUT_CREATE_DRAFT}" '.draft = $value')
  local PRERELEASE_VALUE="false"
  if [ -n "${INPUT_PRERELEASE_REGEX}" ]; then
    if echo "${TAG}" | grep -qE "$INPUT_PRERELEASE_REGEX"; then
      PRERELEASE_VALUE="true"
    fi
  fi
  RELEASE_DATA=$(echo "${RELEASE_DATA}" | jq --argjson value $PRERELEASE_VALUE '.prerelease = $value')
  if [ -n "${INPUT_RELEASE_TITLE}" ]; then
    RELEASE_DATA=$(echo "${RELEASE_DATA}" | jq --arg name "${INPUT_RELEASE_TITLE}" '.name = $name')
  fi
}

set_tag

if [ -z "$TAG" ]; then
  echo "::error::This is not a tagged push." 1>&2
  exit 1
fi

if ! echo "${TAG}" | grep -qE "$INPUT_VERSION_REGEX"; then
  echo "::error::Bad version in tag, needs to be adhere to the regex '$INPUT_VERSION_REGEX'" 1>&2
  exit 1
fi

AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
RELEASE_ID=$TAG

echo "Starting release process for tag '$TAG'"
HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
  -sSL \
  -H "${AUTH_HEADER}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/${RELEASE_ID}")

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "Existing release found"

  if [ "${INPUT_UPDATE_EXISTING}" == "true" ]; then
    echo "Updating existing release"
    create_release_data
    RECEIVED_DATA=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')

    RELEASE_DATA=$(echo "$RELEASE_DATA" | jq --argjson r_value "$(echo "$RECEIVED_DATA" | jq '.draft')" '.draft = if ( $r_value != true or .draft != true ) then false else true end ')

    RESPONSE="$(curl \
      --write-out "%{http_code}" \
      --silent \
      --show-error \
      --location \
      --request PATCH \
      --header "${AUTH_HEADER}" \
      --header "Content-Type: application/json" \
      --data "${RELEASE_DATA}" \
      "$(echo "${RECEIVED_DATA}" | jq -r '.url')")"

    HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
    CONTENT=$(echo "$RESPONSE" | sed "$ d" | jq --args)

    if [ "$HTTP_STATUS" -eq 200 ]; then
      echo "::notice::Release updated"
      echo "::set-output name=id::$(echo "$CONTENT" | jq ".id")"
      echo "::set-output name=html_url::$(echo "$CONTENT" | jq ".html_url")"
      echo "::set-output name=upload_url::$(echo "$CONTENT" | jq ".upload_url")"
    else
      echo "::error::Failed to update release ($HTTP_STATUS):"
      echo "$CONTENT" | jq ".errors"
      exit 1
    fi
  else
    echo "::notice::Updating disabled, finishing workflow"
  fi
else
  echo "Creating new release"
  create_release_data
  RESPONSE=$(curl \
    --write-out "%{http_code}" \
    --silent \
    --show-error \
    --location \
    --header "${AUTH_HEADER}" \
    --header "Content-Type: application/json" \
    --data "${RELEASE_DATA}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases")

  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
  CONTENT=$(echo "$RESPONSE" | sed "$ d" | jq --args)

  if [ "$HTTP_STATUS" -eq 201 ]; then
    echo "::notice::Release successfully created"
    echo "::set-output name=id::$(echo "$CONTENT" | jq ".id")"
    echo "::set-output name=html_url::$(echo "$CONTENT" | jq ".html_url")"
    echo "::set-output name=upload_url::$(echo "$CONTENT" | jq ".upload_url")"
  else
    echo "::error::Failed to update release ($HTTP_STATUS):"
    echo "$CONTENT" | jq ".errors"
    exit 1
  fi
fi
