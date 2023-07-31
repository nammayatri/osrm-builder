let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  imageTag = builtins.substring 0 6 (builtins.readFile ./southern-zone-latest.osm.pbf.hash);
in
{
    perSystem = { self', pkgs, lib, ... }: {
      packages = {
        dockerImage = pkgs.dockerTools.buildImage {
          name = imageName;
          tag = imageTag;
          created = "now";
          copyToRoot = pkgs.buildEnv {
            name = "osrm-data";
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
