{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    # data files
    india-latest.url = "https://download.geofabrik.de/africa/comores-latest.osm.pbf";
    india-latest.flake = false;
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        ./osrm.nix
        ./docker.nix
      ];
      perSystem = { self', pkgs, lib, ... }: {
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
