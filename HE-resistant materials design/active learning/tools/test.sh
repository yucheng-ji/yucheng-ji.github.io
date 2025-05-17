#!/bin/bash

module load 2022r2
module load intel/oneapi-all

srun --job-name="int_job" --partition=compute --time=00:30:00 --ntasks=1 --cpus-per-task=8 --mem-per-cpu=1GB --pty lmp_intel_cpu_intelmpi -in rdf.in

