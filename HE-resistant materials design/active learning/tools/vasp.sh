#!/bin/bash
#SBATCH --job-name="AL-AlScCu"
#SBATCH --account=research-3me-mse
#SBATCH --partition=compute
#SBATCH -t 72:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=48
#SBATCH --mem-per-cpu=2G

module load 2022r2
module load intel/oneapi-all
export I_MPI_PMI_LIBRARY=/cm/shared/apps/slurm/current/lib64/libpmi2.so
export I_MPI_OFI_LIBRARY_INTERNAL=off

dir=/scratch/yuchengji/lammps/al_vasp_md/calculate_ab_initio_ef/mlp_al
logdir=/scratch/yuchengji/log/lammps/al_vasp.log

touch $logdir
cd $dir

for file in outmodel*
do
	cd $dir/$file

	echo "----------------------------------------------------" >> $logdir
        echo -e "AL ${file##*/} |       Start time:     \c" >> $logdir
        date >> $logdir

	srun /home/yuchengji/bin/vasp/vasp_std_recompiled

	mlp convert-cfg --input-format=vasp-outcar OUTCAR $file.cfg
	cp $file.cfg ..

	cd $dir
done
