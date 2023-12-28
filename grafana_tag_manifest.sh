#!/bin/bash

set -e

# set expected major.minor tags
EXPECTED_TAGS="9.4 9.5 10.0 10.1 10.2"

tag_manifest() {
  # get expected tag from first argument
  EXPECTED_TAG="${1}"

  # get latest full version from GitHub releases
  echo -n "Getting full version for ${EXPECTED_TAG} from GitHub releases..."
  GRAFANA_VERSION="$(echo "${GRAFANA_RELEASES}" | grep "^v${EXPECTED_TAG}\." | head -n 1)"

  # check to see if we received a grafana version from github tags
  if [ -z "${GRAFANA_VERSION}" ]
  then
    echo -e "error\nERROR: unable to retrieve the Grafana version from GitHub\n"
    exit 1
  fi

  echo "${GRAFANA_VERSION}"

  # check to see if this is a non-GA version
  if [ -n "$(echo "${GRAFANA_VERSION}" | awk -F '-' '{print $2}')" ]
  then
    echo -e "ERROR: non-GA version ${GRAFANA_VERSION} found!\n"
    exit 1
  fi

  # trim the tag for checking
  TRIMMED_TAG="$(echo "${GRAFANA_VERSION}" | awk -F 'v' '{print $2}')"

  # check to see if we got a trimmed tag
  if [ -z "${TRIMMED_TAG}" ]
  then
    echo -e "ERROR: TRIMMED_TAG not set!\n"
    exit 1
  fi

  # get digest for image
  echo -n "Getting digest for grafana/grafana:${TRIMMED_TAG} from Docker Hub..."
  TAG_DIGEST="$(docker buildx imagetools inspect --raw "grafana/grafana:${TRIMMED_TAG}" | jq -r '.manifests | .[] | select((.platform.architecture == "amd64") and (.platform.os == "linux")) | .digest')"

  # check to see if we got a tag digest
  if [ -z "${TAG_DIGEST}" ]
  then
    echo -e "error\nERROR: TAG_DIGEST not set!\n"
    exit 1
  fi

  echo "done"

  # get the target tag we want to use
  MAJOR_MINOR_TAG="$(echo "${GRAFANA_VERSION}" | awk -F 'v' '{print $2}' | awk -F '.' '{print $1"."$2}')"

  # check to see if we got a tag digest
  if [ -z "${MAJOR_MINOR_TAG}" ]
  then
    echo -e "ERROR: MAJOR_MINOR_TAG not set!\n"
    exit 1
  fi

  # check to see if the major.minor tag is no longer the value of EXPECTED_TAG
  if [ "${MAJOR_MINOR_TAG}" != "${EXPECTED_TAG}" ]
  then
    echo -e "ERROR: the major.minor tag is no longer ${EXPECTED_TAG}; we found ${TRIMMED_TAG}!\n"
    exit 1
  fi

  # create the new manifest and push the manifest to docker hub
  echo -n "Create new manifest and push to Docker Hub..."
  docker buildx imagetools create --progress plain -t "mbentley/grafana:${MAJOR_MINOR_TAG}" "grafana/grafana@${TAG_DIGEST}"

  echo -e "done\n"
}

# get last 100 release tags from GitHub; filter out beta releases & only v8, v9, or v10
GRAFANA_RELEASES="$(wget -q -O - "https://api.github.com/repos/grafana/grafana/tags?per_page=100" | jq -r '.[] | select(.name | contains("-") | not) | select((.name | startswith("v8")) or (.name | startswith("v9")) or (.name | startswith("v10"))) | .name' | sort --version-sort -r)"

# load env_parallel
. "$(command -v env_parallel.bash)"

# run multiple scans in parallel
# shellcheck disable=SC2086
env_parallel -j 4 tag_manifest ::: ${EXPECTED_TAGS}
