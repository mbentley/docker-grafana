#!/bin/bash

set -e

# set expected major.minor tags
EXPECTED_MAJOR_MINOR_TAGS="9.5 10.0 10.1 10.2 10.3 10.4 11.0"

# set expected major tags from the major.minor list
EXPECTED_MAJOR_TAGS="$(echo "${EXPECTED_MAJOR_MINOR_TAGS}" | tr " " "\n" | awk -F '.' '{print $1}' | sort -nu | xargs)"

# combine list of all expected tags
ALL_EXPECTED_TAGS="${EXPECTED_MAJOR_MINOR_TAGS} ${EXPECTED_MAJOR_TAGS}"

tag_manifest() {
  # set this again for use in parallel
  set -e

  # get expected tag from first argument
  EXPECTED_TAG="${1}"

  # test if major.minor or just major
  if ! echo "${EXPECTED_TAG}" | grep -q '\.'
  then
    # major only; set variable
    MAJOR_ONLY=true
  fi

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
  docker buildx imagetools create --progress plain -t "mbentley/grafana:${DESTINATION_TAG}" "grafana/grafana@${TAG_DIGEST}"

  echo -e "done\n"
}

# get last 100 release tags from GitHub; filter out beta releases & only v9, v10, or v11
GRAFANA_RELEASES="$(wget -q -O - "https://api.github.com/repos/grafana/grafana/tags?per_page=100" | jq -r '.[] | select(.name | contains("-") | not) | select((.name | startswith("v9")) or (.name | startswith("v10")) or (.name | startswith("v11"))) | .name' | sort --version-sort -r | grep -vE '(v10.3.8)')"

# load env_parallel
. "$(command -v env_parallel.bash)"

# run multiple tags in parallel
# shellcheck disable=SC2086
env_parallel --halt soon,fail=1 -j 4 tag_manifest ::: ${ALL_EXPECTED_TAGS}
