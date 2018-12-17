def proper_fractions(denom):
    # 
    phi = int(denom > 1 and denom)  # phi = n unless n==1 or n==0
    for divis in range(2, int(denom ** .5) + 1) :
        # divisors <= sqrt will be repeated in range x+sqrt+1 .. sqrt*2, so
        # they don't need to be checked
        if not denom % divis:       # if there's no remainder ...
            phi -= phi // divis	    # remove all multiples of divis 
            while not denom % divis:
                denom //= divis
    # if denom is > 1 it means it is prime
    if denom > 1: phi -= phi // denom 
    return phi


print(proper_fractions(1))
print(proper_fractions(2))
print(proper_fractions(5))
print(proper_fractions(15))
print(proper_fractions(25))

for i in range (0, 10) :
    print(i, proper_fractions(i))

