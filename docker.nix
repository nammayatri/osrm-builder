{ self, ... }:
let
  imageBase = "ghcr.io/nammayatri/osrm-builder";
  imageTag  = builtins.substring 0 6 (self.rev or "dev");

in {
  perSystem = { pkgs, system, ... }:
  let
    mkDockerImage = profile: profilePkgSet: profileLua:
      pkgs.dockerTools.buildImage {
        name = "${imageBase}-${profile}";
        tag = imageTag;
        created = "now";

        copyToRoot = pkgs.buildEnv {
          name = "patched-osrm-root-${profile}";
          paths = with profilePkgSet; [
            patchedOsrmBackend
            osrmData
            osrmServer
            pkgs.cacert
            pkgs.coreutils
            pkgs.bashInteractive
          ];
        };
      };
    carPkgs = {
      patchedOsrmBackend = self.packages.${system}.patched-osrm-backend-car;
      osrmData           = self.packages.${system}.osrm-data-car;
      osrmServer         = self.packages.${system}.osrm-server-car;
    };

    footPkgs = {
      patchedOsrmBackend = self.packages.${system}.patched-osrm-backend-foot;
      osrmData           = self.packages.${system}.osrm-data-foot;
      osrmServer         = self.packages.${system}.osrm-server-foot;
    };
  in {
    packages = {
      dockerImage-car  = mkDockerImage "car" carPkgs ./car.lua;
      dockerImage-foot = mkDockerImage "foot" footPkgs ./foot.lua;
    };
  };
}
