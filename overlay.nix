# python packages that nixpkgs doesn't have. this only adds attributes, so
# nothing that is already in nixpkgs changes or gets rebuilt
_final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyfinal: _pyprev: {
      catppuccin-jupyterlab = pyfinal.callPackage ./pkgs/catppuccin-jupyterlab.nix { };
      jupyter-ruff = pyfinal.callPackage ./pkgs/jupyter-ruff.nix { };
      devenv-jupyterlab-settings = pyfinal.callPackage ./pkgs/jupyterlab-settings.nix { };
      # not `polars`: lib.mkPython swaps it in for the env only (see there)
      polars-wheel = pyfinal.callPackage ./pkgs/polars-wheel.nix { };
    })
  ];
}
