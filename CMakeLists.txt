cmake_minimum_required(VERSION 3.12...3.31)

# Project name, version, and language
project(
  MultiplyProgram
  VERSION 1.0.0
  LANGUAGES Fortran
)

# Place executables at the top level
set (
  CMAKE_RUNTIME_OUTPUT_DIRECTORY
  ${CMAKE_SOURCE_DIR}
)

# ==========================================
# Main Code

# Add executable with module dependency
add_executable(
  multiply
  multiply_mod.f90
  multiply_prog.f90
)

# ==========================================
# pFUnit Tests

find_package(PFUNIT REQUIRED)
enable_testing()

# Create a library with module being tested
add_library (multlib multiply_mod.f90)

# Generate pFUnit simple tests
add_pfunit_ctest (test_multiply
  TEST_SOURCES unittest_multiply.pf
  LINK_LIBRARIES multlib
)

# Generate pFUnit parameterised tests
add_pfunit_ctest (test_multiply_param
  TEST_SOURCES unittest_multiply_param.pf
  LINK_LIBRARIES multlib
)

# ==========================================
