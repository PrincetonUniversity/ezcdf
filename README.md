# ezcdf

## About

EZcdf, Easy Interface to netCDF routine calls. See the USERGUIDE for more details.

## Contact

transp_support@pppl.gov


## History

Feb 1999   - Created  
April 2000 - A. Pletzer: Added R4  
May 2000   - C. Ludescher-Furth: Simplified by adding module ezcdf  
May 2001   - A. Pletzer: Added C8 and C16  
Oct 2002   - S. Hirshman: added LOG and reworked interface  
Sept 2019  - Moved to github


## Contents

Sources to build `libezcdf.a` or `libezcdf.so` and f90 modules:
```
   ezcdf.f90         ezcdf_genget.f90  ezcdf_inqvar.f90  
   ezcdf_attrib.f90  ezcdf_genput.f90  ezcdf_opncls.f90  
   handle_err.f90
```

Test programs, reference output data in `ref/`:
   `eztest.f90` - Fortran example program
   `eztest2.cc, ezcdf.hh` - C++ example program.


## Build

NOTE:  For linking the netCDF library is required.
```
make             # will build libezcdf.a, libezcdf.so, and the test programs
make libezcdf.a  # only build the static library, similar for the shared library or test porgrams
make clean       # will remove the compiled objects and modules  
make clobber     # will run clean and remove the libs and test programs
```
The Makefile is set-up for compiling with the GNU, Intel, and Portland group compilers.


## Test

Fortran test program:
```
./eztest
```
will write and re-read a simple netCDF file `EZtest.nc` and write/re-read a large file, `bigFile.nc` and check for errors. The contents of these files should be the same as what is in `ref/`.

C++ version of eztest
```
./eztest2
```
which writes the `EZtest.cdf` output file.


## Install

Final installation will be put in a location specified by the `PREFIX` environment variable. The directory './build/' will be used if not specified. Installation done with:
```
make install     # will install the code in $PREFIX  
make uninstall   # to delete the installation
```
