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
        patched-osrm-backend = pkgs.stdenv.mkDerivation {
          name = "patched-osrm-backend";
          src = inputs.osrm-backend;
          buildInputs = [
            pkgs.cmake
            pkgs.boost
            pkgs.tbb_2021_8 # Use TBB 2021.8 explicitly
            pkgs.expat
            pkgs.bzip2
            pkgs.libzip
            pkgs.pkg-config
            pkgs.lua5_2
          ];

          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            mkdir build
            cd build
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

        osrm-data = pkgs.runCommandNoCC "osrm-data"
          { buildInputs = [ patched-osrm-backend ]; }
          ''
            mkdir -p $out
            cd $out

            ln -s ${inputs.india-latest} ${openStreetDataFileName}.osm.pbf
            ln -s ${speedDataPath} ${indiaSpeedDataFileName}.csv

            ${patched-osrm-backend}/bin/osrm-extract \
              -p ${patched-osrm-backend}/profiles/car.lua \
              ${openStreetDataFileName}.osm.pbf

            ${patched-osrm-backend}/bin/osrm-partition \
              ${openStreetDataFileName}.osrm

            ${patched-osrm-backend}/bin/osrm-customize \
              --segment-speed-file ${indiaSpeedDataFileName}.csv \
              ${openStreetDataFileName}.osrm
          '';

        osrm-server = pkgs.writeShellApplication {
          name = "osrm-server";
          runtimeInputs = [ patched-osrm-backend ];
          text = ''
            set -x
            osrm-routed --algorithm mld \
               ${osrm-data}/${openStreetDataFileName}.osrm
          '';
        };
      };
  };
}