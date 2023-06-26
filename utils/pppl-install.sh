#!/bin/bash

rm -rf builds

module purge
module load gcc/9.3.0
module load netcdf-c/4.7.3
module load netcdf-fortran/4.5.2
make clobber
make
PREFIX=`pwd`/builds/gcc/9.3.0 make install

module purge
module load gcc/11.2.0 
module load netcdf-c/4.8.1 
module load netcdf-fortran/4.5.4
make clobber
make
PREFIX=`pwd`/builds/gcc/11.2.0 make install

module purge
module load intel/2019.u3
module load netcdf-c/4.7.3
module load netcdf-fortran/4.5.2
make clobber
make
PREFIX=`pwd`/builds/icc/2019 make install

module purge
module load intel/2022.1.2
module load netcdf-c/4.9.0
module load netcdf-fortran/4.6.0
make clobber
make
PREFIX=`pwd`/builds/icc/2022 make install

module purge
module load pgi/19.10 
module load netcdf-c/4.7.3
module load netcdf-fortran/4.5.2
make clobber
make
PREFIX=`pwd`/builds/pgi/19.10 make install
