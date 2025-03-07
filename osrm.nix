{ osrmBackend, inputs, ... }:

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
        patched-osrm-backend = pkgs.osrm-backend.overrideAttrs (oldAttrs: {
          src = osrmBackend;
        });
        # pkgs.stdenv.mkDerivation {
        #   name = "patched-osrm-backend";
        #   src = osrmBackend;
        #   buildInputs = [
        #     pkgs.cmake
        #     pkgs.boost
        #     pkgs.tbb_2021_8 # Use TBB 2021.8 explicitly
        #     pkgs.expat
        #     pkgs.bzip2
        #     pkgs.libzip
        #     pkgs.pkg-config
        #     pkgs.lua5_2 # Updated to Lua 5.3
        #   ];

        #   phases = [ "unpackPhase" "buildPhase" "installPhase" ];
        #   buildPhase = ''
        #     mkdir build
        #     cd build
        #     cmake .. \
        #       -DENABLE_MASON=ON \
        #       -DTBB_ROOT=${pkgs.tbb_2021_8} \
        #       -DCMAKE_PREFIX_PATH="${pkgs.boost};${pkgs.tbb_2021_8};${pkgs.expat};${pkgs.bzip2};${pkgs.lua5_3}" \
        #       -DCMAKE_CXX_STANDARD=20 \
        #       -DCMAKE_CXX_FLAGS="-std=c++20 -stdlib=libc++" \
        #       -DCMAKE_INSTALL_PREFIX=$out
        #     make
        #   '';
        #   installPhase = ''
        #     mkdir -p $out/bin $out/profiles
        #     cp build/osrm-* $out/bin/
        #     cp ${carLuaPath} $out/profiles/car.lua
        #   '';
        # };

        osrm-data = pkgs.runCommandNoCC "osrm-data"
          { buildInputs = [ patched-osrm-backend ]; }
          ''
            mkdir -p $out && cd $out

            # Link input files
            ln -s ${inputs.india-latest} ${openStreetDataFileName}.osm.pbf
            ln -s ${speedDataPath} ${indiaSpeedDataFileName}.csv

            # Run OSRM tools
            ${patched-osrm-backend}/bin/osrm-extract \
              -p ${patched-osrm-backend}/profiles/car.lua \
              ${openStreetDataFileName}.osm.pbf

            ${patched-osrm-backend}/bin/osrm-partition \
              ${openStreetDataFileName}.osrm

            ${patched-osrm-backend}/bin/osrm-customize \
              --segment-speed-file ${indiaSpeedDataFileName}.csv \
              ${openStreetDataFileName}.osrm

            # Move processed data to output directory
            cp ${openStreetDataFileName}.* $out/
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
