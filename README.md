# osrm-backend

First, fetch the data file:

```sh
nix run .#fetch
```

To build and load the docker image,

```sh
docker load -i $(nix build .#dockerImage --print-out-paths)
```
