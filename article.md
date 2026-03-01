---
title: Parameterizing Fortran tests with pFUnit
author: Jack Atkinson
date: "2025-07-25T00:00:00+00:00"
publishDate: "2026-03-01T00:00:00+00:00"
categories: ["computing","software","RSE"]
tags: ["Fortran","testing"]
---

I recently set about parameterizing a test suite for some Fortran code
written using the [pFUnit framework](https://github.com/Goddard-Fortran-Ecosystem/pFUnit).

The process of doing so, given the sparse documentation around pFUnit,
resulted in much bashing of my head against the wall.
In the hope of saving others time in future I thought I'd write my
experiences and key steps into a short post.

---

## Introduction

I'm going to start by assuming that anyone reading this is familiar with
Fortran, basic concepts around testing (unit tests, parameterization, etc.),
and basic use of pFUnit for testing Fortran code.

I'll look at an example code, including tests, and then work through the
process of parameterizing them using the pFUnit utilities.
I'll also provide a short summary of gotchas and other things to be aware
of when doing this.

All of the code described in this article is available in a
[GitHub repository](https://github.com/jatkinson1000/pfunit-parameterization-demo),
fully runnable with instructions and with comparisons, at
[github.com/jatkinson1000/pfunit-parameterization-demo](https://github.com/jatkinson1000/pfunit-parameterization-demo).


## Setup - a basic code to test

Consider the following simple Fortran module `multiply_mod.f90` that
provides a function to multiply two floating point numbers together:

```fortran
!| Module containing a multiply function

module multiply_mod
  use, intrinsic :: iso_fortran_env, only: wp => real64

  implicit none

  public

contains

  function multiply_numbers(a, b) result(product)
    real(wp), intent(in) :: a, b  !! Numbers to be multiplied
    real(wp) :: product  !! Result of the multiplication

    product = a * b
  end function multiply_numbers

end module multiply_mod
```

We use it in the following simple program (`multiply_prog.f90`) that
takes two numbers from the user and prints the product to the screen:

```fortran
!| Program to fetch numbers from user and multiply

program multiply

  use, intrinsic :: iso_fortran_env, only: wp => real64
  use multiply_mod, only: multiply_numbers

  implicit none

  real(wp) :: num1, num2  !! Numbers to multiply
  real(wp) :: result      !! The product of 1 and b

  ! Prompt user for input
  print *, "Enter the first number:"
  read *, num1
  print *, "Enter the second number:"
  read *, num2

  ! Call the multiplication function
  result = multiply_numbers(num1, num2)

  ! Print the result
  write (*, "(A, F6.2, A, F6.2, A, F8.2)") &
    "The product of ", num1, " and ", num2, " is ", result

end program multiply
```

You can check this by compiling with the
[`CMakeLists.txt`](https://github.com/jatkinson1000/pfunit-parameterization-demo/blob/main/CMakeLists.txt)
or
[`Makefile`](https://github.com/jatkinson1000/pfunit-parameterization-demo/blob/main/Makefile)
in the
[git repository](https://github.com/jatkinson1000/pfunit-parameterization-demo)
associated with this post.


## Simple pFUnit test

The following is a basic pFUnit file that defines a testing module
with a single test that checks that the result of `2 * 2` using our
multiply function is `4`.

```fortran
!| unittest_multiply.pf
!  pFUnit file containing tests for multiplying numbers

module unittest_multiply

  use, intrinsic :: iso_fortran_env, only: wp => real64
  use funit
  use multiply_mod, only: multiply_numbers

  implicit none

  public

contains

  @test
  subroutine test_multiply_numbers()
    !! Test multiplying two numbers returns the expected result

    real(wp) :: num1, num2  !! numbers to multiply
    real(wp) :: product     !! The product from multiplying
    real(wp) :: expected    !! The expected result

    num1 = 2.0_wp
    num2 = 2.0_wp
    expected = 4.0_wp

    product = multiply_numbers(num1, num2)

    @assertEqual(expected, product)

  end subroutine test_multiply_numbers

end module unittest_multiply
```


## Parameterizing the tests

Anyone with unit testing experience will understand the need to
parameterize this test.
Currently we check `2 * 2 = 4`, but what about multiplying two negative
numbers? Does that work? Or a positive and a negative? etc.

Ideally we would be able to test all of these without writing out the same test code
multiple times and changing the numbers.
And indeed, this is what test parameterization does for us.

In frameworks such as [pytest](https://docs.pytest.org/) for Python the process is
rather easy, but doing so in compiled Fortran using pFUnit requires a little more leg work.
Below I'll set out how the simple test above can be modified to add parameterization.

### 1. Defining a testParameter

pFUnit provides the `AbstractTestParameter` parent type that can be
extended using the `extends` attribute.

We need extend this to add the variables that we will be passing to the
test as parameters to its members.
We also need to add a `toString` procedure (`deferred` and expected by
`AbstractTestParameter` as a Fortran `function`) that will be
used to output the parameters of the type.

Finally we annotate this type as a test parameter using `@testParameter`
so that pFUnit knows to treat it accordingly.

So, to parameterize the `test_multiply_numbers` test above we need to provide
two numbers to be multiplied together (`a` and `b`) and an `expected` result.
It's also nice to add a `character` variable to provide a short description
of the particular case the parameter set is used for (e.g. `+ * +`, `+ * -`, etc.).

This can be done as follows:
```fortran
module unittest_multiply_param

  implicit none

  public

  ...

  !> Typedef for a test parameter for the multiply routine
  @testParameter
  type, extends(AbstractTestParameter) :: MultiplyTestParameters
    real(wp) :: a, b, expected
    character(:), allocatable :: desc
   contains
    procedure :: toString
  end type MultiplyTestParameters

  contains

  !> Fixture for writing specific parameterization information
  function toString(this) result(string)

    class(MultiplyTestParameters), intent(in) :: this
    character(:), allocatable :: string

    string = trim(this%desc)

  end function toString

  ...

end module unittest_multiply_param
```


### 2. Defining a testCase

The next step is to define a `testCase` type by extending another parent
type `ParameterizedTestCase`.
We define a specific type for our test, and extend it with a variable of
the `MultiplyTestParameters` type so that the testcase can hold and
iterate over parameters.

This has to be accompanied by a `constructor` function that will take a
specific set of parameters (as a `MultiplyTestParameters` type from above)
and set them as this member variable of a `MultiplyTestCase`.

Finally, similarly to the parameters above, the `testCase` needs to be
annotated using `@testCase` for the benefit of pFUnit, and the name of its
constructor specified.


This can be done with the following:
```fortran
module unittest_multiply_param

  implicit none

  public

  ...

  !> Typedef for a test case taking MultiplyTestParameters
  @testCase(constructor=multiply_test_case_constructor)
  type, extends (ParameterizedTestCase) :: MultiplyTestCase
    type(MultiplyTestParameters) :: params
  end type MultiplyTestCase

  contains

  !> Constructor for the MultiplyTestCase type
  function multiply_test_case_constructor(params)

    type(MultiplyTestCase) :: multiply_test_case_constructor
    type(MultiplyTestParameters), intent(in) :: params

    multiply_test_case_constructor%params = params

  end function multiply_test_case_constructor

  ...

end module unittest_multiply_param
```

### 3. Define a parameters getter

The last piece of infrastructure we need to provide is a parameters getter.
This is where we will define all of the various parameter sets we want to
run our test over.
It takes the form of a `function` that returns an array of
`MultiplyTestParameters` and will be used in the next
step.

For us, this can be done as follows:
```fortran
module unittest_multiply_param

  implicit none

  public

   ...

  contains

  !> A fixture for varying the multiplication parameters
  function get_multiply_parameters() result(params)

    type(MultiplyTestParameters), allocatable :: params(:)

    params = [ &
      MultiplyTestParameters(2.0, 2.0, 4.0, trim("+ * +")), &
      MultiplyTestParameters(-2.0, 2.0, -4.0, trim("+ * -")), &
      MultiplyTestParameters(2.0, -2.0, -4.0, trim("- * +")), &
      MultiplyTestParameters(-2.0, -2.0, 4.0, trim("- * -")), &
      MultiplyTestParameters(3.0, 2.0, 6.0, trim("2 integer")), &
      MultiplyTestParameters(3.0, 2.5, 7.5, trim("1 real")), &
      MultiplyTestParameters(3.3, 6.6, 21.78, trim("2 real")) &
    ]
  end function get_multiply_parameters

  ...

end module unittest_multiply_param
```
note how we use the `desc` character string to add a brief description of
what we are testing with each item.


### 4. Update the tests to handle parameters

The final step is to update the simple test from the original example to
use this new infrastructure.

To do so requires adding the getter function as the `testParameters` in
the `@test` annotation.
This tells pFUnit to construct and run the test for each set of parameters
returned by `get_multiply_parameters()` getter.

At the same time we make the test subroutine take an argument `this` of
the `MultiplyTestCase` type.
Recall that this type is capable of holding a
`MultiplyTestParameters` type so will contain the parameters for the
current test case.

To access parameters from `this` inside the test we use type variable access
with `%` for variables as they are defined in `MultiplyTestParameters`,
with specific values as returned by `get_multiply_parameters()`.
For example, `this%params%a` and `this%params%b` are the two numbers to be
multiplied, and `this%params%expected` is the expected result as defined in
the `MultiplyTestParameters` type.
These replace the previously hardcoded numbers.

Here is the updated test subroutine:

```fortran
module unittest_multiply_param

  implicit none

  public

   ...

  contains

  @test(testParameters={get_multiply_parameters()})
  subroutine test_multiply_numbers(this)
    !! Test multiplying two numbers returns the expected result

    class(MultiplyTestCase), intent(inout) :: this

    real(wp) :: num1, num2  !! numbers to multiply
    real(wp) :: product     !! The product from multiplying
    real(wp) :: expected    !! The expected result

    num1 = this%params%a
    num2 = this%params%b
    expected = this%params%expected

    product = multiply_numbers(num1, num2)

    @assertEqual(expected, product, tolerance=1.e-5)

  end subroutine test_multiply_numbers

end module unittest_multiply_param

```

The single test will now be run with different parameters, keeping it
concise and easy to maintain whilst increasing coverage and checking of
edge cases.


## Things to be aware of

There are a few gotchas and pitfalls I have come across that are worth
being aware of when writing parameterized tests.

#### Beware the implied save!

In Fortran, if setting the value of a variable as part of its definition,
this is done as a one-off at compile time, _not_ on each call to the
procedure.
As such, any updates to the variable will be `save`d or 'remembered',
persisting to subsequent calls.
See [Implied Save](https://fortran-lang.org/learn/quickstart/gotchas/#implied-save) for more details.

This is something to be particularly wary of as parameterized tests as you
the generated pFUnit code will loop over a subroutine several times.
Unless you are setting the value of a `parameter` at declaration you
should instead ensure that there is a clean assignment that occurs
separately:

```fortran
@test(testParameters={get_my_test_parameters()})
subroutine mytest(this)
    class(MyTestCase), intent(inout) :: this

    integer, dimension(2) :: bad=[0, 1]  ! Implied save!
    integer, dimension(2) :: good

    good = [0, 1]

    ! Here `bad` is implied save. If `routine_to_be_tested`
    ! modifies bad the change persists across subsequent calls.
    ! Instead explicitly initialise the value at the start of the
    ! subroutine as is done for `good`.
    call routine_to_be_tested(bad)
    call routine_to_be_tested(good)

end subroutine
```

#### Checking for "almost equal" on arrays

pFUnit comes with some built-in checkers such as `@assertTrue`, and
`@assertEqual`, the latter of which can take an absolute tolerance.
However, if you want to operate on arrays or have more elaborate functions
that operate closer to `numpy`, e.g. with relative tolerance, you may need
to define your own `assert_allclose` etc. as we do in the
[FTorch implementation](https://github.com/Cambridge-ICCS/FTorch/blob/main/src/ftorch_test_utils.f90).

You can still leverage pFUnit's utilities by applying `@assertTrue()` to the
result any custom function provided it returns a boolean.

#### If one test is parameterized, all must be

If you define any test in a pFUnit test module to be parameterized, then
all tests in the submodule need to be parameterized. I.e. no bare `@test`
annotations.

To get around this you can define a minimal fixture that provides a single
set of dummy parameters (that go unused) to any tests in the module that do
not need parameterizing, for example:

```fortran
  ! A minimal fixture for tests requiring no parameters
  function get_parameters_unparameterized() result(params)
    type(MultiplyTestParameters), allocatable :: params(:)

    params = [ &
      MultiplyTestParameters(0.0, 0.0, 0.0, trim("---")), &
    ]
  end function get_parameters_unparameterized
```

#### Multiple fixtures

It is possible to define multiple fixture types in a single test module.
However, care may needs to be taken when setting an appropriate `toString`
method if differing behaviour is required.
For example customising how the parameters are displayed in the test string 
output for different types.

Since `AbstractTestParameter` expects the deferred `toString`
[type-bound procedure](https://fortran-lang.org/learn/oop_features_in_fortran/object_oriented_programming_techniques/#type-bound-procedures-tbp)
the solution is to define explicit methods and then bind them to the
`toString` procedure of the appropriate parameter type using `=>` operator.

For example, you might have one set of parameters for testing
multiplication and another for testing exponents, each with a differing
`toString` representation:

```fortran
@testParameter
type, extends(AbstractTestParameter) :: MultiplyTestParameters
  real(wp) :: a, b, expected
  character(:), allocatable :: desc
  contains
    procedure :: toString => toStringMultiply
end type MultiplyTestParameters

@testParameter
type, extends(AbstractTestParameter) :: ExponentTestParameters
  real(wp) :: num, expected
  integer :: pow
  character(:), allocatable :: desc
  contains
    procedure :: toString => toStringExponent
end type ExponentTestParameters

contains

!> Fixture for writing out specific parameterization information
function toStringMultiply(this) result(string)
  class(MultiplyTestParameters), intent(in) :: this
  character(:), allocatable :: string
  string = "Multiply: " // trim(this%desc)
end function toStringMultiply

function toStringExponent(this) result(string)
  class(ExponentTestParameters), intent(in) :: this
  character(:), allocatable :: string
  string = "Exponent: " // trim(this%desc)
end function toStringExponent
```

#### Implicit limit on test name length

Remember that for certain standards and compilers there is a default
limit on line length of 132 characters.
If the generated pFUnit code exceeds this then it will lead to a
truncation error when compiling.
This most often occurs in the `call suite%addTest` at the end of the
module and imposes an implicit limit of around 35 characters on
test/subroutine names, as the rest of the call for a custom test with
parameters becomes rather long.

Consider whether you really need "`test`" or "`modulename`" in the
individual test name given that we know these are tests and the suite name
is output as a header when running CTest.


## Summary

This article has walked through the process of parameterizing tests in
pFUnit, adapting a basic test to define the infrastructure required to
loop over a set of predefined parameter sets.
Following these steps allows construction of concise and maintainable test
suites for Fortran code, easily adding coverage and edge cases.

I hope that this description is useful to others out there to understand
and use these tools in their own work.
If so, please drop a star on the GitHub repository, get in touch, or
[grab me a coffee](https://buymeacoffee.com/jackatkinsr).

If you spot anything that is incorrect or could be made clearer, please get in touch.
