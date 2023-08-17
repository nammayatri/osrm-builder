{ inputs, ... }:

let
  openStreetDataFileName = "SE-zone-latest";
in
{
  perSystem = { pkgs, lib, ... }: {
    packages =
      rec {
        osrm-data =
          pkgs.runCommandNoCC "osrm-data"
            { buildInputs = [ pkgs.osrm-backend ]; }
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
          runtimeInputs = [ pkgs.osrm-backend ];
          text = ''
            set -x
            osrm-routed --algorithm mld \
               ${osrm-data}/${openStreetDataFileName}.osrm
          '';
        };
      };
  };
}
