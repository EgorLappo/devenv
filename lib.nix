# helpers for project flakes.
#
# the mk* functions take the project's `pkgs` first, which needs overlays.default (pkgsFor and eachSystem apply it)
{
  nixpkgs,
  overlay,
  systems,
}:

let
  inherit (nixpkgs) lib;

  pkgsBySystem = lib.genAttrs systems (
    system:
    import nixpkgs {
      inherit system;
      overlays = [ overlay ];
    }
  );
in
rec {
  inherit systems;

  # nixpkgs with overlays.default
  pkgsFor =
    system:
    pkgsBySystem.${system} or (import nixpkgs {
      inherit system;
      overlays = [ overlay ];
    });

  # flake-utils' eachSystem, except that `f` gets nixpkgs with overlays.default
  # instead of the system name:
  #   outputs = { devenv, ... }: devenv.lib.eachSystem (pkgs: { devShells.default = ...; });
  eachSystem =
    f:
    let
      perSystem = lib.mapAttrs (_: f) pkgsBySystem;
      outputNames = lib.unique (lib.concatMap lib.attrNames (lib.attrValues perSystem));
    in
    lib.genAttrs outputNames (
      output:
      lib.mapAttrs (_: outputs: outputs.${output}) (lib.filterAttrs (_: o: o ? ${output}) perSystem)
    );

  # the outputs of a simple analysis project, from its package lists: the dev
  # shell, and on linux the same environment without JupyterLab as an image for
  # the cluster (packages.image, packages.sif, and apps.sif: nix run .#sif)
  mkProject =
    {
      name,
      # the python interpreter (pkgs: pkgs.python314), or null for no python
      python ? (pkgs: pkgs.python3),
      pythonPackages ? (_: [ ]),
      # R packages (rp: [ ... ]); without them, no R
      rPackages ? null,
      # other packages (pkgs: [ ... ]) and environment variables, for the shell
      # and the image alike
      packages ? (_: [ ]),
      env ? { },
    }:
    eachSystem (
      pkgs:
      let
        inherit (pkgs.stdenv.hostPlatform) isLinux;

        pythonEnv =
          jupyter:
          if python == null then
            null
          else
            mkPython pkgs {
              python = python pkgs;
              extra = pythonPackages;
              inherit jupyter;
            };

        REnv = if rPackages == null then null else mkR pkgs { extra = rPackages; };

        container = mkContainer pkgs {
          inherit name env;
          python = pythonEnv false;
          R = REnv;
          packages = packages pkgs;
        };
      in
      {
        devShells.default = mkShell pkgs (
          env
          // {
            inherit name;
            python = pythonEnv true;
            R = REnv;
            # apptainer, to try the image locally
            packages = packages pkgs ++ lib.optional isLinux pkgs.apptainer;
          }
        );

        # empty off linux; static names keep `nix develop` from evaluating
        # nixpkgs for every system
        packages = lib.optionalAttrs isLinux { inherit (container) image sif; };

        apps = lib.optionalAttrs isLinux {
          sif = {
            type = "app";
            program = lib.getExe container.sif;
            meta.description = "Build ${name}.sif from the image";
          };
        };
      }
    );

  # python with JupyterLab (catppuccin, jupyter-ruff), plus the project's
  # packages. jupyter = false leaves JupyterLab out, as for the image.
  mkPython =
    pkgs:
    {
      python ? pkgs.python3,
      extra ? (_: [ ]),
      jupyter ? true,
    }:
    assert lib.assertMsg (
      python.pkgs ? catppuccin-jupyterlab
    ) "devenv: pkgs needs devenv.overlays.default (devenv.lib.pkgsFor and eachSystem apply it)";
    python.withPackages (
      ps:
      let
        wheel = ps.polars-wheel;
        ps' =
          ps
          // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
            polars =
              lib.warnIf (lib.versionAtLeast ps.polars.version wheel.version)
                "devenv: nixpkgs has polars ${ps.polars.version} now (the wheel is ${wheel.version}). Check pl.Series(np.arange(40.0)).max() == 39 with it, then drop the wheel."
                wheel;
          };
      in
      [ ps.ipython ]
      ++ lib.optionals jupyter [
        ps.jupyter
        ps.catppuccin-jupyterlab
        ps.jupyter-ruff
        ps.devenv-jupyterlab-settings
      ]
      ++ extra ps'
    );

  mkR =
    pkgs:
    {
      extra ? (_: [ ]),
    }:
    pkgs.rWrapper.override {
      packages =
        (with pkgs.rPackages; [
          tidyverse
          broom
          scales
          patchwork
          cowplot
          rmarkdown
          knitr
        ])
        ++ extra pkgs.rPackages;
    };

  # pkgs.mkShell with the usual setup. `python` and `R` are envs from mkPython
  # and mkR (either can be left out); all other arguments go to pkgs.mkShell
  mkShell =
    pkgs:
    {
      python ? null,
      R ? null,
      packages ? [ ],
      shellHook ? "",
      ...
    }@args:
    pkgs.mkShell (
      removeAttrs args [
        "python"
        "R"
      ]
      // {
        packages =
          lib.optional (python != null) python
          ++ lib.optional (R != null) R
          ++ (with pkgs; [
            just
            ruff
            basedpyright
          ])
          ++ packages;

        shellHook = ''
          unset PYTHONPATH
          export REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
        ''
        + lib.optionalString (python != null) ''
          # basedpyright and editors find the env through .venv
          ln -sfn ${python} "$REPO_ROOT/.venv"
          alias py=python
        ''
        + lib.optionalString (R != null) ''
          # radian runs this R
          export R_BINARY=${R}/bin/R
          alias rs=Rscript
          alias r="radian -q --vanilla"
        ''
        + shellHook;
      }
    );

  # an environment as an image for the cluster: `image` is a docker archive and
  # `sif` a script that converts it to <name>.sif. apptainer needs user
  # namespaces, which the nix sandbox does not have, so that step is a script
  # rather than a derivation. the image holds the environment only: jobs run
  # the synced code with it
  mkContainer =
    pkgs:
    {
      name,
      python ? null,
      R ? null,
      packages ? [ ],
      env ? { },
    }:
    let
      root = pkgs.buildEnv {
        name = "${name}-container-root";
        paths =
          lib.optional (python != null) python
          ++ lib.optional (R != null) R
          ++ packages
          ++ (with pkgs; [
            bashInteractive
            coreutils
            findutils
            gnugrep
            gnused
            gawk
            gzip
            dockerTools.binSh
            dockerTools.usrBinEnv
          ]);
        pathsToLink = [
          "/bin"
          "/lib"
          "/share"
          "/usr/bin"
        ];
      };

      image = pkgs.dockerTools.buildLayeredImage {
        inherit name;
        tag = "latest";
        contents = [
          root
          pkgs.dockerTools.fakeNss
        ];
        # apptainer unpacks it right away
        compressor = "none";
        config.Env = lib.mapAttrsToList (n: v: "${n}=${toString v}") (
          {
            PATH = "/bin";
            LC_ALL = "C.UTF-8";
            # apptainer binds the host's /etc/localtime as a file, and without
            # TZ, R warns on every run that it is not a symlink
            TZ = "UTC";
            PYTHONDONTWRITEBYTECODE = 1;
            PYTHONUNBUFFERED = 1;
          }
          // env
        );
      };
    in
    {
      inherit image;

      sif = pkgs.writeShellApplication {
        name = "${name}-sif";
        runtimeInputs = [ pkgs.apptainer ];
        text = ''
          out="''${1:-${name}.sif}"
          rm -f "$out"
          apptainer build "$out" "docker-archive:${image}"
          echo "built $out ($(du -h "$out" | cut -f1))"
        '';
      };
    };
}
