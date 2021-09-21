#!/bin/bash

# get version from GitHub releases
echo -n "Getting version from GitHub releases..."
GRAFANA_VERSION="$(wget -q -O - https://api.github.com/repos/grafana/grafana/releases/latest | jq -r .tag_name)"

# check to see if we received a grafana version from github tags
if [ -z "${GRAFANA_VERSION}" ]
then
  echo -e "error\nERROR: unable to retrieve the Grafana version from GitHub"
  exit 1
fi

echo "done"

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

# clear any existing manifests, create the new manifest, and push the manifest
echo "Clearing existing manifests, create new manifest and push to Docker Hub..."
docker manifest rm "mbentley/grafana:${MAJOR_MINOR_TAG}"
docker manifest create "mbentley/grafana:${MAJOR_MINOR_TAG}" --amend "grafana/grafana@${TAG_DIGEST}"
docker manifest push "mbentley/grafana:${MAJOR_MINOR_TAG}"

echo "done"
