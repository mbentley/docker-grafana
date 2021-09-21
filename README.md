# mbentley/grafana

docker image for Grafana; direct mirror of grafana/grafana images

I've found that the Grafana images published in the [grafana/grafana](https://hub.docker.com/r/grafana/grafana/) and [grafana/grafana-image-renderer](https://hub.docker.com/r/grafana/grafana-image-renderer/) repositories on Docker Hub only have specific tags (e.g. - there are no `major.minor` tags) which makes it a pain to stay up to date on the latest bugfix versions.  This script will run daily to just create a manifest tag for the `linux/amd64` images by querying for the latest tag from GitHub and parsing it.
