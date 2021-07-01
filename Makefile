EXEC = lpicola
BIN = ../../Binary
OPTIMIZE  = -O3

CC = mpicc
FFTW_INCL = -I/usr/local/include/
FFTW_LIBS = -L/usr/local/lib/ -lfftw3_mpi -lfftw3
GSL_INCL  = -I/usr/local/include/gsl/
GSL_LIBS  = -L/usr/local/lib/ -lgsl -lgslcblas
MPI_INCL  = -I/usr/local/include/openmpi/
MPI_LIBS  = -L/usr/local/lib/openmpi/  -lmpi

# Various C preprocessor directives that change the way L-PICOLA is made
# ====================================================================
#SINGLE_PRECISION = -DSINGLE_PRECISION	 # Single precision floats and FFTW (else use double precision)
#OPTIONS += $(SINGLE_PRECISION)

MEMORY_MODE = -DMEMORY_MODE             # Save memory by making sure to allocate and deallocate arrays only when we need them
OPTIONS += $(MEMORY_MODE)               # and by making the particle data single precision

PARTICLE_ID = -DPARTICLE_ID             # Assigns unsigned long ID's to each particle and outputs them. This adds
OPTIONS += $(PARTICLE_ID)               # an extra 4 bytes to the storage required for each particle. Overrides LONG_PARTICLE_ID.

#LONG_PARTICLE_ID = -DLONG_PARTICLE_ID   # Assigns unsigned long long ID's to each particle and outputs them. This adds
#OPTIONS += $(LONG_PARTICLE_ID)          # an extra 8 bytes to the storage required for each particle

#LIGHTCONE = -DLIGHTCONE                 # Builds a lightcone based on the run parameters and only outputs particles
#OPTIONS += $(LIGHTCONE)                 # at a given timestep if they have entered the lightcone 

#ONLY_ZA = -DONLY_ZA                    # Switch this on if you want ZA initial conditions (2LPT otherwise)
#OPTIONS += $(ONLY_ZA)

GAUSSIAN = -DGAUSSIAN                   # Switch this if you want gaussian initial conditions (fnl otherwise)
OPTIONS += $(GAUSSIAN) 

#LOCAL_FNL = -DLOCAL_FNL                 # Switch this if you want only local non-gaussianities
#OPTIONS += $(LOCAL_FNL)                 # NOTE this option is only for invariant inital power spectrum
                                         # for local with ns != 1 use DGENERIC_FNL and input_kernel_local.txt

#EQUIL_FNL = -DEQUIL_FNL                 # Switch this if you want equilateral Fnl
#OPTIONS += $(EQUIL_FNL)                 # NOTE this option is only for invariant inital power spectrum
                                         # for local with ns != 1 use DGENERIC_FNL and input_kernel_equil.txt

#ORTHO_FNL = -DORTHO_FNL                 # Switch this if you want ortogonal Fnl
#OPTIONS += $(ORTHO_FNL)                 # NOTE this option is only for invariant inital power spectrum
                                         # for local with ns != 1 use DGENERIC_FNL and input_kernel_ortog.txt

#GENERIC_FNL += -DGENERIC_FNL            # Switch this if you want generic Fnl implementation
#OPTIONS += $(GENERIC_FNL)               # This option allows for ns != 1 and should include an input_kernel_file.txt 
                                         # containing the coefficients for the generic kernel 
                                         # see README and Manera et al astroph/NNNN.NNNN
                                         # For local, equilateral and orthogonal models you can use the provided files
                                         # input_kernel_local.txt, input_kernel_equil.txt, input_kernel_orthog.txt 

GADGET_STYLE = -DGADGET_STYLE           # If we are running snapshots this writes all the output in Gadget's '1' style format, with the corresponding header
OPTIONS += $(GADGET_STYLE)              # This option is incompatible with LIGHTCONE simulations. For binary outputs with LIGHTCONE simulations use the UNFORMATTED option.
																				
#UNFORMATTED = -DUNFORMATTED             # If we are running lightcones this writes all the output in binary. All the particles are output in chunks with each 
#OPTIONS += $(UNFORMATTED)               # chunk preceded by the number of particles in the chunk. With the chunks we output all the data (id, position and velocity)
                                         # for a given particle contiguously

#TIMING = -DTIMING                       # Turns on timing loops throughout the whole code and outputs the CPU times for each major part of the code 
#OPTIONS += $(TIMING)                    # and for each timestep, for both processor 0 and the sum of all processors

# =========================================================================================================================================================================================================
# Nothing below here should need changing unless you are modifying the code.
# =========================================================================================================================================================================================================

# Run some checks on option compatability
# =======================================
ifdef GAUSSIAN
ifdef LOCAL_FNL
  $(error ERROR: GAUSSIAN AND LOCAL_FNL are not compatible, choose only one in Makefile)
endif
ifdef EQUIL_FNL
  $(error ERROR: GAUSSIAN AND EQUIL_FNL are not compatible, choose only one in Makefile)
endif
ifdef ORTHO_FNL
  $(error ERROR: GAUSSIAN AND ORTHO_FNL are not compatible, choose only one in Makefile)
endif
ifdef GENERIC_FNL
  $(error ERROR: GAUSSIAN AND GENERIC_FNL are not compatible, choose only one in Makefile)
endif
else
ifndef LOCAL_FNL 
ifndef EQUIL_FNL
ifndef ORTHO_FNL 
ifndef GENERIC_FNL
  $(error ERROR: if not using GAUSSIAN then must select some type of non-gaussianity (LOCAL_FNL, EQUIL_FNL, ORTHO_FNL, GENERIC_FNL), change Makefile)
endif
endif
endif
endif
endif

ifdef GENERIC_FNL 
ifdef LOCAL_FNL 
   $(error ERROR: GENERIC_FNL AND LOCAL_FNL are not compatible, choose only one in Makefile) 
endif 
ifdef EQUIL_FNL 
   $(error ERROR: GENERIC_FNL AND EQUIL_FNL are not compatible, choose only one in Makefile) 
endif 
ifdef ORTHO_FNL 
   $(error ERROR: GENERIC_FNL AND ORTHO_FNL are not compatible, choose only one in Makefile) 
endif 
endif 

ifdef LOCAL_FNL
ifdef EQUIL_FNL
   $(error ERROR: LOCAL_FNL AND EQUIL_FNL are not compatible, choose only one in Makefile) 
endif
ifdef ORTHO_FNL
   $(error ERROR: LOCAL_FNL AND ORTHO_FNL are not compatible, choose only one in Makefile) 
endif
endif

ifdef EQUIL_FNL
ifdef ORTHO_FNL
   $(error ERROR: EQUIL_FNL AND ORTHO_FNL are not compatible, choose only one in Makefile) 
endif
endif

ifdef PARTICLE_ID
ifdef LIGHTCONE
   $(warning WARNING: LIGHTCONE output does not output particle IDs)
endif
endif

ifdef GADGET_STYLE
ifdef LIGHTCONE
   $(error ERROR: LIGHTCONE AND GADGET_STYLE are not compatible, for binary output with LIGHTCONE simulations please choose the UNFORMATTED option.)
endif
endif

ifdef UNFORMATTED
ifndef LIGHTCONE 
   $(error ERROR: UNFORMATTED option is incompatible with snapshot simulations, for binary output with snapshot simulations please choose the GADGET_STYLE option.)
endif
endif

# Compile the code
# ================
LIBS   =   -lm $(MPI_LIBS) $(FFTW_LIBS) $(GSL_LIBS)

CFLAGS =   $(OPTIMIZE) $(FFTW_INCL) $(GSL_INCL) $(MPI_INCL) $(OPTIONS)

OBJS   = src/main.o src/cosmo.o src/auxPM.o src/2LPT.o src/power.o src/vars.o src/read_param.o
ifdef GENERIC_FNL
OBJS += src/kernel.o
endif
ifdef LIGHTCONE
OBJS += src/lightcone.o
endif

INCL   = src/vars.h src/proto.h  Makefile

all: $(OBJS) 
	$(CC) $(CFLAGS) $(OBJS) $(LIBS) -o $(EXEC)

$(OBJS): $(INCL) 

.PHONY: clean
clean:
	rm -f src/*.o src/*~ *~ $(EXEC)


.PHONY: install
install:
	cp $(EXEC) $(BIN)
