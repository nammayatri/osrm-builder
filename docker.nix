let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  imageTag = builtins.readFile ./southern-zone-latest.osm.pbf.hash;
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
