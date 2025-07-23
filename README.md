# pFUnit Parameterization Demonstration

![Fortran](https://img.shields.io/badge/Fortran-2008-purple)
![GitHub](https://img.shields.io/github/license/jatkinson1000/pfunit-parameterization-demo)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jatkinson1000/pfunit-parameterization-demo/test_build.yaml?label=tests)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jatkinson1000/pfunit-parameterization-demo/static_analysis.yaml?label=quality)

This code accompanies a post I wrote about using the Fortran unit testing framework
[pFUnit](https://github.com/Goddard-Fortran-Ecosystem/pFUnit) to write and run
parameterized tests.

pFUnit has a lot of excellent features, but the documentation and tutorials are sparse,
and often out of date.
This makes it a challenge to learn and utilize to the fullest extent.

In this demo I take a simple Fortran code that multiplies two numbers together,
supported by a simple pFUnit test.
I then provide a parameterized version of the test to indicate the benefits of utilizing
parameterization, and the changes required to accommodate it.


## Dependencies

To run this code requires a Fortran compiler (gfortran is assumed in the Makefile, but
could be adjusted) pFUnit to be installed.
You will need Make, or optionally CMake, to build.

pFUnit can be installed as follows:
```sh
git clone git@github.com:Goddard-Fortran-Ecosystem/pFUnit.git
cd pFUnit
cmake -B build
cd build
make tests
make install
```

Following this pFUnit should should be installed at
`pfunit/build/installed/PFUNIT-x.y/`, where
`x.y` indicates the version of this installation.


## Building/Installation

This code comes with both a Makefile and a CMakeLists.

### Using Make

To build using Make set the value of the environment variable `PFUNIT` to
be the path to the installation as noted above, then invoke `make`:
```sh
PFUNIT=<PATH/TO/PFUNIT-x.y>
make
```

to build the code.

Alternatively, pass the value of the variable directly to the `make`
command:
```sh
make PFUNIT=<PATH/TO/PFUNIT-x.y>
```

This will generate a number of compilation files, as well as three executables.
To clean up the compilation files run:
```sh
make clean
```

### Using CMake

To build using CMake, from the root of the repository run:
```sh
cmake -B build -DCMAKE_PREFIX_PATH=<PATH/TO/PFUNIT-x.y>
cmake --build build
```
where `<PATH/TO/PFUNIT-x.y>` is the path to the pFUnit installation as described
above.

This will generate build files in the `build/` directory, and the three executables
at the root of the repository.


## Usage

Once built/installed the code provides three executables:

- `multiply` is a program defined in `multiply.f90` that takes two numbers from
  the user and returns the product. It makes use of a subroutine defined in the
  `multiply_mod.f90` module file.
- `test_multiply` is a simple test for the `multiply_mod` module written using
  the pFUnit framework. It contains a single test checking that `2 * 2 == 4`.
  It is defined in the `unittest_multiply.pf` file.
- `test_multiply_param` is an extension of `test_multiply` that runs the same test,
  but this time parameterized for a series of different inputs to check a variety of
  possible cases. It is defined in the `unittest_multiply_param.pf` file.

All three can be run from the command line with no additional arguments.

To gain a clear picture of the changes that had to be made to accommodate
parameterization one can run:
```sh
vimdiff unittest_multiply.pf unittest_multiply_param.pf
```
or any other side-by-side comparison tool/viewer.

To view the process of adding parameterization you can inspect the git history.


### License

This demo is distributed under a [GPL 3.0](https://github.com/jatkinson1000/pfunit-parameterization-demo/blob/main/LICENSE)
License.


## Contributions
Contributions are welcome.

Bugs, feature requests, and clear suggestions for improvement can be documented by
[opening an issue](https://github.com/jatkinson1000/pfunit-parameterization-demo/issues).
