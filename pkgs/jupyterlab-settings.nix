# JupyterLab defaults for the envs from lib.mkPython. settings saved in
# ~/.jupyter/lab/user-settings still win.
#
# JupyterLab reads defaults from <app_settings_dir>/overrides.d, but nixpkgs'
# jupyter-lab wrapper exports JUPYTERLAB_DIR=<the jupyterlab package>, so the
# default app_settings_dir is inside that package. jupyter_lab_config.json
# points it here instead (a jupyter_server_config.d file wouldn't do: only its
# jpserver_extensions are read). python -m jupyterlab and jupyter notebook
# don't get JUPYTERLAB_DIR and find the same overrides.d through the env
{
  toPythonModule,
  runCommand,
  writeText,
}:

let
  overrides = writeText "devenv-jupyterlab-overrides.json" (
    builtins.toJSON {
      "@jupyterlab/apputils-extension:themes" = {
        theme = "Catppuccin Mocha";
        # used while "adaptive-theme" follows the system light/dark mode
        preferred-light-theme = "Catppuccin Latte";
        preferred-dark-theme = "Catppuccin Mocha";
      };
    }
  );
in
toPythonModule (
  runCommand "devenv-jupyterlab-settings" { } ''
    settings=$out/share/jupyter/lab/settings
    mkdir -p $settings/overrides.d $out/etc/jupyter
    cp ${overrides} $settings/overrides.d/devenv.json
    echo "{\"LabApp\": {\"app_settings_dir\": \"$settings\"}}" \
      > $out/etc/jupyter/jupyter_lab_config.json
  ''
)
