# mbentley/grafana & mbentley/grafana-image-renderer

docker image for Grafana & Grafana image renderer; direct mirrors of `grafana/grafana` and `grafana/grafana-image-renderer` images

I've found that the Grafana images published in the [grafana/grafana](https://hub.docker.com/r/grafana/grafana/) and [grafana/grafana-image-renderer](https://hub.docker.com/r/grafana/grafana-image-renderer/) repositories on Docker Hub only have specific tags (e.g. - there are no `major.minor` tags) which makes it a pain to stay up to date on the latest bugfix versions.  This script will run daily to just create a manifest tag for the `linux/amd64` images by querying for the latest tag from GitHub and parsing it.

This allows for using the `major.minor` versions so that you'll always have the latest bugfix versions, such as:

* mbentley/grafana:8.1
* mbentley/grafana-image-renderer:3.2

These manifests always use the same image digest as the newest bugfix versions available for each.
