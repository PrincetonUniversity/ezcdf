# ---------------------------------------------------------------------------
# EZCDF Makefile
#
# Common Linux Makefile
#
# This Makefile is independent of:
#
#     - Linux compute system / cluster
#     - compiler family
#     - compiler version
#     - NetCDF installation layout
#     - HDF5 installation layout
#
# Machine- and compiler-specific configuration must be supplied by the
# environment before running make.
#
# Expected environment variables:
#
#     FC              Fortran compiler
#     CC              C compiler
#     CXX             C++ compiler
#
#     FFLAGS          Fortran compiler flags
#     CFLAGS          C compiler flags
#     CXXFLAGS        C++ compiler flags
#
#     NETCDF_F_HOME   NetCDF Fortran installation
#     NETCDF_C_HOME   NetCDF C installation
#
#     L_NETCDF        Complete NetCDF/HDF5 link libraries
#
# Optional:
#
#     NETCDF_MODDIR   Directory containing netcdf.mod
#     FLIBROOT        Compiler Fortran runtime library directory
#     L_FLIBS         Fortran runtime libraries
#     L_CLIBS         C/C++ runtime libraries
#     LDFLAGS         Additional linker flags
#     PREFIX          Installation directory
#     DEBUG           Build-mode selector used by the environment
#
# Example:
#
#     source environ
#     make
#     make install
#
# ---------------------------------------------------------------------------

SHELL := /bin/bash


# ===========================================================================
# Compilers
#
# These should normally be supplied by the environment.
#
# Defaults are provided only as a convenience.
# ===========================================================================

FC  ?= gfortran
CC  ?= gcc
CXX ?= g++


# ===========================================================================
# Archiver
# ===========================================================================

AR      ?= ar
ARFLAGS ?= rcs


# ===========================================================================
# Source/build directories
# ===========================================================================

SRCDIR := $(CURDIR)

PREFIX ?= $(SRCDIR)/builds

LIBDIR := $(PREFIX)/lib
INCDIR := $(PREFIX)/include
MODDIR := $(PREFIX)/mod
BINDIR := $(PREFIX)/bin


# ===========================================================================
# External include directories
#
# NETCDF_MODDIR should point to the directory containing netcdf.mod when
# that directory differs from NETCDF_F_HOME/include.
#
# Examples:
#
# Flux/Lynx:
#
#     NETCDF_MODDIR may be the NetCDF Fortran include directory.
#
# Ranger:
#
#     NETCDF_MODDIR=/usr/lib64/gfortran/modules
#
# Do not encode any machine-specific paths here.
# ===========================================================================

FINCL :=

ifdef NETCDF_MODDIR
	FINCL += -I$(NETCDF_MODDIR)
endif

ifdef NETCDF_F_HOME
	FINCL += -I$(NETCDF_F_HOME)/include
endif

ifdef NETCDF_C_HOME
	FINCL += -I$(NETCDF_C_HOME)/include
endif

ifdef HDF5_HOME
	FINCL += -I$(HDF5_HOME)/include
endif


# ===========================================================================
# Compiler flags
#
# Compiler-specific options should be supplied by the environment.
#
# The defaults below are intentionally minimal and portable.
#
# IMPORTANT:
#
#     -c is NOT included here.
#
# The object compilation rule explicitly supplies -c.
#
# -fPIC or the equivalent compiler-specific PIC option must be supplied by
# the environment because the same objects are used to construct
# libezcdf.so.
# ===========================================================================

FFLAGS   ?= -O2 -g
CFLAGS   ?= -O2 -g
CXXFLAGS ?= -O2 -g


# ===========================================================================
# Linker flags
# ===========================================================================

LDFLAGS ?=


# ===========================================================================
# External libraries
#
# L_NETCDF must be supplied by the environment.
#
# It must contain everything necessary to link NetCDF Fortran and NetCDF C.
# If the particular NetCDF installation requires HDF5 libraries explicitly,
# those libraries must also be included in L_NETCDF by the environment.
#
# This is intentionally NOT reconstructed here because the library layout
# differs between Flux, Lynx, Ranger, and potentially other systems.
# ===========================================================================

L_NETCDF ?=


# ===========================================================================
# Compiler runtime libraries
#
# These are optional because the compiler driver often supplies its own
# runtime automatically.
#
# They can be provided by the environment when explicit runtime linking or
# RPATH information is required.
# ===========================================================================

L_FLIBS ?=
L_CLIBS ?=


# ===========================================================================
# Library names
# ===========================================================================

LIBAR := libezcdf.a
LIBSO := libezcdf.so


# ===========================================================================
# Test executable names
# ===========================================================================

EXEF90 := eztest
EXECXX := eztest2


# ===========================================================================
# Sources
# ===========================================================================

SRCS := \
	ezcdf_inqvar.f90 \
	ezcdf_opncls.f90 \
	ezcdf_attrib.f90 \
	ezcdf_genget.f90 \
	ezcdf_genput.f90 \
	ezcdf.f90 \
	handle_err.f90


# ===========================================================================
# Objects
# ===========================================================================

OBJS := $(SRCS:.f90=.o)


# ===========================================================================
# Phony targets
# ===========================================================================

.PHONY: \
	all \
	check-env \
	show \
	install \
	uninstall \
	clean \
	clobber


# ===========================================================================
# Main target
# ===========================================================================

all: check-env $(LIBAR) $(LIBSO) $(EXEF90) $(EXECXX)


# ===========================================================================
# Environment validation
# ===========================================================================

check-env:
	@command -v "$(FC)" >/dev/null 2>&1 || { \
		echo "ERROR: Fortran compiler not found: $(FC)"; \
		exit 1; \
	}
	@command -v "$(CXX)" >/dev/null 2>&1 || { \
		echo "ERROR: C++ compiler not found: $(CXX)"; \
		exit 1; \
	}
	@test -n "$(NETCDF_F_HOME)" || { \
		echo "ERROR: NETCDF_F_HOME is not set"; \
		exit 1; \
	}
	@test -n "$(NETCDF_C_HOME)" || { \
		echo "ERROR: NETCDF_C_HOME is not set"; \
		exit 1; \
	}
	@test -n "$(L_NETCDF)" || { \
		echo "ERROR: L_NETCDF is not set"; \
		exit 1; \
	}


# ===========================================================================
# Display configuration
# ===========================================================================

show:
	@echo
	@echo "============================================================"
	@echo " EZCDF build configuration"
	@echo "============================================================"
	@echo
	@echo "Source/build:"
	@echo "  SRCDIR         = $(SRCDIR)"
	@echo "  PREFIX         = $(PREFIX)"
	@echo "  LIBDIR         = $(LIBDIR)"
	@echo "  MODDIR         = $(MODDIR)"
	@echo "  INCDIR         = $(INCDIR)"
	@echo "  BINDIR         = $(BINDIR)"
	@echo
	@echo "Compilers:"
	@echo "  FC             = $(FC)"
	@echo "  CC             = $(CC)"
	@echo "  CXX            = $(CXX)"
	@echo
	@echo "Compiler flags:"
	@echo "  FFLAGS         = $(FFLAGS)"
	@echo "  CFLAGS         = $(CFLAGS)"
	@echo "  CXXFLAGS       = $(CXXFLAGS)"
	@echo "  LDFLAGS        = $(LDFLAGS)"
	@echo
	@echo "NetCDF/HDF5:"
	@echo "  NETCDF_F_HOME  = $(NETCDF_F_HOME)"
	@echo "  NETCDF_C_HOME  = $(NETCDF_C_HOME)"
	@echo "  NETCDF_MODDIR  = $(NETCDF_MODDIR)"
	@echo "  HDF5_HOME      = $(HDF5_HOME)"
	@echo "  FINCL          = $(FINCL)"
	@echo "  L_NETCDF       = $(L_NETCDF)"
	@echo
	@echo "Compiler runtime:"
	@echo "  FLIBROOT       = $(FLIBROOT)"
	@echo "  L_FLIBS        = $(L_FLIBS)"
	@echo "  L_CLIBS        = $(L_CLIBS)"
	@echo
	@echo "============================================================"


# ===========================================================================
# Static library
# ===========================================================================

$(LIBAR): $(OBJS)
	@echo
	@echo "Building EZCDF static library"
	@echo "  $@"
	@echo
	@rm -f $@
	$(AR) $(ARFLAGS) $@ $(OBJS)


# ===========================================================================
# Shared library
#
# The Fortran compiler driver is used for the final link because the EZCDF
# implementation is primarily Fortran.
#
# The object files must have been compiled with the compiler-appropriate
# position-independent-code option supplied through FFLAGS.
# ===========================================================================

$(LIBSO): $(OBJS)
	@echo
	@echo "Building EZCDF shared library"
	@echo "  $@"
	@echo
	@rm -f $@
	$(FC) -shared \
		$(LDFLAGS) \
		-o $@ \
		$(OBJS) \
		$(L_NETCDF) \
		$(L_FLIBS)


# ===========================================================================
# Fortran test executable
#
# Link explicitly against the shared library produced in the source
# directory.
#
# Embed the source directory as an RPATH so the test can be run before
# installation.
# ===========================================================================

$(EXEF90): $(LIBSO) $(EXEF90).f90
	@echo
	@echo "Building $(EXEF90)"
	@echo
	$(FC) \
		$(FFLAGS) \
		$(FINCL) \
		$(EXEF90).f90 \
		-o $@ \
		$(LDFLAGS) \
		-L$(SRCDIR) \
		-lezcdf \
		-Wl,-rpath,$(SRCDIR) \
		$(L_NETCDF) \
		$(L_FLIBS)


# ===========================================================================
# C++ test executable
#
# Link with the C++ compiler driver because the main program is C++.
#
# L_CLIBS and L_FLIBS may be supplied by the environment when the compiler
# family requires explicit runtime libraries.
# ===========================================================================

$(EXECXX): $(LIBSO) $(EXECXX).cc
	@echo
	@echo "Building $(EXECXX)"
	@echo
	$(CXX) \
		$(CXXFLAGS) \
		$(FINCL) \
		$(EXECXX).cc \
		-o $@ \
		$(LDFLAGS) \
		-L$(SRCDIR) \
		-lezcdf \
		-Wl,-rpath,$(SRCDIR) \
		$(L_NETCDF) \
		$(L_CLIBS) \
		$(L_FLIBS)


# ===========================================================================
# Fortran object compilation
#
# -c is supplied explicitly here rather than through FFLAGS.
# ===========================================================================

%.o: %.f90
	$(FC) \
		$(FFLAGS) \
		$(FINCL) \
		-c $< \
		-o $@


# ===========================================================================
# Install
# ===========================================================================

install: all
	@echo
	@echo "Installing EZCDF"
	@echo "  PREFIX = $(PREFIX)"
	@echo

	@mkdir -p $(LIBDIR)
	@mkdir -p $(INCDIR)
	@mkdir -p $(MODDIR)
	@mkdir -p $(BINDIR)

	@cp ezcdf.hh $(INCDIR)

	@if ls *.mod >/dev/null 2>&1; then \
		cp *.mod $(MODDIR); \
	fi

	@if [ -d ref ]; then \
		rm -rf $(PREFIX)/ref; \
		cp -r ref $(PREFIX)/ref; \
	fi

	@cp $(LIBAR) $(LIBDIR)
	@cp $(LIBSO) $(LIBDIR)

	@if [ -f $(EXEF90) ]; then \
		cp $(EXEF90) $(BINDIR); \
	fi

	@if [ -f $(EXECXX) ]; then \
		cp $(EXECXX) $(BINDIR); \
	fi

	@echo
	@echo "Installed:"
	@echo "  $(LIBDIR)/$(LIBAR)"
	@echo "  $(LIBDIR)/$(LIBSO)"
	@echo "  $(MODDIR)"
	@echo "  $(INCDIR)"
	@echo "  $(BINDIR)"
	@echo


# ===========================================================================
# Uninstall
# ===========================================================================

uninstall:
	@echo "Removing EZCDF installation:"
	@echo "  $(PREFIX)"
	@rm -rf $(PREFIX)


# ===========================================================================
# Clean
# ===========================================================================

clean:
	@echo "Cleaning EZCDF objects and modules"
	@rm -f *~
	@rm -f $(OBJS)
	@rm -f *.mod


# ===========================================================================
# Complete cleanup
# ===========================================================================

clobber: clean
	@echo "Removing EZCDF libraries and test executables"
	@rm -f $(LIBAR)
	@rm -f $(LIBSO)
	@rm -f $(EXEF90)
	@rm -f $(EXECXX)
