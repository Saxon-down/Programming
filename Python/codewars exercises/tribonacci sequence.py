# Description:

# Well met with Fibonacci bigger brother, AKA Tribonacci.
#
# As the name may already reveal, it works basically like a Fibonacci, but
# summing the last 3 (instead of 2) numbers of the sequence to generate the
# next. And, worse part of it, regrettably I won't get to hear non-native
# Italian speakers trying to pronounce it :(
#
# So, if we are to start our Tribonacci sequence with [1, 1, 1] as a starting
# input (AKA signature), we have this sequence:
#
# [1, 1 ,1, 3, 5, 9, 17, 31, ...]
# But what if we started with [0, 0, 1] as a signature? As starting with [0, 1]
# instead of [1, 1] basically shifts the common Fibonacci sequence by once
# place, you may be tempted to think that we would get the same sequence shifted
# by 2 places, but that is not the case and we would get:
#
# [0, 0, 1, 1, 2, 4, 7, 13, 24, ...]
# Well, you may have guessed it by now, but to be clear: you need to create a
# fibonacci function that given a signature array/list, returns the first n
# elements - signature included of the so seeded sequence.
#
# Signature will always contain 3 numbers; n will always be a non-negative
# number; if n == 0, then return an empty array and be ready for anything else
# which is not clearly specified ;)


# My Solution
def tribonacci(signature, n):
    if (n==0):
        # Return an empty list
        return []
    elif (n==1):
        # Return a list with just the first element
        signature.pop()
        signature.pop()
        return signature
    elif (n==2):
        # Return a sub-list of just the first 2 elements
        signature.pop()
        return signature
    elif (n==3):
        # Return the supplied 3-entry list
        return signature
    else:
        # Actually need to calculate the correct result,
        # .. and return the entire list
        for count in range (3, n):
            # Calculate next by adding the previous 3 values
            next = signature[-1] + signature[-2] + signature[-3]
            # Append the calculated value to the list
            signature.append(next)
        # Return the list we've generated
        return signature

# Best Practice
def tribonacci(signature, n):
  res = signature[:n]
  for i in range(n - 3): res.append(sum(res[-3:]))
  return res
