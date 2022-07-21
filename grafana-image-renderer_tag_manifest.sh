#!/bin/bash

set -e

# set expected major.minor tags
EXPECTED_TAGS="3.4 3.5"

tag_manifest() {
  # get expected tag from first argument
  EXPECTED_TAG="${1}"

  # get latest full version from GitHub releases
  echo -n "Getting full version for ${EXPECTED_TAG} from GitHub releases..."
  GRAFANA_VERSION="$(echo "${GRAFANA_RELEASES}" | grep "^v${EXPECTED_TAG}\." | head -n 1)"

  # check to see if we received a grafana version from github tags
  if [ -z "${GRAFANA_VERSION}" ]
  then
    echo -e "error\nERROR: unable to retrieve the Grafana Image Renderer version from GitHub"
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
  docker manifest rm "mbentley/grafana-image-renderer:${MAJOR_MINOR_TAG}" 2>/dev/null || true
  docker manifest create "mbentley/grafana-image-renderer:${MAJOR_MINOR_TAG}" --amend "grafana/grafana-image-renderer:${TRIMMED_TAG}"
  docker manifest push --purge "mbentley/grafana-image-renderer:${MAJOR_MINOR_TAG}"

  echo -e "done\n"
}


# get last 100 release tags from GitHub; filter out beta releases
GRAFANA_RELEASES="$(wget -q -O - "https://api.github.com/repos/grafana/grafana-image-renderer/tags?per_page=100" | jq -r '.[] | select(.name | contains("-beta") | not) | select(.name | startswith("v3")) | .name' | sort --version-sort -r)"

# load env_parallel
. "$(which env_parallel.bash)"

# run multiple scans in parallel
# shellcheck disable=SC2086
env_parallel -j 4 tag_manifest ::: ${EXPECTED_TAGS}
