{ inputs, ... }:

let
  openStreetDataFileName   = "india-latest";
  carLuaPath               = ./car.lua;
  footLuaPath              = ./foot.lua;
  speedDataPath            = ./speed-data.csv;
  indiaSpeedDataFileName   = "india-latest-speed-data";

in {
  perSystem = { self', pkgs, lib, ... }: let
    mkOsrmBackend = profileName: luaPath:
      pkgs.stdenv.mkDerivation {
        name = "patched-osrm-backend-${profileName}";
        src  = inputs.osrm-backend;

        buildInputs = with pkgs; [
          cmake boost tbb_2021_8 expat bzip2 libzip pkg-config lua5_2
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
          cp -r ../profiles/* $out/profiles/ || true
          cp ${luaPath} $out/profiles/${profileName}.lua
        '';
      };

    mkOsrmData = profileName: luaPath: backendDrv:
      pkgs.runCommandNoCC "osrm-data-${profileName}" {
        buildInputs = [ backendDrv ];
      } ''
        mkdir -p $out/opt/osrm-data
        cd $out/opt/osrm-data

        ln -s ${inputs.india-latest}                   ${openStreetDataFileName}.osm.pbf
        ln -s ${speedDataPath}                         ${indiaSpeedDataFileName}.csv

        ${backendDrv}/bin/osrm-extract -p ${backendDrv}/profiles/${profileName}.lua ${openStreetDataFileName}.osm.pbf

        ${backendDrv}/bin/osrm-partition ${openStreetDataFileName}.osrm

        ${backendDrv}/bin/osrm-customize --segment-speed-file ${indiaSpeedDataFileName}.csv ${openStreetDataFileName}.osrm
      '';

    mkOsrmServer = profileName: backendDrv:
      pkgs.writeShellApplication {
        name = "osrm-server-${profileName}";
        runtimeInputs = [ backendDrv ];
        text = ''
          set -x
          osrm-routed --algorithm mld /opt/osrm-data/${openStreetDataFileName}.osrm
        '';
      };
  in {
    packages = rec {
      # Car profile
      patched-osrm-backend-car = mkOsrmBackend "car" carLuaPath;
      osrm-data-car            = mkOsrmData "car" carLuaPath patched-osrm-backend-car;
      osrm-server-car          = mkOsrmServer "car" patched-osrm-backend-car;

      # Foot profile
      patched-osrm-backend-foot = mkOsrmBackend "foot" footLuaPath;
      osrm-data-foot            = mkOsrmData "foot" footLuaPath patched-osrm-backend-foot;
      osrm-server-foot          = mkOsrmServer "foot" patched-osrm-backend-foot;
    };
  };
}
