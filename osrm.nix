{ inputs, ... }:

let
  openStreetDataFileName = "SE-zone-latest";
  carLuaPath = ./car.lua; # Adjust this path as needed
in
{
  perSystem = { self', pkgs, lib, ... }: {
    packages =
      rec {
        osrm-backend = pkgs.osrm-backend.overrideAttrs (oa: {
          postInstall = (oa.postInstall or "") + ''
            cp ${carLuaPath} $out/share/osrm/profiles/car.lua
          '';
        });

        osrm-data =
          pkgs.runCommandNoCC "osrm-data"
            { buildInputs = [ self'.packages.osrm-backend ]; }
            ''
              mkdir $out && cd $out
              ln -s ${inputs.southern-zone-latest} a.osm.pbf
              ln -s ${inputs.eastern-zone-latest} b.osm.pbf
              ${pkgs.osmium-tool}/bin/osmium merge -o ${openStreetDataFileName}.osm.pbf a.osm.pbf b.osm.pbf
              osrm-extract -p ${pkgs.osrm-backend}/share/osrm/profiles/car.lua ${openStreetDataFileName}.osm.pbf
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
