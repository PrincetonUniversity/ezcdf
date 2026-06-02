# ezcdf Makefile for Lynx, GCC 13.4.0

SHELL := /bin/bash

# Compiler setup
FC  ?= gfortran
CC  ?= gcc
CXX ?= g++

AR      := ar
ARFLAGS := rcs

# Directories
SRCDIR := $(shell pwd)

PREFIX ?= $(SRCDIR)/builds
LIBDIR := $(PREFIX)/lib
INCDIR := $(PREFIX)/include
MODDIR := $(PREFIX)/mod
BINDIR := $(PREFIX)/bin

# NetCDF / HDF5 paths are expected from loaded modules
# Required modules:
#   module load gcc-runtime/13.4.0
#   module load gcc/13.4.0
#   module load hdf5/1.14.6-gcc-13.4.0
#   module load netcdf-c/4.9.3-gcc-13.4.0
#   module load netcdf-fortran/4.6.2-gcc-13.4.0

FINCL := -I$(NETCDF_F_HOME)/include \
         -I$(NETCDF_C_HOME)/include

FLIBS := -Wl,-rpath,$(NETCDF_F_HOME)/lib \
         -L$(NETCDF_F_HOME)/lib -lnetcdff \
         -Wl,-rpath,$(NETCDF_C_HOME)/lib64 \
         -L$(NETCDF_C_HOME)/lib64 -lnetcdf \
         -Wl,-rpath,$(HDF5_HOME)/lib \
         -L$(HDF5_HOME)/lib -lhdf5_fortran -lhdf5_hl -lhdf5

ifdef GCC_RUNTIME_ROOT
  GCCRT := $(GCC_RUNTIME_ROOT)/lib
  FLIBS += -Wl,-rpath,$(GCCRT) -L$(GCCRT) -lgfortran -lstdc++ -lgcc_s
endif

FFLAGS  := -g -O2 -m64 -fPIC -fallow-argument-mismatch \
           -fno-range-check -fdollar-ok

CXXFLAGS := -g -O2 -m64 -fPIC

# Library names
LIBAR := libezcdf.a
LIBSO := libezcdf.so

EXEF90 := eztest
EXECXX := eztest2

# Sources
SRCS := ezcdf_inqvar.f90 \
        ezcdf_opncls.f90 \
        ezcdf_attrib.f90 \
        ezcdf_genget.f90 \
        ezcdf_genput.f90 \
        ezcdf.f90 \
        handle_err.f90

OBJS := $(SRCS:.f90=.o)

.PHONY: all clean clobber install uninstall check-env

all: check-env $(LIBAR) $(LIBSO) $(EXEF90) $(EXECXX)

check-env:
	@test -n "$(NETCDF_F_HOME)" || { echo "ERROR: NETCDF_F_HOME is not set"; exit 1; }
	@test -n "$(NETCDF_C_HOME)" || { echo "ERROR: NETCDF_C_HOME is not set"; exit 1; }
	@test -n "$(HDF5_HOME)"     || { echo "ERROR: HDF5_HOME is not set"; exit 1; }

$(LIBAR): $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

$(LIBSO): $(OBJS)
	$(FC) -shared -o $@ $(OBJS) $(FLIBS)

$(EXEF90): $(LIBAR)
	$(FC) $(FFLAGS) $@.f90 -o $@ -L$(SRCDIR) -lezcdf $(FLIBS) $(FINCL)

$(EXECXX): $(LIBAR)
	$(CXX) $(CXXFLAGS) $@.cc -o $@ -L$(SRCDIR) -lezcdf $(FLIBS) $(FINCL)

%.o: %.f90
	$(FC) -c $(FFLAGS) $< -o $@ $(FINCL)

install:
	@test -d $(LIBDIR) || mkdir -p $(LIBDIR)
	@test -d $(INCDIR) || mkdir -p $(INCDIR)
	@test -d $(MODDIR) || mkdir -p $(MODDIR)
	@test -d $(BINDIR) || mkdir -p $(BINDIR)
	cp ezcdf.hh $(INCDIR)
	cp *.mod $(MODDIR)
	cp -r ref $(PREFIX)
	@test ! -f $(LIBAR) || cp $(LIBAR) $(LIBDIR)
	@test ! -f $(LIBSO) || cp $(LIBSO) $(LIBDIR)
	@test ! -f $(EXEF90) || cp $(EXEF90) $(BINDIR)
	@test ! -f $(EXECXX) || cp $(EXECXX) $(BINDIR)

uninstall:
	rm -rf $(PREFIX)

clean:
	rm -f *~
	rm -f $(OBJS) *.mod

clobber: clean
	rm -f $(LIBAR) $(LIBSO)
	rm -f $(EXEF90) $(EXECXX)
