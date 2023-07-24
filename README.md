# osrm-backend

To build and load the docker image,

```sh
docker load -i $(nix build .#dockerImage --print-out-paths)
```
