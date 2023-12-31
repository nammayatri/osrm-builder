{ inputs, ... }:

let
  openStreetDataFileName = "india-latest";
  carLuaPath = ./car.lua; # Adjust this path as needed
  speedDataPath = ./speed-data.csv;
  indiaSpeedDataFileName = "india-latest-speed-data";
in
{
  perSystem = { self', pkgs, lib, ... }: {
    packages =
      rec {
        # Patch osrm-backend to use our own car.lua file
        osrm-backend = pkgs.osrm-backend.overrideAttrs (oa: {
          # TODO: Use `patches` to directly patch the car.lua file.
          # Or, use a fork of osrm-backend, and point to it.
          src = pkgs.runCommandNoCC "osrm-backend-patched-src" { } ''
            cp -r ${oa.src} $out
            chmod -R u+w $out
            cp ${carLuaPath} $out/profiles/car.lua
          '';
        });

        osrm-data =
          pkgs.runCommandNoCC "osrm-data"
            { buildInputs = [ self'.packages.osrm-backend ]; }
            ''
              mkdir $out && cd $out
              ln -s ${inputs.india-latest} ${openStreetDataFileName}.osm.pbf
              ln -s ${speedDataPath} ${indiaSpeedDataFileName}.csv
              osrm-extract -p ${self'.packages.osrm-backend}/share/osrm/profiles/car.lua ${openStreetDataFileName}.osm.pbf
              osrm-partition ${openStreetDataFileName}.osrm
              osrm-customize --segment-speed-file ${indiaSpeedDataFileName}.csv ${openStreetDataFileName}.osrm
            '';

        osrm-server = pkgs.writeShellApplication {
          name = "osrm-server";
          runtimeInputs = [ self'.packages.osrm-backend ];
          text = ''
            set -x
            osrm-routed --algorithm mld \
               ${osrm-data}/${openStreetDataFileName}.osrm
          '';
        };
      };
  };
}
