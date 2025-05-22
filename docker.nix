{ self, ... }:
let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  imageTag = builtins.substring 0 6 (self.rev or "dev");
in
{
  perSystem = { self', pkgs, lib, ... }: {
    packages = {
      dockerImage = pkgs.dockerTools.buildImage {
        name = imageName;
        tag = imageTag;
        created = "now";
        copyToRoot = pkgs.buildEnv {
          name = "patched-osrm-backend";
          paths = with pkgs; [
            cacert
            coreutils
            bashInteractive
            self'.packages.osrm-server
          ];
          /* pathsToLink = [
              "/bin"
              "/opt"
            ];
            */
        };
      };
    };
  };
}
