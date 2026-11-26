# formats notebook cells with ruff. a prebuilt labextension that runs its own
# ruff (0.14, compiled to WebAssembly) in the browser, not the shell's ruff.
# settings: format-on-save, format-on-run (both off by default), sort-imports
{
  buildPythonPackage,
  fetchurl,
}:

buildPythonPackage {
  pname = "jupyter-ruff";
  version = "0.3.1";
  format = "wheel";
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/44/eb/bc5322c8fe3f519a9ddfafe80e40c38706c3639f7124885d02d9d23bf54a/jupyter_ruff-0.3.1-py3-none-any.whl";
    hash = "sha256-M4ApjoAS6x+TtitT6J+MRffs7hotwTPEFdomH8YOH48=";
  };
  pythonImportsCheck = [ "jupyter_ruff" ];

  meta = {
    description = "JupyterLab and Notebook extension for formatting code with Ruff";
    homepage = "https://github.com/leotaku/jupyter-ruff";
  };
}
