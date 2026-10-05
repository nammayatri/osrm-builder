{ self, ... }:
let
  imageName     = "ghcr.io/nammayatri/osrm-builder";
  footImageName = "ghcr.io/nammayatri/osrm-builder-foot";
  imageTag      = builtins.substring 0 6 (self.rev or "dev");
in
{
  perSystem = { self', pkgs, lib, ... }:
    let
      mkImage = name: data: pkgs.dockerTools.buildImage {
        inherit name;
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
            data
          ];
        };
      };
    in
    {
      packages = {
        # Car routing (what beckn-osrm runs today)
        dockerImage = mkImage imageName self'.packages.osrm-data;

        # Walking routing; same server command, foot-profile data
        dockerImageFoot = mkImage footImageName self'.packages.osrm-data-foot;
      };
    };
}
