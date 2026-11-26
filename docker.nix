{ self, ... }:
let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  imageTag  = builtins.substring 0 6 (self.rev or "dev");
in
{
  perSystem = { self', pkgs, lib, ... }:
    let
      # All images share one name and are told apart by a tag suffix
      # (<sha>-foot, <sha>-eu, <sha>-eu-foot, <sha>-india-eu), which CI mirrors when it pushes.
      mkImage = tagSuffix: server: data: pkgs.dockerTools.buildImage {
        name    = imageName;
        tag     = imageTag + tagSuffix;
        created = "now";

        copyToRoot = pkgs.buildEnv {
          name = "osrm-data";
          paths = with pkgs; [
            cacert
            coreutils
            bashInteractive
            self'.packages.patched-osrm-backend
            server
            data
          ];
        };
      };
    in
    {
      packages = with self'.packages; {
        dockerImage        = mkImage ""          osrm-server              osrm-data;
        dockerImageFoot    = mkImage "-foot"     osrm-server              osrm-data-foot;
        dockerImageEu      = mkImage "-eu"       osrm-server-europe       osrm-data-europe;
        dockerImageEuFoot  = mkImage "-eu-foot"  osrm-server-europe       osrm-data-europe-foot;
        dockerImageIndiaEu = mkImage "-india-eu" osrm-server-india-europe osrm-data-india-europe;
      };
    };
}
