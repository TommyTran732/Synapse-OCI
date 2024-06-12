# tommytran732/synapse

![Build, scan & push](https://github.com/tommytran732/Synapse-Docker/actions/workflows/build.yml/badge.svg)

[Synapse](https://github.com/matrix-org/synapse) is a [Matrix](https://matrix.org/) implementation written in Python.

### Notes
- Prebuilt images are available at `ghcr.io/tommytran732/synapse`.
- Don't trust random images: build yourself if you can.
- Always keep your software up-to-date: manage versions with [build-time variables](https://github.com/TommyTran732/Synapse-Docker/blob/main/Dockerfile#L1-L4).

### Features & usage
- Drop-in replacement for the [official image](https://github.com/matrix-org/synapse/tree/develop/docker).
- Unprivileged image: you should check your volumes permissions (eg `/data`), default UID/GID is 991.
- Based on the latest [Alpine](https://alpinelinux.org/) containers which provide more recent packages while having less attack surface.
- Daily rebuilds keeping the image up-to-date.
- Comes with the [hardened memory allocator](https://github.com/GrapheneOS/hardened_malloc) built from the latest tag, protecting against some heap-based buffer overflows.
- [Mjolnir module](https://github.com/matrix-org/mjolnir/blob/main/docs/synapse_module.md) support.

### Licensing
- v1.98.0 and prior are under the [Apache License](https://www.apache.org/licenses/LICENSE-2.0). 😇
- Versions after v1.98.0 are under AGPL 3 🤮 to comply with licensing changes by Element.