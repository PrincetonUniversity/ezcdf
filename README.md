# ezcdf

## About

EZCDF (Easy Interface to NetCDF) provides a simplified interface to NetCDF routine calls. It is intended to reduce the complexity of reading and writing NetCDF files from Fortran applications.

See the `USERGUIDE` for additional details and usage examples.

## Contact

[transp_support@pppl.gov](mailto:transp_support@pppl.gov)

## History

Feb 1999   - Created
Apr 2000   - A. Pletzer: Added R4 support
May 2000   - C. Ludescher-Furth: Simplified by adding module `ezcdf`
May 2001   - A. Pletzer: Added C8 and C16 support
Oct 2002   - S. Hirshman: Added LOG support and reworked interfaces
Sept 2019  - Migrated to GitHub
May 2026   - Updated build system for GCC 13.4.0, OpenMPI 5.0.10, NetCDF 4.9.3, and NetCDF-Fortran 4.6.2 on Lynx

## Contents

Sources used to build `libezcdf.a`, `libezcdf.so`, and the Fortran modules:

```text
ezcdf.f90
ezcdf_attrib.f90
ezcdf_genget.f90
ezcdf_genput.f90
ezcdf_inqvar.f90
ezcdf_opncls.f90
handle_err.f90
```

Test programs and reference output data in `ref/`:

```text
eztest.f90            - Fortran example program
eztest2.cc            - C++ example program
ezcdf.hh              - C++ wrapper interface
```

## Prerequisites

The build requires NetCDF C and NetCDF Fortran libraries.

Recommended Lynx environment (env_gcc_13.4.0):

```bash
module purge

module load gcc-runtime/13.4.0
module load gcc/13.4.0
module load openmpi/5.0.10-gcc-13.4.0

module load hdf5/1.14.6-gcc-13.4.0
module load netcdf-c/4.9.3-gcc-13.4.0
module load netcdf-fortran/4.6.2-gcc-13.4.0
```

## Build

Build libraries and test programs:

```bash
make
```

This will build:

```text
libezcdf.a
libezcdf.so
eztest
eztest2
```

Additional targets:

```bash
make libezcdf.a
make libezcdf.so
make eztest
make eztest2

make clean
make clobber
```

where:

* `clean` removes object files and module files.
* `clobber` removes all generated files, including libraries and test programs.

## Test

Fortran test program:

```bash
./eztest
```

This test writes and re-reads a simple NetCDF file:

```text
EZtest.nc
```

and a larger test file:

```text
bigFile.nc
```

The contents should match the reference data provided in `ref/`.

C++ test program:

```bash
./eztest2
```

This test exercises the C++ wrapper interface and creates:

```text
EZtest.cdf
```

## Install

Installation location is controlled by the `PREFIX` variable.

If not specified, the default installation location is:

```text
./builds
```

Install:

```bash
make install
```

or

```bash
make install PREFIX=/path/to/install
```

This installs files into:

```text
<PREFIX>/lib
<PREFIX>/include
<PREFIX>/mod
<PREFIX>/bin
```

Remove an installation:

```bash
make uninstall
```

## Notes

* EZCDF depends on NetCDF C and NetCDF Fortran.
* HDF5 is required indirectly through the NetCDF installation.
* The C++ example program may produce warnings with modern C++ compilers because the legacy implementation throws exceptions from a destructor. This behavior is retained for backward compatibility.

## Contributing

Contributions to this repository are welcome, particularly bug fixes, portability improvements, and build-system updates.

All changes must be submitted through a pull request from a branch based on `main`.

The pull request must:

* Pass all CI tests.
* Be labeled with exactly one of:

  * `patch`
  * `minor`
  * `major`
* Be reviewed by at least one CODEOWNER.

Version numbers follow semantic versioning:

* `patch` – bug fixes and maintenance updates.
* `minor` – new functionality that maintains backward compatibility.
* `major` – significant changes that may break backward compatibility.

The CI pipeline validates label usage and will fail if an appropriate label is not provided.
