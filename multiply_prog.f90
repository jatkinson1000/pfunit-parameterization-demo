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
