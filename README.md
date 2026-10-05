# osrm-backend

First, fetch the latest data files:

```sh
nix flake lock --update-input india-latest
```

To build and load the docker image,

```sh
docker load -i $(nix build .#dockerImage --no-link --print-out-paths)
```

Commit the changes to the `flake.lock` file.

## Walking (foot) profile

OSRM fixes the routing profile when the data is extracted; the `driving`/`foot` segment of a request URL is ignored. The car image (`dockerImage`) therefore answers `/route/v1/foot/...` with a **car** route. Walking routes come from a separate image built from the same `india-latest` map with the stock `foot.lua`:

```sh
docker load -i $(nix build .#dockerImageFoot --no-link --print-out-paths)
```

It is pushed as `ghcr.io/nammayatri/osrm-builder-foot:<sha>` and runs with the same command as the car image (`osrm-server`, data at `/opt/osrm-data/india-latest.osrm`), so it deploys as its own service, e.g. with `/(route|table|match|nearest|trip)/v1/foot/` routed to it. `speed-data.csv` is not applied to it (those are car speeds).

## Auto update in CI

https://github.com/DeterminateSystems/update-flake-lock is used to automatically open a PR every week to make an update to the `flake.lock` file. Merge this PR so `main` branch will build the new latest data.

### Manual update

To manuall trigger an update, go [here](https://github.com/nammayatri/osrm-builder/actions/workflows/update.yml) and run this workflow:

<img width="302" alt="image" src="https://github.com/nammayatri/osrm-builder/assets/3998/22aecc13-6342-4cfe-9a5b-5cbc47404e28">

## `car.lua`

The `car.lua` script plays a crucial role in the accurate and efficient navigation capabilities of OSRM. It defines rules and behavior specific to car routing, impacting how OSRM calculates routes for car navigation.