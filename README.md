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
