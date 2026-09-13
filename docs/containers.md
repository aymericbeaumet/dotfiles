# Local containers

Use Colima with the Docker runtime on macOS and native Docker Engine on Linux. The Docker CLI
and Compose/Buildx plugins belong in mise on both machines. Colima belongs in `Brewfile` as an
explicit exception for macOS VM integration; Homebrew installs its Lima dependency. Docker's
macOS Keychain credential helper also belongs in `Brewfile`. The supported Colima installation is
`rtk proxy brew install colima`. See the [Colima installation guide](https://github.com/abiosoft/colima/blob/main/docs/INSTALL.md).

`setup.sh` registers the mise-managed Docker plugins. After changing tool installations, rerun
`rtk proxy bash scripts/configure-docker-plugins.sh` to restore plugin discovery, then check
`docker compose version` and `docker buildx version`.

## macOS configuration

This machine sets `XDG_CONFIG_HOME=$HOME/.config`, so Colima uses
`$HOME/.config/colima/default/colima.yaml`. Keep that home when starting Colima from scripts or
services: set `COLIMA_HOME=$HOME/.config/colima` explicitly if the launcher does not inherit XDG
configuration, so a second empty VM is not created under `~/.colima`.

The existing Apple Silicon profile uses `arch: aarch64`, `runtime: docker`, `vmType: vz`,
`mountType: virtiofs`, and `rosetta: true`, with 4 CPUs, 8 GiB RAM, and a 60 GiB disk capacity.
Prefer native arm64 images; Rosetta handles amd64 images when needed. Capacity is the virtual
disk limit, not its current allocated size. Preserve the existing profile and data when changing
resources. VM architecture, runtime, VM type, and mount type can require recreation; do not
recreate an existing VM as an incidental configuration fix.
[Configuration reference](https://colima.run/docs/configuration/).

## Start, inspect, and stop

```sh
rtk proxy colima start
rtk proxy colima status
rtk proxy docker context ls
rtk proxy docker context use colima
rtk proxy docker info
rtk proxy docker compose version
rtk proxy docker buildx version
rtk proxy colima stop
```

Run start when local containers are needed and stop when finished. Colima creates and normally
activates its Docker context on startup; inspect the selection before commands that mutate
containers, especially when remote contexts also exist. Named profiles have separate contexts.
On Linux, operate the native Docker service and select its context instead of starting Colima.
[Lifecycle commands](https://colima.run/docs/commands/).

## Tools that need a socket

Docker-aware tools should use the selected context. For an application that needs an explicit
endpoint, inspect it rather than assuming Colima's default home directory:

```sh
rtk proxy docker context inspect colima --format '{{.Endpoints.docker.Host}}'
```

Use that value in the application's own configuration, or scope `DOCKER_HOST` to that one
invocation. Keep it out of global shell configuration and do not symlink `/var/run/docker.sock`.
This preserves context selection and compatibility with remote Docker engines.
[Colima Docker integration](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md).

## Storage and migration

Inspect the selected engine with `rtk proxy docker system df -v`, `rtk proxy docker ps -a`, and
`rtk proxy docker volume ls` before cleanup. Build caches and unused images can be regenerated;
named volumes and container filesystems may contain the only copy of a database. Stop is the
normal lifecycle operation, not VM deletion or volume pruning.

Docker Desktop and Colima have separate storage. Switching contexts does not migrate images,
containers, or volumes. Recreate disposable services from their Compose definitions and migrate
persistent data through explicit backups and restores before removing the old runtime's data.
Never use `colima delete`, `colima delete --data`, or `docker compose down --volumes` as routine
space recovery; review the affected data and obtain authorization for its removal.
