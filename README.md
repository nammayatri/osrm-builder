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

### Manual update

To manuall trigger an update, go [here](https://github.com/nammayatri/osrm-builder/actions/workflows/update.yml) and run this workflow:

<img width="302" alt="image" src="https://github.com/nammayatri/osrm-builder/assets/3998/22aecc13-6342-4cfe-9a5b-5cbc47404e28">

## `car.lua`

The `car.lua` script plays a crucial role in the accurate and efficient navigation capabilities of OSRM. It defines rules and behavior specific to car routing, impacting how OSRM calculates routes for car navigation.