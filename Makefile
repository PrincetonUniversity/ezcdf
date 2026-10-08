# ezcdf makefile

SHELL := /bin/bash

# ---------------------------------------------------------------------------
# NetCDF installation paths
# ---------------------------------------------------------------------------

ifeq ($(strip $(NETCDF_C_HOME)),)
NETCDF_C_HOME := $(shell nc-config --prefix 2>/dev/null)
endif

ifeq ($(strip $(NETCDF_F_HOME)),)
NETCDF_F_HOME := $(shell nf-config --prefix 2>/dev/null)
endif

ifeq ($(strip $(NETCDF_ROOT)),)
NETCDF_ROOT := $(NETCDF_C_HOME)
endif

export NETCDF_C_HOME NETCDF_F_HOME NETCDF_ROOT

# ---------------------------------------------------------------------------
# NetCDF configuration
# ---------------------------------------------------------------------------

NC_CONFIG_OK := $(shell command -v nc-config >/dev/null 2>&1 && echo yes || echo no)
NF_CONFIG_OK := $(shell command -v nf-config >/dev/null 2>&1 && echo yes || echo no)

ifeq ($(NC_CONFIG_OK),yes)
  FINCL = -I$(shell nc-config --includedir)
  FLIBS = -L$(shell nc-config --libdir) -lnetcdf
else
  FINCL = -I$(NETCDF_ROOT)/include
  FLIBS = -L$(NETCDF_ROOT)/lib -lnetcdf
  $(warning nc-config not found; using NETCDF_ROOT from environment/command line.)
endif

ifeq ($(NF_CONFIG_OK),yes)
  FINCL += -I$(shell nf-config --includedir)
  FLIBS += -L$(shell nf-config --prefix)/lib -lnetcdff
else
  FINCL += -I$(NETCDF_ROOT)/include
  FLIBS += -L$(NETCDF_ROOT)/lib -lnetcdff
  $(warning nf-config not found; using NETCDF_ROOT from environment/command line.)
endif

# ---------------------------------------------------------------------------
# Compiler flags
# ---------------------------------------------------------------------------

ifneq (,$(findstring icc, $(CC)))
        FFLAGS = -O2 -nowarn -ftz -traceback -heap-arrays 20 -fPIC
        DFFLAGS = -g -traceback -check all -warn all
        CXXFLAGS = -O2
        CXXLIBS = -lifcore

else ifneq (,$(findstring pgcc, $(CC)))
        FFLAGS = -O -Mnoupcase -Mdalign -Mdefaultunit -Ktrap=fp -fPIC -D_PGC
        DFFLAGS = -g -Mnoupcase -Mdalign -Mdefaultunit -Minform=inform -Ktrap=fp -Mbounds
        CXXFLAGS = -O2 -mp
        CXXLIBS = -lstdc++ -lpgf90 -lpgf90rtl

else
        FC = gfortran
        CC = gcc
        FFLAGS = -g -O3 -m64 -fno-range-check -fdollar-ok -fPIC
        GCCVERSION = $(shell gcc -dumpversion | cut -f1 -d.)

ifeq ($(shell test $(GCCVERSION) -gt 9; echo $$?),0)
        FFLAGS += -fallow-argument-mismatch
endif

        DFFLAGS = -Og -Wall
        CXXFLAGS = -O2
        CXXLIBS = -lstdc++ -lgfortran
endif

# ---------------------------------------------------------------------------
# Define directories and library names
# ---------------------------------------------------------------------------

SRCDIR := $(shell pwd)

PREFIX := $(or $(PREFIX),$(SRCDIR)/builds)
LIBDIR := $(PREFIX)/lib
INCDIR := $(PREFIX)/include
MODDIR := $(PREFIX)/mod
BINDIR := $(PREFIX)/bin

LIBAR := libezcdf.a
LIBSO := libezcdf.so

EXEF90 := eztest
EXECXX := eztest2

# ---------------------------------------------------------------------------
# Define objects
# ---------------------------------------------------------------------------

SRCS := ezcdf_inqvar.f90 \
        ezcdf_opncls.f90 \
        ezcdf_attrib.f90 \
        ezcdf_genget.f90 \
        ezcdf_genput.f90 \
        ezcdf.f90 \
        handle_err.f90

OBJS := $(SRCS:.f90=.o)

.PHONY: clean clobber install uninstall

# ---------------------------------------------------------------------------
# Build libraries and executables
# ---------------------------------------------------------------------------

all: $(LIBAR) $(LIBSO) eztest eztest2

$(LIBAR): $(OBJS)
	ar r $@ $(OBJS)

$(LIBSO): $(OBJS)
	$(FC) -shared -o $(LIBSO) $(OBJS)

eztest:
	$(FC) $(FFLAGS) $@.f90 -o $@ -L$(SRCDIR) -lezcdf $(FLIBS)

eztest2:
	$(CXX) $(CXXFLAGS) $(FINCL) $@.cc -o $@ $(CXXLIBS) -L$(SRCDIR) -lezcdf $(FLIBS)

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install:
	@test -d $(LIBDIR) || mkdir -p $(LIBDIR)
	@test -d $(INCDIR) || mkdir -p $(INCDIR)
	@test -d $(MODDIR) || mkdir -p $(MODDIR)
	@test -d $(BINDIR) || mkdir -p $(BINDIR)
	@cp ezcdf.hh $(INCDIR)
	@cp *.mod $(MODDIR)
	@cp -r ref $(PREFIX)
	@test ! -f $(LIBAR) || cp $(LIBAR) $(LIBDIR)
	@test ! -f $(LIBSO) || cp $(LIBSO) $(LIBDIR)
	@test ! -f $(EXEF90) || cp $(EXEF90) $(BINDIR)
	@test ! -f $(EXECXX) || cp $(EXECXX) $(BINDIR)

# ---------------------------------------------------------------------------
# Compile objects
# ---------------------------------------------------------------------------

$(OBJS):

%.o: %.f90
	$(FC) -c $(FFLAGS) $< -o $@ $(FINCL)

# ---------------------------------------------------------------------------
# Uninstall / Clean
# ---------------------------------------------------------------------------

uninstall:
	@rm -rf $(PREFIX)

clean:
	@rm -f *~
	@rm -f $(OBJS) *.mod

clobber: clean
	@rm -f $(LIBAR) $(LIBSO)
	@rm -f $(EXEF90) $(EXECXX)
