{
  description = "my-project";

  inputs = {
    devenv.url = "github:EgorLappo/devenv";
  };

  outputs =
    { devenv, ... }:
    devenv.lib.mkProject {
      name = "my-project";

      # python = pkgs: pkgs.python314;
      pythonPackages =
        ps: with ps; [
          numpy
          scipy
          pandas
          polars
          pyarrow
          matplotlib
          seaborn
          statsmodels
          scikit-learn
          tqdm
        ];

      rPackages =
        rp: with rp; [
          ggpubr
          ggthemes
          future
          furrr
        ];

      # packages = pkgs: with pkgs; [ bcftools ];
    };
}
