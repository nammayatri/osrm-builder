{ self, ... }:
let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  imageTag  = builtins.substring 0 6 (self.rev or "dev");
in
{
  perSystem = { self', pkgs, lib, ... }:
    let
      # Both images share one name; the walking one is told apart by a tag
      # suffix (<sha>-foot), which CI mirrors when it pushes.
      mkImage = tagSuffix: data: pkgs.dockerTools.buildImage {
        name    = imageName;
        tag     = imageTag + tagSuffix;
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
            data
          ];
        };
      };
    in
    {
      packages = {
        # Car routing (what beckn-osrm runs today)
        dockerImage = mkImage "" self'.packages.osrm-data;

        # Walking routing; same server command, foot-profile data
        dockerImageFoot = mkImage "-foot" self'.packages.osrm-data-foot;
      };
    };
}
