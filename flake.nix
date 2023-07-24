{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        ./osrm.nix
        ./docker.nix
      ];
      perSystem = { self', pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
