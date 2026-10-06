# EZCDF

## About

EZCDF (**Easy Interface to NetCDF**) provides a simplified interface to NetCDF routine calls. It is intended to reduce the complexity of reading and writing NetCDF files from Fortran applications.

EZCDF provides both:

- a Fortran interface;
- a C++ wrapper interface.

See `USERGUIDE` for additional details and usage examples.

## Contact

transp_support@pppl.gov

---

## History

```text
Feb 1999   - Created
Apr 2000   - A. Pletzer: Added R4 support
May 2000   - C. Ludescher-Furth: Simplified by adding module ezcdf
May 2001   - A. Pletzer: Added C8 and C16 support
Oct 2002   - S. Hirshman: Added LOG support and reworked interfaces
Sept 2019  - Migrated to GitHub
May 2026   - Updated build system for GCC 13.4.0, OpenMPI 5.0.10,
             NetCDF 4.9.3, and NetCDF-Fortran 4.6.2 on Lynx
Oct 2026   - Introduced a common Linux Makefile independent of machine
             and compiler configuration. Machine/compiler-specific setup
             is now provided through environment files.
```

---

## Contents

The following Fortran sources are used to build the EZCDF static and shared libraries:

```text
ezcdf.f90
ezcdf_attrib.f90
ezcdf_genget.f90
ezcdf_genput.f90
ezcdf_inqvar.f90
ezcdf_opncls.f90
handle_err.f90
```

The build produces:

```text
libezcdf.a
libezcdf.so
```

and the corresponding Fortran module files (`*.mod`).

Test programs and C++ interface:

```text
eztest.f90       - Fortran test/example program
eztest2.cc       - C++ test/example program
ezcdf.hh         - C++ wrapper interface
```

Reference test data are stored under:

```text
ref/
```

---

# Building EZCDF

## Build-system organization

EZCDF now uses a **common Linux Makefile**.

The Makefile does not contain machine-specific compiler, NetCDF, HDF5, or runtime-library paths.

Machine- and compiler-specific configuration is supplied through an environment file before running `make`.

The general procedure is:

```bash
source <environment-file>

make show
make
make install
```

The same Makefile can therefore be used on different Linux systems without modification.

Current supported PPPL configurations include:

```text
Flux    GCC 13.2.0
Lynx    GCC 13.4.0
Ranger  GCC Toolset 13 / GCC 13.3.0
```

Additional compiler or machine configurations can be added by creating an appropriate environment file rather than modifying the Makefile.

---

## Prerequisites

EZCDF requires:

- a Fortran compiler;
- a C++ compiler for the C++ test program;
- NetCDF C;
- NetCDF Fortran;
- HDF5 when required by the NetCDF installation.

The environment file is responsible for defining the compiler and external-library configuration needed by the common Makefile.

Important variables include:

```text
FC
CC
CXX

FFLAGS
CFLAGS
CXXFLAGS

NETCDF_F_HOME
NETCDF_C_HOME
NETCDF_MODDIR
HDF5_HOME

L_NETCDF
L_FLIBS
L_CLIBS
```

Not every system requires every variable. For example, `NETCDF_MODDIR` is needed when `netcdf.mod` is installed outside `${NETCDF_F_HOME}/include`.

The environment should also set any required runtime search paths such as `LD_LIBRARY_PATH`.

---

# Machine Environments

## Flux — GCC 13.2.0

The Flux environment uses:

```text
GCC               13.2.0
OpenMPI            4.1.6
NetCDF-Fortran     4.6.1
```

The required modules include:

```bash
module purge

module load gcc/13.2.0-gcc-11.4.1-wykjv
module load openmpi/4.1.6-gcc-13.2.0

module load openmpi-4.1.6/gcc-13.2.0/netcdf-c/main-4adke
module load openmpi-4.1.6/gcc-13.2.0/netcdf-fortran/4.6.1-53pdx
```

The Flux environment file defines the NetCDF library layout:

```text
NetCDF Fortran libraries : ${NETCDF_F_HOME}/lib
NetCDF C libraries       : ${NETCDF_C_HOME}/lib64
```

Source the corresponding Flux environment before building.

---

## Lynx — GCC 13.4.0

The Lynx environment uses:

```text
GCC               13.4.0
OpenMPI            5.0.10
HDF5               1.14.6
NetCDF-C            4.9.3
NetCDF-Fortran      4.6.2
```

The required modules are:

```bash
module purge

module load gcc-runtime/13.4.0
module load gcc/13.4.0
module load openmpi/5.0.10-gcc-13.4.0
module load hdf5/1.14.6-gcc-13.4.0
module load netcdf-c/4.9.3-gcc-13.4.0
module load netcdf-fortran/4.6.2-gcc-13.4.0
```

Source the corresponding Lynx environment before building.

---

## Ranger — GCC Toolset 13

Ranger uses GCC Toolset 13 together with system RPM installations of OpenMPI, HDF5, and NetCDF.

The GCC Toolset shell should first be enabled:

```bash
scl enable gcc-toolset-13 bash
```

The Ranger environment then configures:

```text
GCC_ROOT            /opt/rh/gcc-toolset-13/root/usr
OPENMPI_HOME         /usr/lib64/openmpi
HDF5_HOME            /usr
NETCDF_C_HOME        /usr
NETCDF_F_HOME        /usr
NETCDF_MODDIR        /usr/lib64/gfortran/modules
```

The Ranger environment must be sourced after enabling GCC Toolset 13.

---

# Build Procedure

## 1. Source the environment

Source the environment corresponding to the machine and compiler being used.

For example:

```bash
source environ
```

The exact pathname depends on the installation and machine configuration.

Verify that the expected compiler is active:

```bash
which gfortran
gfortran --version
```

The NetCDF installation can also be checked with:

```bash
echo "$NETCDF_F_HOME"
echo "$NETCDF_C_HOME"
echo "$NETCDF_MODDIR"
```

---

## 2. Display the build configuration

Before compiling, the current configuration can be inspected with:

```bash
make show
```

This displays the compiler commands, compiler flags, NetCDF/HDF5 configuration, installation directories, and external libraries that will be used.

This step is recommended when building on a new system or after changing an environment file.

---

## 3. Clean an existing build

When changing compilers, compiler versions, or external library installations, remove objects and Fortran module files from the previous build:

```bash
make clobber
```

This is particularly important because Fortran `.mod` files are compiler dependent.

---

## 4. Build

Build the EZCDF libraries and test programs:

```bash
make
```

This produces:

```text
libezcdf.a
libezcdf.so
eztest
eztest2
```

The build also creates the EZCDF Fortran module files.

Individual targets can be built with:

```bash
make libezcdf.a
make libezcdf.so
make eztest
make eztest2
```

---

# Static and Shared Libraries

EZCDF builds both a static and a shared library.

The static library is:

```text
libezcdf.a
```

The shared library is:

```text
libezcdf.so
```

The Fortran source objects are compiled as position-independent code so that the same objects can be used to construct both libraries.

For GNU compilers this requires:

```text
-fPIC
```

The appropriate compiler-specific option is supplied by the environment rather than being hard-coded in the common Makefile.

The shared library is linked against the NetCDF/HDF5 libraries supplied through:

```text
L_NETCDF
```

Machine-specific NetCDF and HDF5 library layouts therefore remain outside the common Makefile.

---

# Testing

## Fortran test

Run:

```bash
./eztest
```

The Fortran test writes and re-reads NetCDF files including:

```text
EZtest.nc
bigFile.nc
```

The results can be compared with the reference data supplied under:

```text
ref/
```

---

## C++ test

Run:

```bash
./eztest2
```

The C++ test exercises the EZCDF C++ wrapper interface and creates:

```text
EZtest.cdf
```

---

## Check the shared-library dependencies

On Linux, the shared-library dependencies can be inspected with:

```bash
ldd libezcdf.so
```

There should be no entries reported as:

```text
not found
```

A more complete runtime relocation check can be performed with:

```bash
ldd -r libezcdf.so
```

The direct ELF dependencies can be inspected with:

```bash
readelf -d libezcdf.so | grep NEEDED
```

These checks are recommended before installing a newly built EZCDF library.

---

# Installation

The installation location is controlled by:

```text
PREFIX
```

If `PREFIX` is not specified, the default is:

```text
./builds
```

Install using:

```bash
make install
```

A different installation location can be selected with:

```bash
make install PREFIX=/path/to/install
```

Alternatively, `PREFIX` may be exported before the build:

```bash
export PREFIX=/path/to/install

make
make install
```

The installed tree has the following structure:

```text
<PREFIX>/
├── bin/
│   ├── eztest
│   └── eztest2
│
├── include/
│   └── ezcdf.hh
│
├── lib/
│   ├── libezcdf.a
│   └── libezcdf.so
│
├── mod/
│   └── *.mod
│
└── ref/
```

The `mod/` directory contains the compiler-generated EZCDF Fortran module files.

---

# Cleaning

Remove object files and generated Fortran module files:

```bash
make clean
```

This preserves the built libraries and test executables.

Remove all generated build products:

```bash
make clobber
```

`clobber` removes:

```text
*.o
*.mod
libezcdf.a
libezcdf.so
eztest
eztest2
```

---

# Uninstall

Remove the installation under `PREFIX`:

```bash
make uninstall
```

Because this removes the complete `PREFIX` directory, verify that `PREFIX` points to the intended EZCDF installation before running this command.

---

# Adding a New Machine or Compiler

The common Makefile should normally **not be modified** when adding support for a new Linux system or compiler.

Instead, create a new environment configuration that defines:

```text
FC
CC
CXX

FFLAGS
CFLAGS
CXXFLAGS

NETCDF_F_HOME
NETCDF_C_HOME
NETCDF_MODDIR
HDF5_HOME

L_NETCDF
L_FLIBS
L_CLIBS
```

The environment is responsible for differences such as:

- compiler family and version;
- position-independent-code compiler options;
- NetCDF installation directories;
- HDF5 installation directories;
- compiler runtime libraries;
- runtime library search paths;
- machine-specific compiler compatibility options.

This keeps the EZCDF Makefile common across Flux, Lynx, Ranger, and other Linux systems.

---

# Notes

- EZCDF directly depends on NetCDF C and NetCDF Fortran.
- HDF5 may be required through the NetCDF installation.
- Both `libezcdf.a` and `libezcdf.so` are built.
- Objects used in `libezcdf.so` must be compiled as position-independent code.
- Fortran `.mod` files are compiler dependent. Rebuild EZCDF when changing compiler families or incompatible compiler versions.
- Avoid reusing `.mod` files generated by a different Fortran compiler.
- NetCDF Fortran itself must be compatible with the Fortran compiler used to build EZCDF.
- Machine- and compiler-specific paths should be kept in environment files rather than added to the common Makefile.
- The C++ example program may produce warnings with modern C++ compilers because the legacy implementation throws exceptions from a destructor. This behavior is retained for backward compatibility.

---

# Contributing

Contributions to this repository are welcome, particularly bug fixes, portability improvements, and build-system updates.

All changes must be submitted through a pull request from a branch based on `main`.

The pull request must:

- pass all CI tests;
- be reviewed by at least one CODEOWNER;
- be labeled with exactly one of:

  - `patch`
  - `minor`
  - `major`

Version numbers follow semantic versioning:

- `patch` — bug fixes and maintenance updates;
- `minor` — new functionality that maintains backward compatibility;
- `major` — significant changes that may break backward compatibility.

The CI pipeline validates label usage and will fail if an appropriate label is not provided.