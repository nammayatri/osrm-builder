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
            REGION1=southern-zone-latest
            REGION2=eastern-zone-latest
            MERGED=SE-zone-latest
            set -x
            rm -f $REGION1.osm.pbf*
            rm -f $REGION2.osm.pbf*
            ${lib.getExe pkgs.wget} http://download.geofabrik.de/asia/india/$REGION1.osm.pbf
            ${lib.getExe pkgs.wget} http://download.geofabrik.de/asia/india/$REGION2.osm.pbf
            ${pkgs.osmium-tool}/bin/osmium merge -o $MERGED.osm.pbf $REGION1.osm.pbf $REGION2.osm.pbf
            nix hash file $MERGED.osm.pbf  --base32 > $MERGED.osm.pbf.hash
          '';
        };
      };
    };
}
