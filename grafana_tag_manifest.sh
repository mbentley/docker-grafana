#!/bin/bash

set -e

# set expected major.minor tags
EXPECTED_TAGS="8.1 8.2 8.3"

# get last 100 release tags from GitHub; filter out beta releases
GRAFANA_RELEASES="$(wget -q -O - "https://api.github.com/repos/grafana/grafana/tags?per_page=100" | jq -r '.[] | select(.name | contains("-beta") | not) | select(.name | startswith("v8")) | .name')"

# loop through each tag
for EXPECTED_TAG in ${EXPECTED_TAGS}
do
  # get latest full version from GitHub releases
  echo -n "Getting full version for ${EXPECTED_TAG} from GitHub releases..."
  GRAFANA_VERSION="$(echo "${GRAFANA_RELEASES}" | grep "^v${EXPECTED_TAG}." | head -n 1)"

  # check to see if we received a grafana version from github tags
  if [ -z "${GRAFANA_VERSION}" ]
  then
    echo -e "error\nERROR: unable to retrieve the Grafana version from GitHub"
    exit 1
  fi

  echo "${GRAFANA_VERSION}"

  # check to see if this is a non-GA version
  if [ -n "$(echo "${GRAFANA_VERSION}" | awk -F '-' '{print $2}')" ]
  then
    echo "ERROR: non-GA version ${GRAFANA_VERSION} found!"
    exit 1
  fi

  # trim the tag for checking
  TRIMMED_TAG="$(echo "${GRAFANA_VERSION}" | awk -F 'v' '{print $2}')"

  # check to see if we got a trimmed tag
  if [ -z "${TRIMMED_TAG}" ]
  then
    echo "ERROR: TRIMMED_TAG not set!"
    exit 1
  fi

  # get digest for image
  echo -n "Getting digest for grafana/grafana:${TRIMMED_TAG} from Docker Hub..."
  TAG_DIGEST="$(docker manifest inspect "grafana/grafana:${TRIMMED_TAG}" | jq -r '.manifests | .[] | select((.platform.architecture == "amd64") and (.platform.os == "linux")) | .digest')"

  # check to see if we got a tag digest
  if [ -z "${TAG_DIGEST}" ]
  then
    echo -e "error\nERROR: TAG_DIGEST not set!"
    exit 1
  fi

  echo "done"

  # get the target tag we want to use
  MAJOR_MINOR_TAG="$(echo "${GRAFANA_VERSION}" | awk -F 'v' '{print $2}' | awk -F '.' '{print $1"."$2}')"

  # check to see if we got a tag digest
  if [ -z "${MAJOR_MINOR_TAG}" ]
  then
    echo "ERROR: MAJOR_MINOR_TAG not set!"
    exit 1
  fi

  # check to see if the major.minor tag is no longer the value of EXPECTED_TAG
  if [ "${MAJOR_MINOR_TAG}" != "${EXPECTED_TAG}" ]
  then
    echo "ERROR: the major.minor tag is no longer ${EXPECTED_TAG}; we found ${TRIMMED_TAG}!"
    exit 1
  fi

  # clear any existing manifests, create the new manifest, and push the manifest
  echo "Clearing existing manifests, create new manifest and push to Docker Hub..."
  docker manifest rm "mbentley/grafana:${MAJOR_MINOR_TAG}" || true
  docker manifest create "mbentley/grafana:${MAJOR_MINOR_TAG}" --amend "grafana/grafana@${TAG_DIGEST}"
  docker manifest push --purge "mbentley/grafana:${MAJOR_MINOR_TAG}"

  echo -e "done\n"
done
