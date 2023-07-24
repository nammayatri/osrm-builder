{ self, ... }:

let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  # self.rev will be non-null only when the working tree is clean
  # This is equivalent to `git rev-parse --short HEAD`
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
            name = "osrm-builder-contents";
            paths = with pkgs; [
              cacert
              coreutils
              bashInteractive
              self'.packages.osrm-data
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
