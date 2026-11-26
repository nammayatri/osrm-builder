{ inputs, ... }:

let
  carLuaPath    = ./car.lua;
  speedDataPath = ./speed-data.csv;
in
{
  perSystem = { self', pkgs, lib, ... }:
    let
      backend = self'.packages.patched-osrm-backend;

      mkOsrmData = { name, dataName, pbf, profile, speedData ? null }:
        pkgs.runCommandNoCC name { buildInputs = [ backend ]; } ''
          mkdir -p $out/opt/osrm-data
          cd $out/opt/osrm-data

          ln -s ${pbf} ${dataName}.osm.pbf

          ${backend}/bin/osrm-extract -p ${backend}/profiles/${profile}.lua ${dataName}.osm.pbf

          ${backend}/bin/osrm-partition ${dataName}.osrm

          ${backend}/bin/osrm-customize ${lib.optionalString (speedData != null) "--segment-speed-file ${speedData}"} ${dataName}.osrm
        '';

      mergePbf = name: pbfs: pkgs.runCommandNoCC name {
        buildInputs = [ pkgs.osmium-tool ];
      } ''
        osmium merge -F pbf ${lib.concatStringsSep " " (map toString pbfs)} -o $out -f pbf
      '';

      mkOsrmServer = dataName: pkgs.writeShellApplication {
        name          = "osrm-server";
        runtimeInputs = [ backend ];
        text = ''
          set -x
          osrm-routed --algorithm mld /opt/osrm-data/${dataName}.osrm
        '';
      };
    in
    {
      packages = rec {
        patched-osrm-backend = pkgs.stdenv.mkDerivation {
          name       = "patched-osrm-backend";
          src        = inputs.osrm-backend;
          buildInputs = [
            pkgs.cmake
            pkgs.boost
            pkgs.tbb_2021_8
            pkgs.expat
            pkgs.bzip2
            pkgs.libzip
            pkgs.pkg-config
            pkgs.lua5_2
          ];
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            mkdir build && cd build
            cmake .. \
              -DENABLE_MASON=ON \
              -DENABLE_IPO=OFF \
              -DTBB_ROOT=${pkgs.tbb_2021_8} \
              -DCMAKE_PREFIX_PATH="${pkgs.boost};${pkgs.tbb_2021_8};${pkgs.expat};${pkgs.bzip2};${pkgs.lua5_2}" \
              -DCMAKE_CXX_STANDARD=20 \
              -DCMAKE_CXX_FLAGS="-std=c++20 -Wno-error=array-bounds -fpermissive" \
              -DCMAKE_INSTALL_PREFIX=$out
            make
          '';
          installPhase = ''
            mkdir -p $out/bin $out/profiles
            cp osrm-* $out/bin/
            cp -r ../profiles/* $out/profiles/
            cp ${carLuaPath} $out/profiles/car.lua
          '';
        };

        europe-pbf = mergePbf "europe-latest.osm.pbf" [
          inputs.finland-latest
          inputs.netherlands-latest
        ];

        india-europe-pbf = mergePbf "india-europe-latest.osm.pbf" [
          inputs.india-latest
          inputs.finland-latest
          inputs.netherlands-latest
        ];

        osrm-data = mkOsrmData {
          name      = "osrm-data";
          dataName  = "india-latest";
          pbf       = inputs.india-latest;
          profile   = "car";
          speedData = speedDataPath;
        };

        # Same map, walking profile (stock foot.lua from the patched backend).
        # OSRM fixes the profile at extract time and ignores the profile segment
        # of the request URL, so walking routes need a dataset of their own.
        # No --segment-speed-file: speed-data.csv holds car segment speeds.
        osrm-data-foot = mkOsrmData {
          name     = "osrm-data-foot";
          dataName = "india-latest";
          pbf      = inputs.india-latest;
          profile  = "foot";
        };

        osrm-data-europe = mkOsrmData {
          name     = "osrm-data-europe";
          dataName = "europe-latest";
          pbf      = europe-pbf;
          profile  = "car";
        };

        osrm-data-europe-foot = mkOsrmData {
          name     = "osrm-data-europe-foot";
          dataName = "europe-latest";
          pbf      = europe-pbf;
          profile  = "foot";
        };

        osrm-data-india-europe = mkOsrmData {
          name      = "osrm-data-india-europe";
          dataName  = "india-europe-latest";
          pbf       = india-europe-pbf;
          profile   = "car";
          speedData = speedDataPath;
        };

        osrm-server               = mkOsrmServer "india-latest";
        osrm-server-europe        = mkOsrmServer "europe-latest";
        osrm-server-india-europe  = mkOsrmServer "india-europe-latest";
      };
    };
}
