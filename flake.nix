{
  inputs = {
    common.url = "github:nammayatri/common";
    nixpkgs.follows = "common/nixpkgs";
    flake-parts.follows = "common/flake-parts";
    systems.follows = "common/systems";

    # data files
    india-latest.url = "https://download.geofabrik.de/asia/india-latest.osm.pbf";
    india-latest.flake = false;
    finland-latest.url = "https://download.geofabrik.de/europe/finland-latest.osm.pbf";
    finland-latest.flake = false;
    netherlands-latest.url = "https://download.geofabrik.de/europe/netherlands-latest.osm.pbf";
    netherlands-latest.flake = false;

    osrm-backend = {
      url = "github:nammayatri/osrm-backend/Backend/feat/adding-one-to-one-distance-calculation";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        (import ./osrm.nix { inherit inputs; })
        ./docker.nix
      ];
      perSystem = { self', pkgs, lib, ... }: {
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}