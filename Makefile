# ezcdf makefile

SHELL:=/bin/bash

FLIBS =
FINCL =

ifneq (,$(shell which nf-config))
        FINCL += -I`nf-config --includedir`
        FLIBS += `nf-config --flibs`
endif

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
        FFLAGS = -g -O2 -m64 -ffpe-trap=invalid,zero,overflow -fno-range-check -fdollar-ok -fPIC
	GCCVERSION = $(shell gcc -dumpversion | cut -f1 -d.)
ifeq ($(shell test $(GCCVERSION) -gt 9; echo $$?),0)
	FFLAGS += -fallow-argument-mismatch
endif
        DFFLAGS = -Og -Wall
        CXXFLAGS = -O2
        CXXLIBS = -lstdc++ -lgfortran
endif

# Define directories and library names
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

# Define the objects
SRCS :=	ezcdf_inqvar.f90 \
	ezcdf_opncls.f90 \
	ezcdf_attrib.f90 \
	ezcdf_genget.f90 \
	ezcdf_genput.f90 \
	ezcdf.f90 \
	handle_err.f90
OBJS :=	$(SRCS:.f90=.o)


.PHONY: clean clobber install uninstall

all:	$(LIBAR) $(LIBSO) eztest eztest2

$(LIBAR): $(OBJS)
	@ar r $@ $(OBJS)

$(LIBSO): $(OBJS)
	@$(FC) -shared -o $(LIBSO) $(OBJS)

eztest:
	@$(FC) $(FFLAGS) $@.f90 -o $@ -L$(SRCDIR) -lezcdf $(FLIBS)

eztest2:
	@$(CXX) $(CXXFLAGS) $@.cc -o $@ $(CXXLIBS) -L$(SRCDIR) -lezcdf $(FLIBS)

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

$(OBJS) :
%.o: %.f90
	@$(FC) -c $(FFLAGS) $< -o $@ $(FINCL)

uninstall:
	@rm -rf $(PREFIX)

clean:
	@rm -f *~
	@rm -f $(OBJS) *.mod

clobber: clean
	@rm -f $(LIBAR) $(LIBSO)
	@rm -f $(EXEF90) $(EXECXX)
