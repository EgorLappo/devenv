# devenv

## New project

```sh
nix flake init -t github:EgorLappo/devenv
direnv allow
```

## Existing project

```nix
inputs.devenv.url = "github:EgorLappo/devenv";

outputs = { devenv, ... }: devenv.lib.mkProject {
  name = "my-project";
  pythonPackages = ps: with ps; [ numpy polars ];
  rPackages = rp: with rp; [ furrr ];
};
```

## API

- `lib.mkProject { name; python ? pkgs: pkgs.python3; pythonPackages ? ps: [ ]; rPackages ? null; packages ? pkgs: [ ]; env ? { }; unfree ? [ ]; }`: `devShells.default`, plus `packages.{image,sif}` and `apps.sif` on Linux. `python` is the interpreter, as in `mkPython`, and `python = null` leaves Python out. R is included only when `rPackages` is given. `packages` and `env` go into both the shell and the image. `unfree` names the unfree packages to allow (by `lib.getName`, e.g. `[ "sratoolkit" "ncbi-vdb" ]`); Hydra doesn't build those, so they build locally.
- `lib.mkPython pkgs { python ? pkgs.python3; extra ? ps: [ ]; jupyter ? true; }`
- `lib.mkR pkgs { extra ? rp: [ ]; }`
- `lib.mkShell pkgs { python ? null; R ? null; packages ? [ ]; shellHook ? ""; ... }`: any other arguments go to `pkgs.mkShell`.
- `lib.mkContainer pkgs { name; python ? null; R ? null; packages ? [ ]; env ? { }; }`: `{ image; sif; }`, a docker archive and a script that converts it to `<name>.sif` with apptainer. The image has CA certificates in `/etc/ssl/certs`, so https works from jobs.
- `lib.eachSystem (pkgs: { ... })`: flake-utils' `eachSystem`, but given nixpkgs with `overlays.default` instead of the system name. `lib.pkgsFor system` returns the same nixpkgs. `lib.eachSystemWith { unfree = [ ... ]; } (pkgs: { ... })` does the same with those unfree packages allowed.
- `overlays.default`: adds `catppuccin-jupyterlab`, `jupyter-ruff`, `devenv-jupyterlab-settings` and `polars-wheel` to the Python package sets. It overrides nothing, so nothing gets rebuilt.
