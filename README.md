# osrm-backend

First, fetch the latest data files:

```sh
nix flake lock --update-input southern-zone-latest --update-input eastern-zone-latest
```

To build and load the docker image,

```sh
docker load -i $(nix build .#dockerImage --no-link --print-out-paths)
```

Commit the changes to the `flake.lock` file.

## Auto update in CI

https://github.com/DeterminateSystems/update-flake-lock is used to automatically open a PR every week to make an update to the `flake.lock` file. Merge this PR so `main` branch will build the new latest data.