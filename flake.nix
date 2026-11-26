{
  description = "Shared development environments: Python with JupyterLab, R, the usual dev shell, and cluster images";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      overlay = import ./overlay.nix;

      # mkProject, mkPython, mkR, mkShell, mkContainer, eachSystem, pkgsFor
      lib = import ./lib.nix { inherit nixpkgs systems overlay; };
    in
    {
      overlays.default = overlay;

      inherit lib;

      templates.default = {
        path = ./templates/default;
        description = "egor's devenv";
      };
    }
    // lib.eachSystem (
      pkgs:
      let
        example = lib.mkProject {
          name = "devenv-check";
          pythonPackages = ps: [ ps.polars ];
          rPackages = _: [ ];
        };
      in
      {
        packages = {
          python = lib.mkPython pkgs { };
          R = lib.mkR pkgs { };
        };

        checks.shell = example.devShells.${pkgs.stdenv.hostPlatform.system}.default;

        formatter = pkgs.nixfmt;
      }
    );
}
