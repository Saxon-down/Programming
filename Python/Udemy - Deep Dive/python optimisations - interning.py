# Python will create singleton integers in the range -5:256
import string
import time

def my_func() :
    a = 24 * 60
    b = (1,2) * 5
    c = 'abc' * 3
    d = 'ab' * 11
    e = "the quick brown fox" * 5
    f = ['a', 'b'] * 3

print(my_func.__code__.co_consts)
# Shows what python stores in memory and that, as well as 
# the variable values themselves, the results of a bunch of
# the calculations are included too (so 1440 is listed [24 * 
# 60], as are strings <= 20 chars)


char_list = list(string.ascii_letters)
char_tuple = tuple(string.ascii_letters)
char_set = set(string.ascii_letters)

def membership_test(n, container) :
    for _ in range(n) :
        if 'z' in container :
            pass

for container in (char_list, char_set, char_tuple) :
    start = time.perf_counter()
    membership_test(10000000, container)
    end = time.perf_counter()
    print(type(container), "\t", end-start)
# .. shows that lookups in a set is an order of magnitude 
# faster than in a list or tuple