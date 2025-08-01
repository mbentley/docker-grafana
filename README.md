# mbentley/grafana & mbentley/grafana-image-renderer

docker image for Grafana & Grafana image renderer; direct mirrors of `grafana/grafana` and `grafana/grafana-image-renderer` images

## Image Tags

### `mbentley/grafana`

* Daily updates:
    * `12.1`, `12.0`, `11.6,`, `11.5`, `11.4`, `11.3`, `11.2`, `11.1`, `11.0`, `10.4`
    * `12`, `11`, `10`
* Tagged but no further updates (no new upstream tags in about the last 6 months):
    * `10.3`, `10.2`, `10.1`, `10.0`, `9.5`, `9.4`, `9.3`, `9.2`, `9.1`, `9.0`, `8.5`, `8.4`, `8.3`, `8.2`, `8.1`, `8.0`
    * `9`

### `mbentley/grafana-image-renderer`

* Daily updates:
    * `4`, `4.0`
    * `3`, `3.12`
* Tagged but no further updates (no new upstream tags in the last 6 months):
    * `3.11`, `3.10`, `3.9`, `3.8`, `3.7`, `3.6`, `3.5`, `3.4`, `3.3`, `3.2`, `3.1`, `3.0`

I've found that the Grafana images published in the [grafana/grafana](https://hub.docker.com/r/grafana/grafana/) and [grafana/grafana-image-renderer](https://hub.docker.com/r/grafana/grafana-image-renderer/) repositories on Docker Hub only have specific tags (e.g. - there are no `major.minor` tags) which makes it a pain to stay up to date on the latest bugfix versions.  [These scripts](https://github.com/mbentley/docker-grafana) will run daily to just create manifest tags for the `linux/amd64` images by querying for the latest tag from GitHub, parsing it, and writing manifests with the `major.minor` version only.

This allows for using the `major.minor` versions so that you'll always have the latest bugfix versions, such as:

* `mbentley/grafana:8.1` is a manifest pointing to `grafana/grafana:8.1.5`
* `mbentley/grafana-image-renderer:3.2` is a manifest pointing `grafana/grafana-image-renderer:3.2.0`

These manifests always use the same image digest as the newest bugfix versions available for each.
