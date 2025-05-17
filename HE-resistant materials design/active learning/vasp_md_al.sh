#!/bin/bash
#SBATCH --job-name="AL-AlScCu"
#SBATCH --account=research-3me-mse
#SBATCH --partition=compute
#SBATCH -t 72:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=48
#SBATCH --mem-per-cpu=3G

module load 2022r2
module load intel/oneapi-all
export OMP_NUM_THREADS=1

mddir=/scratch/yuchengji/lammps/mlip/al_vasp_md
vaspdir=$mddir/calculate_ab_initio_ef

cd $mddir
touch $mddir/log.timestamp

rm -f train.cfg
rm -f curr.mtp
rm -f preselect.cfg
rm -f diff.cfg
rm -f selected.cfg
rm -f out.cfg

cp all.mtp curr.mtp
cp train_init.cfg train.cfg

#A. Active set construction
mlp calc-grade curr.mtp train.cfg train.cfg out.cfg --als-filename=state.als

rm out.cfg

timestamp=1

while [ 1 -gt 0 ]
do
echo -e "############## This is the -> $timestamp <- cycle ##############" >> $mddir/log.timestamp
#B. MD simulations and extrapolative (preselected) configurations
touch preselect.cfg

srun --job-name="int_job" --partition=compute --time=00:30:00 --ntasks=1 --cpus-per-task=8 --mem-per-cpu=1GB --pty lmp_intel_cpu_intelmpi -in rdf.in

#mpirun -np 2 lmp_intel_cpu_intelmpi -in rdf.in

n_preselected=$(grep "BEGIN" preselect.cfg | wc -l)

if [ $n_preselected -gt 0 ]; then

#C. Selection
    mlp select-add curr.mtp train.cfg preselect.cfg diff.cfg --als-filename=state.als
    cp diff.cfg $vaspdir

    rm -f preselect.cfg
    rm -f selected.cfg

#D and E. Ab initio calculations and merging (updating the training set)
    cd $vaspdir

    mlp convert-cfg diff.cfg outmodel --output-format=vasp-poscar
    /home/yuchengji/bin/py39/bin/python3.9 al_vasp_calibration.py

    rm -rf oumodel*
    cd $vaspdir/mlp_al
    
    for mfile in outmodel*
    do
        cd $vaspdir/mlp_al/$mfile
	echo -e "VASP Calc    :     $mfile	start	\c" >> $mddir/log.timestamp
	date >> $mddir/log.timestamp

        srun /home/yuchengji/bin/vasp/vasp_std_recompiled
	energy=$( grep "TOTEN" OUTCAR | tail -n 1 | awk -F" " '{print $5}')

	if [ $(echo "$energy < 0 "| bc ) -eq 1 ];then
                echo -e "VASP Calc    :	$mfile	$energy     \c" >> $mddir/log.timestamp
                date >> $mddir/log.timestamp
		mlp convert-cfg --input-format=vasp-outcar OUTCAR $mfile.cfg
	        cp $mfile.cfg $vaspdir
	else
		echo -e "VASP Calc    : Error --> skipped     \c" >> $mddir/log.timestamp
		date >> $mddir/log.timestamp
	fi

        cd $vaspdir
    done

    cat out*.cfg >> $mddir/train.cfg

    rm -rf mlp_al diff.cfg outmodel* OUTCAR

    cd $mddir

#F. Training
    echo -e "MLIP Start   : 	\c" >> $mddir/log.timestamp
    date >> $mddir/log.timestamp

    srun mlp train curr.mtp train.cfg --trained-pot-name=curr.mtp --update-mindist
    
    echo -e "MLIP END     : 	\c" >> $mddir/log.timestamp
    date >> $mddir/log.timestamp

    
#A. Active set construction
    mlp calc-grade curr.mtp train.cfg diff.cfg out.cfg --als-filename=state.als
    
    rm -f diff.cfg
    rm -f out.cfg

    timestamp=$[$timestamp+1]
    
elif  [ $n_preselected -eq 0 ]; then
    exit
fi

done

