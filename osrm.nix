{ inputs, ... }:

let
  openStreetDataFileName = "SE-zone-latest";
  carLuaPath = ./car.lua; # Adjust this path as needed
  #tempDir = "/tmp/osrm-temp"; # Use a specific temporary directory path
  #copyDir = "${tempDir}/osrm-backend-copy"; # Path to the temporary copy directory
in
{
  perSystem = { pkgs, lib, ... }: {
    packages =
      rec {
        osrm-data =
          pkgs.runCommandNoCC "osrm-data"
            { buildInputs = [ pkgs.osrm-backend ]; }
            ''
              ln -s ${inputs.southern-zone-latest} a.osm.pbf
              ln -s ${inputs.eastern-zone-latest} b.osm.pbf
              mkdir -p $out/share/osrm/profiles

              cp -r ${pkgs.osrm-backend}/* $out/

              # ln -sf ${carLuaPath} $out/share/osrm/profiles/car.lua

              ${pkgs.osmium-tool}/bin/osmium merge -o ${openStreetDataFileName}.osm.pbf a.osm.pbf b.osm.pbf 
              osrm-extract -p $out/share/osrm/profiles/car.lua ${openStreetDataFileName}.osm.pbf
              osrm-partition ${openStreetDataFileName}.osrm
              osrm-customize ${openStreetDataFileName}.osrm
            '';

        osrm-server = pkgs.writeShellApplication {
          name = "osrm-server";
          runtimeInputs = [ osrm-data ];
          text = ''
            set -x
            osrm-routed --algorithm mld \
               $out/${openStreetDataFileName}.osrm
          '';
        };
      };
  };
}
