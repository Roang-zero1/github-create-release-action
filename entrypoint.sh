#!/bin/sh

set -e
set -o pipefail

TAG=$(echo ${GITHUB_REF} | grep tags | grep -o "[^/]*$")

if [ -z $TAG ]; then
  echo "\e[31mEroor: This is not a tagged push.\e[0m"
  exit 1
fi

if ! echo "${TAG}" | grep -qE '^\d+\.\d+\.\d+$'; then
  echo "Bad version in tag, needs to be %u.%u.%u" 1>&2
  exit 1
fi

exit

export PACKAGE_NAME=$(jq -r .name info.json)
export PACKAGE_VERSION=$(jq -r .version info.json)
export PACKAGE_FULL_NAME=$PACKAGE_NAME\_$PACKAGE_VERSION
export PACKAGE_FILE="$PACKAGE_FULL_NAME.zip"

if ! [[ ${PACKAGE_VERSION} == "${TAG}" ]]; then
  echo "Tag version (${TAG}) doesn't match info.json version (${PACKAGE_VERSION}) (or info.json is invalid)." 1>&2
  exit 1
fi

if ! grep -q "\"$PACKAGE_VERSION\"" changelog.json; then
  echo "ERROR: Changelog is missing." 1>&2
  exit 1
fi

if ! grep -q "$PACKAGE_VERSION" changelog.txt; then
  echo "ERROR: Changelog was not compiled." 1>&2
  exit 1
fi

export DIST_DIR=dist

export FILE_PATH=$DIST_DIR/$PACKAGE_FILE

export FILESIZE=$(stat -c "%s" "${FILE_PATH}")

echo ${FILE_PATH} ${FILESIZE}

# Prepare the headers
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

RELEASE_ID=$PACKAGE_VERSION
FILENAME=$PACKAGE_FILE

echo "Verifying release"
HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
  -sSL \
  -H "${AUTH_HEADER}" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/${RELEASE_ID}")

HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

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

UPLOAD_URL=$(echo ${RELEASE_DATA} | jq -r .upload_url)
UPLOAD_URL=$(echo $UPLOAD_URL | sed "s/{?name,label}/?name=${FILENAME}/g")
echo "Uploading to $UPLOAD_URL"

# Upload the file
HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
  -sSL \
  -XPOST \
  -H "${AUTH_HEADER}" \
  -H "Content-Length: ${FILESIZE}" \
  -H "Content-Type: application/zip" \
  --upload-file "${FILE_PATH}" \
  "${UPLOAD_URL}")

# extract the body
JSON_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')

# extract the status
HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ ! $HTTP_STATUS -eq 201 ]; then
  echo "Upload failed ($HTTP_STATUS): $(echo $JSON_BODY | jq -r .message)"
  if $(echo $JSON_BODY | jq ".errors != null") -ne "false"; then
    echo "$(echo $JSON_BODY | jq -r .errors)"
  fi
  exit 1
else
  echo "Upload Completed"
fi
