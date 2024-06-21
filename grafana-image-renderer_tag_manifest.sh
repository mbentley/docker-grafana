#!/bin/bash

set -e

# set expected major.minor tags
EXPECTED_MAJOR_MINOR_TAGS="3.9 3.10 3.11"

# set expected major tags from the major.minor list
EXPECTED_MAJOR_TAGS="$(echo "${EXPECTED_MAJOR_MINOR_TAGS}" | tr " " "\n" | awk -F '.' '{print $1}' | sort -nu | xargs)"

tag_manifest() {
  # get expected tag from first argument
  EXPECTED_TAG="${1}"

  # get latest full version from GitHub releases
  echo -n "Getting full version for ${EXPECTED_TAG} from GitHub releases..."
  GRAFANA_VERSION="$(echo "${GRAFANA_RELEASES}" | grep "^v${EXPECTED_TAG}\." | head -n 1)"

  # check to see if we received a grafana version from github tags
  if [ -z "${GRAFANA_VERSION}" ]
  then
    echo -e "error\nERROR: unable to retrieve the Grafana Image Renderer version from GitHub\n"
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

  # see if we want a MAJOR.MINOR or just MAJOR tag
  if [ "${MAJOR_ONLY}" = "true" ]
  then
    # major only; get the destination tag we want to use
    DESTINATION_TAG="$(echo "${GRAFANA_VERSION}" | awk -F 'v' '{print $2}' | awk -F '.' '{print $1}')"
  else
    # major.minor; get the destination tag we want to use
    DESTINATION_TAG="$(echo "${GRAFANA_VERSION}" | awk -F 'v' '{print $2}' | awk -F '.' '{print $1"."$2}')"
  fi

  # check to see if we got a tag digest
  if [ -z "${DESTINATION_TAG}" ]
  then
    echo -e "ERROR: DESTINATION_TAG not set!\n"
    exit 1
  fi

  # check to see if the major.minor tag is no longer the value of EXPECTED_TAG
  if [ "${DESTINATION_TAG}" != "${EXPECTED_TAG}" ]
  then
    echo -e "ERROR: the major.minor tag is no longer ${EXPECTED_TAG}; we found ${TRIMMED_TAG}!\n"
    exit 1
  fi

  # create the new manifest and push the manifest to docker hub
  echo -n "Create new manifest and push to Docker Hub..."
  docker buildx imagetools create --progress plain -t "mbentley/grafana-image-renderer:${DESTINATION_TAG}" "grafana/grafana-image-renderer:${TRIMMED_TAG}"

  echo -e "done\n"
}


# get last 100 release tags from GitHub; filter out beta releases
GRAFANA_RELEASES="$(wget -q -O - "https://api.github.com/repos/grafana/grafana-image-renderer/tags?per_page=100" | jq -r '.[] | select(.name | contains("-") | not) | select(.name | startswith("v3")) | .name' | sort --version-sort -r)"

# load env_parallel
. "$(command -v env_parallel.bash)"

# run multiple tags in parallel
# shellcheck disable=SC2086
env_parallel -j 4 tag_manifest ::: ${EXPECTED_MAJOR_MINOR_TAGS}

# run multiple tags in parallel
export MAJOR_ONLY=true
# shellcheck disable=SC2086
env_parallel -j 4 tag_manifest ::: ${EXPECTED_MAJOR_TAGS}
