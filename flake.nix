{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
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

        apps.fetch.program = pkgs.writeShellApplication {
          name = "osrm-fetch";
          text = ''
            NAME=southern-zone-latest
            set -x
            rm -f $NAME.osm.pbf*
            ${lib.getExe pkgs.wget} http://download.geofabrik.de/asia/india/$NAME.osm.pbf
            nix hash file $NAME.osm.pbf  --base32 > $NAME.osm.pbf.hash
          '';
        };
      };
    };
}
