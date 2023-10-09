{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    # data files
    southern-zone-latest.url = "https://download.geofabrik.de/africa/sao-tome-and-principe-latest.osm.pbf";
    southern-zone-latest.flake = false;
    eastern-zone-latest.url = "https://download.geofabrik.de/africa/seychelles-latest.osm.pbf";
    eastern-zone-latest.flake = false;
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
