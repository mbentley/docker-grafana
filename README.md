# mbentley/grafana & mbentley/grafana-image-renderer

docker image for Grafana & Grafana image renderer; direct mirrors of `grafana/grafana` and `grafana/grafana-image-renderer` images

## Image Tags

### `mbentley/grafana`

> [!NOTE]
> Grafana now has major.minor tags on Docker Hub so all of these are now archived (available but not updated).

* Tagged but no further updates (no longer supported):
    * `13`, `12`, `11`, `10`, `9`, `8`
    * `13.0`
    * `12.4`, `12.3`, `12.2`, `12.1`, `12.0`,
    * `11.6`, `11.5`, `11.4`, `11.3`, `11.2`, `11.1`, `11.0`
    * `10.4`, `10.3`, `10.2`, `10.1`, `10.0`
    * `9.5`, `9.4`, `9.3`, `9.2`, `9.1`, `9.0`
    * `8.5`, `8.4`, `8.3`, `8.2`, `8.1`, `8.0`

### `mbentley/grafana-image-renderer`

The `grafana-image-renderer_tag_manifest.sh` script automatically determines the latest `major.minor` version so it will update as soon as a new version is released.  There will be daily updates to the `major` tag which will correspond to the latest major release and to the latest `major.minor`.  All other previous `major.minor` tags will not get further updates as the Grafana Image Renderer doesn't backport anything to previous versions.

* Daily updates:
    * `5` - `5.x`

> [!NOTE]
> For a list of the latest releases from Grafana for the Image Renderer, see the releases page for [github.com/grafana/grafana-image-renderer](https://github.com/grafana/grafana-image-renderer/releases).
>
> For all image tags, see the [Docker Hub tag listing for `mbentley/grafana-image-renderer`](https://hub.docker.com/r/mbentley/grafana-image-renderer/tags).

I've found that the Grafana image renderer container images published in the [grafana/grafana-image-renderer](https://hub.docker.com/r/grafana/grafana-image-renderer/) repository on Docker Hub only has specific tags (e.g. - there are no `major.minor` tags) which makes it a pain to stay up to date on the latest bugfix versions.  [These scripts](https://github.com/mbentley/docker-grafana) will run daily to just create manifest tags for the `linux/amd64` images by querying for the latest tag from GitHub, parsing it, and writing manifests with the `major.minor` version only.

This allows for using either the `major` or `major.minor` versions so that you'll always have the latest bugfix versions, such as:

* `mbentley/grafana-image-renderer:3` is a manifest pointing `grafana/grafana-image-renderer:3.2.0`
* `mbentley/grafana-image-renderer:3.2` is a manifest pointing `grafana/grafana-image-renderer:3.2.0`

These manifests always use the same image digest as the newest bugfix versions available for each.
