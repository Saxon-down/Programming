#!/usr/local/bin/python3

import time
from datetime import datetime

def time_it(fn, *args, rep=1, **kwargs) :
    start = time.perf_counter()
    for i in range(rep) :
        # print(args,kwargs)
        fn(*args, **kwargs)
    end = time.perf_counter()
    return (end - start) / rep

def compute_powers_1(n, *, start=1, end) :
    # Using for loop
    results = []
    for i in range(start, end):
        results.append(n**i)
    return results

def compute_powers_2(n, *, start=1, end) :
    # Using a list comprehension
    return [n**i for i in range(start, end)]

def compute_powers_3(n, *, start=1, end) :
    # Using generators expression
    # A generator doesn't actually calculate the results; to do that we need to pass
    # the generator into LIST
    return list(n**i for i in range(start, end))

def log_bad(msg, *, dt=datetime.utcnow()) :
    # this is bad because the function and dt variable are set at the time the script
    # is first run; so you execute the script -> it generates the default value for dt -> 
    #       you wait for 10secs -> call log_bad() -> the timestamp is 10sec out ->
    #       wait another 10secs -> call log_bad() -> the timestamp is exactly the same,
    #       so it's now 20s out
    # NOTE: this kind of problem also happens if you set dt to any kind of mutable object
    # (e.g. a list or dictionary); in this instance, every time you call the function it will
    # use THE SAME list or dictionary. using an immutable type (like a tuple) is fine, however
    print('{}: {}'.format(dt, msg))

def log(msg, *, dt=None) :
    # A much better way to do it
    dt = dt or datetime.utcnow()
    # ... if dt was set by the user, use it's value; otherwise, generate the current timestamp
    print('{}: {}'.format(dt, msg))

# However, this behaviour *can* be useful, for caching data:
def factorial(n, cache={}):
    # When the function is first compile, cache points to a specific memory address
    # which will never change!
    if n < 1:
        return 1
    elif n in cache:
        return cache[n]
    else:
        print("calculating {0}!".format(n))
        result = n * factorial(n-1)
        cache[n] = result
        return result

print("print: ", time_it(print, 1, 2, 3, sep=' - ', end=' ***\n', rep=5))
print("compute_powers_1", time_it(compute_powers_1, 2, start=0, rep=5, end=20000))
print("compute_powers_2", time_it(compute_powers_2, 2, start=0, rep=5, end=20000))
print("compute_powers_3", time_it(compute_powers_3, 2, start=0, rep=5, end=20000))
print('--------')
log_bad("log_bad #1")
log("log #1")
time.sleep(10)
log_bad("log_bad #2")
log("log #2")
print('--------')
print("4! = ", factorial(4))
print("4! (now cached) = ", factorial(4))
print("6! (4! cached already) = ", factorial(6))