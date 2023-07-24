{ self, ... }:

let
  imageName = "ghcr.io/nammayatri/osrm-builder";
  # self.rev will be non-null only when the working tree is clean
  # This is equivalent to `git rev-parse --short HEAD`
  # imageTag = builtins.substring 0 6 (self.rev or "dev");
  imageTag = "dev";
in
{
    perSystem = { self', pkgs, lib, ... }: {
      packages = {
        dockerImage = pkgs.dockerTools.buildImage {
          name = imageName;
          created = "now";
          tag = "dev"; # TODO: based on date
          copyToRoot = pkgs.buildEnv {
            paths = with pkgs; [
              cacert
              coreutils
              bash
              self'.packages.osrm-data
            ];
            name = "osrm-data-img";
            /* pathsToLink = [
              "/bin"
              "/opt"
            ];
            */
          };
          config = {
            Env = [
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              # Ref: https://hackage.haskell.org/package/x509-system-1.6.7/docs/src/System.X509.Unix.html#getSystemCertificateStore
              "SYSTEM_CERTIFICATE_PATH=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
          };
        };
      };
    };
}
