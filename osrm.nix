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
        # Custom build of osrm-backend with our modifications
        patched-osrm-backend = pkgs.stdenv.mkDerivation {
          name = "patched-osrm-backend";
          src = osrmBackend;
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
          
          # Add this patch to fix the C++20 iterator issue
          patches = [
            (pkgs.writeText "fix-iter-value-t.patch" ''
              diff --git a/include/util/static_assert.hpp b/include/util/static_assert.hpp
              --- a/include/util/static_assert.hpp
              +++ b/include/util/static_assert.hpp
              @@ -12,1 +12,1 @@
              -    static_assert(std::is_same_v<std::iter_value_t<It>, Value>, "");
              +    static_assert(std::is_same_v<typename std::iterator_traits<It>::value_type, Value>, "");
            '')
          ];

          phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
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
            
            # Copy the entire profiles directory instead of just car.lua
            cp -r ../profiles/* $out/profiles/
            
            # If you have a custom car.lua, uncomment this to overwrite the default
            cp ${carLuaPath} $out/profiles/car.lua
          '';
        };

        # Modified osrm-data to remove the redundant cp command
        osrm-data = pkgs.runCommandNoCC "osrm-data"
          { buildInputs = [ patched-osrm-backend ]; }
          ''
            mkdir -p $out
            cd $out

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

            # Remove redundant copy - files are already in $out
            # cp ${openStreetDataFileName}.* $out/
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