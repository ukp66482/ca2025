.data
argument: .word   7                # Store the initial value (7) for which we want to compute the factorial
str1:     .string "Factorial value of "  # First part of the output message
str2:     .string " is "                 # Second part of the output message

.text
main:
        lw  a0, argument           # Load the argument (7) into register a0
        jal ra, fact               # Jump-and-link to the 'fact' function to compute factorial

        # Prepare to print the result
        mv  a1, a0                 # Move the result (factorial) from a0 to a1 for printing
        lw  a0, argument           # Reload the original argument into a0 to print it

        # Call the function to print the result
        jal ra, printResult

        # Exit the program
        li a7, 10                  # System call code for exiting the program
        ecall                      # Make the exit system call

# Recursive function to compute factorial
# a0: Input argument (number for which factorial is to be calculated)
fact:
        addi sp, sp, -16           # Allocate stack space for local variables (ra and a0)
        sw   ra, 8(sp)             # Save return address (ra) on the stack
        sw   a0, 0(sp)             # Save input argument (a0) on the stack

        addi t0, a0, -1            # Check if a0 > 0 by subtracting 1
        bge  t0, zero, nfact       # If a0 >= 1, jump to 'nfact' to continue recursion

        # Base case: factorial(0) = 1
        addi a0, zero, 1           # Set a0 = 1 as factorial(0) = 1
        addi sp, sp, 16            # Restore stack
        jr x1                      # Return to the caller

nfact:
        addi a0, a0, -1            # Decrement a0 (input) by 1 for recursive call
        jal  ra, fact              # Recursive call to 'fact' function
        addi t1, a0, 0             # Store the result of factorial(n-1) in t1

        # Restore the previous state before returning
        lw   a0, 0(sp)             # Load the original value of a0 (n) from the stack
        lw   ra, 8(sp)             # Restore return address (ra)
        addi sp, sp, 16            # Deallocate stack space

        # Multiply the current value of n with factorial(n-1)
        mul a0, a0, t1             # a0 = a0 * t1, where t1 contains factorial(n-1)
        ret                        # Return to the caller with factorial(n)

# This function prints the factorial result in the format:
# "Factorial value of X is Y", where X is the original number and Y is the computed factorial
# a0: The original input value (X)
# a1: The computed factorial result (Y)
printResult:
        mv t0, a0                  # Save original input value (X) in temporary register t0
        mv t1, a1                  # Save factorial result (Y) in temporary register t1

        la a0, str1                # Load the address of the first string ("Factorial value of ")
        li a7, 4                   # System call code for printing a string
        ecall                      # Print the string

        mv a0, t0                  # Move the original input value (X) to a0 for printing
        li a7, 1                   # System call code for printing an integer
        ecall                      # Print the integer (X)

        la a0, str2                # Load the address of the second string (" is ")
        li a7, 4                   # System call code for printing a string
        ecall                      # Print the string

        mv a0, t1                  # Move the factorial result (Y) to a0 for printing
        li a7, 1                   # System call code for printing an integer
        ecall                      # Print the integer (Y)

        ret                        # Return to the caller
