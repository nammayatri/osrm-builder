{ self, ... }:
let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  imageTag  = builtins.substring 0 6 (self.rev or "dev");
in
{
  perSystem = { self', pkgs, lib, ... }: {
    packages = {
      dockerImage = pkgs.dockerTools.buildImage {
        name    = imageName;
        tag     = imageTag;
        created = "now";

        # pull in everything under / via buildEnv
        copyToRoot = pkgs.buildEnv {
          name = "osrm-data";
          paths = with pkgs; [
            cacert
            coreutils
            bashInteractive
            self'.packages.patched-osrm-backend
            self'.packages.osrm-server
            self'.packages.osrm-data
          ];
        };
      };
    };
  };
}
