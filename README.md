# osrm-backend

First, fetch the data file:

```sh
nix run .#fetch
```

To build and load the docker image,

```sh
git add -N *.osm.pbf*
docker load -i $(nix build .#dockerImage --no-link --print-out-paths)
```
