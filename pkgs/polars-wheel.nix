# polars from the upstream wheels, swapped into the envs by lib.mkPython.
#
# nixpkgs builds polars from source with RUSTC_BOOTSTRAP and its own rustc, and
# that build reduces Float64 max/min over the first 8 elements only:
# pl.Series(np.arange(40.0)).max() == 7.0. The upstream wheels are right.
{
  buildPythonPackage,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  python,
}:

let
  version = "2.1.0";

  polars-runtime-32 = buildPythonPackage {
    pname = "polars_runtime_32";
    inherit version;
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d2/e6/649c524252d32b24d0ba92278033823fa8e0040ee3748ce5afbeda107403/polars_runtime_32-2.1.0-cp311-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-C4OAVs82XXSXlx2dmCXFR3ZpIzOHccSMVFuG6tLrxXI=";
    };
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];
    meta.platforms = [ "x86_64-linux" ];
  };
in
buildPythonPackage {
  pname = "polars";
  inherit version;
  format = "wheel";
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/d5/d4/e696a46c74ec8cac6434764deaf72f7edcc2e91c2145a9b3f61900a7aa7a/polars-2.1.0-py3-none-any.whl";
    hash = "sha256-Y8UM41M/WgPRfDoqJPHQ4MftqY+95CaKPLqQDTQGDmc=";
  };
  dependencies = [ polars-runtime-32 ];
  pythonImportsCheck = [ "polars" ];

  # the bug above
  postInstallCheck = ''
    PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH" ${python.interpreter} -c '
    import polars as pl
    xs = [float(i) for i in range(40)]
    assert pl.Series(xs).max() == 39.0, pl.Series(xs).max()
    assert pl.Series(xs[::-1]).min() == 0.0, pl.Series(xs[::-1]).min()
    print("polars float max/min over 40 elements: ok")
    '
  '';

  passthru.runtime = polars-runtime-32;

  meta = {
    description = "Polars from the upstream wheels";
    homepage = "https://pola.rs";
    platforms = [ "x86_64-linux" ];
  };
}
