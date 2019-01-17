l = [1, 2, 3, 4, 5, 6]
a, b = l[0], l[1:]
print(a, b)
c, *d = l	# Does the same thing as previous line
print(c, d)

# You can also do this ...
s = "my sentence"
first, second, *bulk, last = s
print(first, second, bulk, last)
# Note that * just unpacks the KEYS (for dictionaries, etc)

d1 = {'p': 1, 'y':2}
d2 = {'t': 3, 'h': 4}
d3 = {'h':5, 'o':6, 'n':7}  # Note 'h' is here as well!

# ** unpacks key:value pairs, whereas * just unpacks the key
merged = {**d1, **d2, **d3}
# results in random order with {'p':1, 'y':2, 't':3, h':5, 'o':6, 'n':7}
# ..note that d3{'h'} overwrites d2{'h'}
print(merged)

*z, = "my string"   # Converts the string to a list
print(z)


def func1(a, b, *args) :
    # Function with optional args
    print("Func1:")
    print("\t", a)
    print("\t", b)
    print("\t", args)

print(func1(1, 2))
print(func1(b=2, a=4))  # Use named parameters so you can 
    # provide them in the order you want, not the order the 
    # function expects. Once you provide a named parameter,
    # all parameters after it also have to be named
print(func1(1, 2, 3, 4, 5, 6, 7))

def avg(*args) :
    # Providing 0 args will result in a divide-by-zero error
    count = len(args)
    total = sum(args)
    return count and total/count

def avg2(a, *args) :
    # Providing 0 args will now result in missing parameter 'a'
    count = 1 + len(args)
    total = a + sum(args)
    return count and total/count

print(avg(1,2,3,4,5,6))


def positional_arguments(a, *args, c) :
    # Can pass as many values as you like, but the last one 
    # MUST be named:
    # positional_arguments(1, 2, 3, 4, c=5)
    # .. will result in args = [2,3,4]
    print("positional_arguments: ", a, args, c)

positional_arguments(1,2,3,4,5,c=6)
positional_arguments('a', c='c')
# Note that NOT specifying the last argument as 'c=...' will 
# cause a missing argument error

def default_value(a=10) :
    print("default_value: ", a)

default_value(4)    # prints 4
default_value()     # prints 10

def named_args_only(*, d, e) :
    print("named_args_only: ", d, e)

named_args_only(d=5, e=9)   # prints '5 9'
named_args_only(e=5, d=9)   # prints '9 5'
# named_args_only(5, 6)  results in an arguments error
# named_args_only(d=5, 6)  results in an arguments error
# named_args_only(e=5, 6)  results in an arguments error
# Also can't provide ANY positional arguments, so ...
# named_args_only(1, d=2, e=3) also gives an args error

def named_and_positional(a, *, b) :
    print("named_and_positional: ", a, b)

named_and_positional(4, b=3)