{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        craneLib = crane.mkLib pkgs;

        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;

          buildInputs = [
            # additional build inputs
          ];
        };

        my-crate = craneLib.buildPackage (
          commonArgs // {
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          }
        );
      in {
        packages.default = my-crate;
        apps.default = flake-utils.lib.mkApp { drv = my-crate; };
        checks = { inherit my-crate; };

        devShells.default = craneLib.devShell {
          checks = self.checks.${system};

          packages = [
            # extra tools in dev shell
          ];
        };
      }
    );
}
