# ======================================================================
# EZCDF Makefile
#
# Builds:
#   libezcdf.a
#   libezcdf.so
#   eztest
#   eztest2
#
# Supported environments:
#   - PPPL Flux / Rocky Linux / Spack
#   - GitHub Actions / Ubuntu
#   - Standard Linux NetCDF installations
#
# NetCDF C and NetCDF Fortran may be installed in different directories.
# Both lib and lib64 layouts are supported.
# ======================================================================

SHELL := /bin/bash


# ======================================================================
# Compiler configuration
# ======================================================================

# GNU Make defines FC=f77 and CC=cc by default.
# Replace those built-in defaults while allowing command-line and
# environment overrides.

ifeq ($(origin FC),default)
FC := gfortran
endif

ifeq ($(origin CC),default)
CC := gcc
endif

ifeq ($(origin CXX),default)
CXX := g++
endif

AR ?= ar


# ======================================================================
# NetCDF configuration utilities
# ======================================================================

NC_CONFIG := $(shell command -v nc-config 2>/dev/null)
NF_CONFIG := $(shell command -v nf-config 2>/dev/null)

NC_CONFIG_OK := $(if $(NC_CONFIG),yes,no)
NF_CONFIG_OK := $(if $(NF_CONFIG),yes,no)


# ======================================================================
# NetCDF installation paths
#
# Priority:
#
#   1. Environment or command-line variables
#   2. nc-config / nf-config
#   3. NETCDF_ROOT
#
# NetCDF C and Fortran installations may differ.
# ======================================================================

ifeq ($(strip $(NETCDF_C_HOME)),)
ifneq ($(NC_CONFIG_OK),no)
NETCDF_C_HOME := $(shell nc-config --prefix)
else
NETCDF_C_HOME := $(NETCDF_ROOT)
endif
endif

ifeq ($(strip $(NETCDF_F_HOME)),)
ifneq ($(NF_CONFIG_OK),no)
NETCDF_F_HOME := $(shell nf-config --prefix)
else
NETCDF_F_HOME := $(NETCDF_ROOT)
endif
endif

ifeq ($(strip $(NETCDF_ROOT)),)
NETCDF_ROOT := $(NETCDF_C_HOME)
endif

export NETCDF_C_HOME
export NETCDF_F_HOME
export NETCDF_ROOT


# ======================================================================
# NetCDF include directories
# ======================================================================

ifneq ($(NC_CONFIG_OK),no)

NETCDF_C_INCDIR := $(shell nc-config --includedir)

else

NETCDF_C_INCDIR := $(NETCDF_C_HOME)/include

endif


ifneq ($(NF_CONFIG_OK),no)

NETCDF_F_INCDIR := $(shell nf-config --includedir)

else

NETCDF_F_INCDIR := $(NETCDF_F_HOME)/include

endif


FINCL := -I$(NETCDF_C_INCDIR) -I$(NETCDF_F_INCDIR)


# ======================================================================
# NetCDF library directories
#
# IMPORTANT:
#
# On PPPL Flux:
#
#   NetCDF Fortran:
#       $(NETCDF_F_HOME)/lib
#
#   NetCDF C:
#       $(NETCDF_C_HOME)/lib64
#
# nf-config --flibs may omit the NetCDF C library directory.
# ======================================================================

# NetCDF C library directory

ifneq ($(NC_CONFIG_OK),no)

NETCDF_C_LIBDIR := $(shell nc-config --libdir)

else

ifneq ($(wildcard $(NETCDF_C_HOME)/lib64/libnetcdf.so*),)

NETCDF_C_LIBDIR := $(NETCDF_C_HOME)/lib64

else

NETCDF_C_LIBDIR := $(NETCDF_C_HOME)/lib

endif

endif


# NetCDF Fortran library directory

ifneq ($(wildcard $(NETCDF_F_HOME)/lib/libnetcdff.so*),)

NETCDF_F_LIBDIR := $(NETCDF_F_HOME)/lib

else ifneq ($(wildcard $(NETCDF_F_HOME)/lib64/libnetcdff.so*),)

NETCDF_F_LIBDIR := $(NETCDF_F_HOME)/lib64

else

NETCDF_F_LIBDIR := $(NETCDF_F_HOME)/lib

endif


# ======================================================================
# NetCDF linker flags
#
# Explicitly provide both library directories.
#
# Preserve additional dependencies reported by nf-config.
#
# Order:
#
#   -L NetCDF Fortran
#   -L NetCDF C
#   -lnetcdff
#   -lnetcdf
#
# This works with separate Spack installations.
# ======================================================================

ifneq ($(NF_CONFIG_OK),no)

NETCDF_CONFIG_LIBS := $(shell nf-config --flibs)

FLIBS := \
	-L$(NETCDF_F_LIBDIR) \
	-L$(NETCDF_C_LIBDIR) \
	$(NETCDF_CONFIG_LIBS)

else

FLIBS := \
	-L$(NETCDF_F_LIBDIR) \
	-L$(NETCDF_C_LIBDIR) \
	-lnetcdff \
	-lnetcdf

endif


# ======================================================================
# Compiler flags
# ======================================================================

ifneq (,$(findstring icc,$(CC)))

FFLAGS = -O2 -nowarn -ftz -traceback -heap-arrays 20 -fPIC
DFFLAGS = -g -traceback -check all -warn all

CXXFLAGS = -O2
CXXLIBS = -lifcore

else ifneq (,$(findstring pgcc,$(CC)))

FFLAGS = -O -Mnoupcase -Mdalign -Mdefaultunit -Ktrap=fp -fPIC -D_PGC
DFFLAGS = -g -Mnoupcase -Mdalign -Mdefaultunit -Minform=inform -Ktrap=fp -Mbounds

CXXFLAGS = -O2 -mp
CXXLIBS = -lstdc++ -lpgf90 -lpgf90rtl

else

FFLAGS = -g -O3 -m64 -fno-range-check -fdollar-ok -fPIC

GCCVERSION := $(shell $(FC) -dumpversion 2>/dev/null | cut -f1 -d.)

ifneq ($(filter 10 11 12 13 14 15 16 17 18 19 20,$(GCCVERSION)),)
FFLAGS += -fallow-argument-mismatch
endif

DFFLAGS = -Og -Wall

CXXFLAGS = -O2
CXXLIBS = -lstdc++ -lgfortran

endif


# ======================================================================
# Build directories
# ======================================================================

SRCDIR := $(CURDIR)

PREFIX ?= $(SRCDIR)/builds

# Guard against an explicitly empty PREFIX.
ifeq ($(strip $(PREFIX)),)
PREFIX := $(SRCDIR)/builds
endif

LIBDIR := $(PREFIX)/lib
INCDIR := $(PREFIX)/include
MODDIR := $(PREFIX)/mod
BINDIR := $(PREFIX)/bin


# ======================================================================
# Library and executable names
# ======================================================================

LIBAR := libezcdf.a
LIBSO := libezcdf.so

EXEF90 := eztest
EXECXX := eztest2


# ======================================================================
# Source files
# ======================================================================

SRCS := \
	ezcdf_inqvar.f90 \
	ezcdf_opncls.f90 \
	ezcdf_attrib.f90 \
	ezcdf_genget.f90 \
	ezcdf_genput.f90 \
	ezcdf.f90 \
	handle_err.f90

OBJS := $(SRCS:.f90=.o)


# ======================================================================
# Phony targets
# ======================================================================

.PHONY: all check install uninstall clean clobber \
        show-config check-netcdf


# ======================================================================
# Default target
# ======================================================================

.DEFAULT_GOAL := all

all: check-netcdf $(LIBAR) $(LIBSO) $(EXEF90) $(EXECXX)


# ======================================================================
# NetCDF configuration checks
# ======================================================================

check-netcdf:
	@echo "========== EZCDF NetCDF configuration =========="
	@echo "FC                = $(FC)"
	@echo "CC                = $(CC)"
	@echo "CXX               = $(CXX)"
	@echo "NETCDF_C_HOME     = $(NETCDF_C_HOME)"
	@echo "NETCDF_F_HOME     = $(NETCDF_F_HOME)"
	@echo "NETCDF_C_LIBDIR   = $(NETCDF_C_LIBDIR)"
	@echo "NETCDF_F_LIBDIR   = $(NETCDF_F_LIBDIR)"
	@echo "FINCL             = $(FINCL)"
	@echo "FLIBS             = $(FLIBS)"
	@echo "================================================"

	@test -n "$(NETCDF_C_HOME)" || \
		(echo "ERROR: NETCDF_C_HOME is not defined"; exit 1)

	@test -n "$(NETCDF_F_HOME)" || \
		(echo "ERROR: NETCDF_F_HOME is not defined"; exit 1)

	@test -d "$(NETCDF_C_LIBDIR)" || \
		(echo "ERROR: NetCDF C library directory not found"; exit 1)

	@test -d "$(NETCDF_F_LIBDIR)" || \
		(echo "ERROR: NetCDF Fortran library directory not found"; exit 1)


# ======================================================================
# Show configuration
# ======================================================================

show-config:
	@echo "========== EZCDF configuration =========="
	@echo "SRCDIR          = $(SRCDIR)"
	@echo "PREFIX          = $(PREFIX)"
	@echo "LIBDIR          = $(LIBDIR)"
	@echo "INCDIR          = $(INCDIR)"
	@echo "MODDIR          = $(MODDIR)"
	@echo "BINDIR          = $(BINDIR)"
	@echo "FC              = $(FC)"
	@echo "CC              = $(CC)"
	@echo "CXX             = $(CXX)"
	@echo "FFLAGS          = $(FFLAGS)"
	@echo "FINCL           = $(FINCL)"
	@echo "FLIBS           = $(FLIBS)"
	@echo "========================================="


# ======================================================================
# Static library
# ======================================================================

$(LIBAR): $(OBJS)
	$(AR) rcs $@ $(OBJS)


# ======================================================================
# Shared library
#
# Explicitly link NetCDF Fortran and C dependencies.
#
# --no-undefined catches unresolved symbols during library creation.
# ======================================================================

$(LIBSO): $(OBJS)
	$(FC) -shared -o $@ $(OBJS) $(FLIBS)


# ======================================================================
# Fortran test executable
# ======================================================================

$(EXEF90): $(LIBAR) $(LIBSO)
	$(FC) $(FFLAGS) $@.f90 -o $@ \
		-L$(SRCDIR) -lezcdf $(FLIBS)


# ======================================================================
# C++ test executable
# ======================================================================

$(EXECXX): $(LIBAR) $(LIBSO)
	$(CXX) $(CXXFLAGS) $(FINCL) $@.cc -o $@ \
		-L$(SRCDIR) -lezcdf $(CXXLIBS) $(FLIBS)


# ======================================================================
# Compile Fortran objects
# ======================================================================

%.o: %.f90
	$(FC) -c $(FFLAGS) $(FINCL) $< -o $@


# ======================================================================
# Install
# ======================================================================

install: all
	@mkdir -p $(LIBDIR)
	@mkdir -p $(INCDIR)
	@mkdir -p $(MODDIR)
	@mkdir -p $(BINDIR)

	@cp ezcdf.hh $(INCDIR)
	@cp *.mod $(MODDIR)
	@cp -r ref $(PREFIX)

	@cp $(LIBAR) $(LIBDIR)
	@cp $(LIBSO) $(LIBDIR)

	@cp $(EXEF90) $(BINDIR)
	@cp $(EXECXX) $(BINDIR)


# ======================================================================
# Uninstall
# ======================================================================

uninstall:
	@rm -rf $(PREFIX)


# ======================================================================
# Clean
# ======================================================================

clean:
	@rm -f *~
	@rm -f $(OBJS)
	@rm -f *.mod


# ======================================================================
# Clobber
# ======================================================================

clobber: clean
	@rm -f $(LIBAR)
	@rm -f $(LIBSO)
	@rm -f $(EXEF90)
	@rm -f $(EXECXX)
