#!/bin/bash
#SBATCH --job-name=my-project
#SBATCH --partition=dpetrov,normal,hns
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00

# from the synced checkout: sbatch cluster/example.sbatch
# (bash because nix flake init drops cluster/run's executable bit)
bash cluster/run python scripts/example.py
