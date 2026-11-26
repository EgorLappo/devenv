# the JupyterLab theme (the `catppuccin` in nixpkgs is the palette library).
# a prebuilt labextension: themes Catppuccin Latte, Frappé, Macchiato, Mocha
{
  buildPythonPackage,
  fetchurl,
}:

buildPythonPackage {
  pname = "catppuccin-jupyterlab";
  version = "0.2.5";
  format = "wheel";
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/7e/33/445cd4ea73fbcd0d4d11f1a15d4cb77334675ffce5732586235bac81a8f0/catppuccin_jupyterlab-0.2.5-py3-none-any.whl";
    hash = "sha256-d5uxZIf3AJ7AX9GEfWdb/+KMTi7xA3Df+SkZgVD6C6Y=";
  };
  pythonImportsCheck = [ "catppuccin_jupyterlab" ];

  meta = {
    description = "Soothing pastel theme for JupyterLab";
    homepage = "https://github.com/catppuccin/jupyterlab";
  };
}
