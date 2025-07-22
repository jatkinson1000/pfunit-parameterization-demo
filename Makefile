# General definitions
FC = gfortran
FFLAGS = -Wall -Wextra -O2

# Sources for building the main program
TARGET = multiply
MODULE = multiply_mod.o
SOURCES := multiply_mod.f90 multiply_prog.f90
OBJS := $(SOURCES:%.f90=%.o)

# Sources for building the tests
TARGET_TEST = test_multiply
SOURCES_TEST := unittest_multiply.F90
OBJS_TEST := $(SOURCES_TEST:%.F90=%.o)

TARGET_TEST_PARAM = test_multiply_param
SOURCES_TEST_PARAM := unittest_multiply_param.F90
OBJS_TEST_PARAM := $(SOURCES_TEST:%.F90=%.o)

# Specify pFUnit location and include its Make functions
# Set the extra compiler flags required to link pFUnit
# Assumes PFUNIT has been set as an environment variable
# with PFUNIT = PATH/TO/PFUNIT-x.y/
include $(PFUNIT)/include/PFUNIT.mk
FFLAGS += $(PFUNIT_EXTRA_FFLAGS)


# Target Rules
all: $(TARGET) $(TARGET_TEST) $(TARGET_TEST_PARAM)

$(TARGET): $(OBJS)
	$(FC) $(FFLAGS) -o $@ $^

$(TARGET_TEST): libmultiply.a

# Extra pFUnit jargon required to parse .pf files
#   and set up compilation appropriately
$(TARGET_TEST)_TESTS := unittest_multiply.pf
$(TARGET_TEST)_REGISTRY :=
$(TARGET_TEST)_OTHER_SOURCES := multiply_mod.f90
$(TARGET_TEST)_OTHER_LIBRARIES := -L. -lmultiply
$(TARGET_TEST)_OTHER_INCS :=

$(eval $(call make_pfunit_test,$(TARGET_TEST)))

$(TARGET_TEST_PARAM): libmultiply.a

$(TARGET_TEST_PARAM)_TESTS := unittest_multiply_param.pf
$(TARGET_TEST_PARAM)_REGISTRY :=
$(TARGET_TEST_PARAM)_OTHER_SOURCES := multiply_mod.f90
$(TARGET_TEST_PARAM)_OTHER_LIBRARIES := -L. -lmultiply
$(TARGET_TEST_PARAM)_OTHER_INCS :=

$(eval $(call make_pfunit_test,$(TARGET_TEST_PARAM)))

libmultiply.a: $(OBJS_TEST)
	$(AR) -r $@ $?

%.o: %.f90
	$(FC) $(FFLAGS) -c $<

%.o: %.F90
	$(FC) $(FFLAGS) -c $<

clean:
	$(RM) *.o *.mod *.a *.inc
	$(RM) unittest_multiply.F90 unittest_multiply_param.F90

clean-all: clean
	$(RM) $(TARGET) $(TARGET_TEST) $(TARGET_TEST_PARAM)
