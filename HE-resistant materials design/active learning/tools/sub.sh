#!/bin/bash
#SBATCH --job-name="mlp_all"
#SBATCH --account=research-3me-mse
#SBATCH --partition=compute
#SBATCH -t 48:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=48
#SBATCH --mem-per-cpu=3G

module load 2022r2
module load intel/oneapi-all

export OMP_NUM_THREADS=1

echo -e "MLIP Start	: \c" >> timepoint.txt
date >> timepoint.txt

srun mlp train curr.mtp train.cfg --trained-pot-name=curr.mtp --update-mindist

echo -e "MLIP END	: \c" >> timepoint.txt
date >> timepoint.txt
