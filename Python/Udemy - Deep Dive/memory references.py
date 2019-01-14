import sys
import ctypes

my_var = 10
print(str(my_var) + "\t", end='')
print(id(my_var), hex(id(my_var)))  # id() gives memory address of a var

other_var = my_var
print(str(other_var) + "\t", end='')
print(id(other_var), hex(id(other_var)))

greeting = "hello"
print(greeting + "\t", end='')
print(id(greeting), hex(id(greeting)))
print("\n-------------------------\n")

a = [1, 2, 3]
print(str(a) + "\t", end='')
print(id(a), hex(id(a)))

print("\tRefCount = " + str(sys.getrefcount(a)))  # Creates *another* reference, but releases it again on completion
print("\tReferenceCount = " + str(ctypes.c_long.from_address(id(a)).value))

b = a
print(str(b) + "\t", end='')
print(id(b), hex(id(b)))

c = a
print(str(c) + "\t", end='')
print(id(c), hex(id(c)))
print("\tReferenceCount = " + str(ctypes.c_long.from_address(id(a)).value))

b = c = None
print(str(c) + "\t\t", end='')
print(id(c), hex(id(c)))
print("\tReferenceCount = " + str(ctypes.c_long.from_address(id(a)).value))

a_id = id(a)
a = None
print("\tReferenceCount = " + str(ctypes.c_long.from_address(a_id).value))

print("\n\n\n")
######################
# GARBAGE COLLECTION
######################

# import ctypes	    # already done, above
import gc

def ref_count(address) :
    return ctypes.c_long.from_address(address).value

def object_by_id(object_id) :
    for obj in gc.get_objects() :
        if id(obj) == object_id :
            return "object exists"
    return "not found"

# Creating two classes to set up a circular reference for testing purposes
class A :
    def __init__(self) :
        self.b = B(self)
        print("A: self: {0}, b: {1}".format(hex(id(self)), hex(id(self.b))))

class B :
    def __init__(self, a) :
        self.a = a
        print("B: self: {0}, a: {1}".format(hex(id(self)), hex(id(self.a))))

gc.disable()    # disable garbage collector
my_var = A()
print("my_var : \t" + str(hex(id(my_var))))
print("my_var.b : \t" + str(hex(id(my_var.b))))
print("my_var.b.a : \t" + str(hex(id(my_var.b.a))))
a_id = id(my_var)
b_id = id(my_var.b)
print("\tRefCount for a_id = " + str(ref_count(a_id)))
print("\tRefCount for b_id = " + str(ref_count(b_id)))
print("object_by_id for a_id: " + object_by_id(a_id))
print("object_by_id for b_id: " + object_by_id(b_id))

my_var = None
print("\nmy_var set to " + str(my_var))
print("\tRefCount for a_id = " + str(ref_count(a_id)))
print("\tRefCount for b_id = " + str(ref_count(b_id)))
print("object_by_id for a_id: " + object_by_id(a_id))
print("object_by_id for b_id: " + object_by_id(b_id))

print("\nManually running garbage collector ...")
gc.collect()
print("object_by_id for a_id: " + object_by_id(a_id))
print("object_by_id for b_id: " + object_by_id(b_id))
# These memory addresses are now freed up and could be used by other
# applications, so the ref_counts may not be 0
print("\tRefCount for a_id = " + str(ref_count(a_id)))
print("\tRefCount for b_id = " + str(ref_count(b_id)))

# Final note: modifying a variable allocates it a new memory address!
print("\n")
for i in range(5) :
    print("i = " + str(i) + "\t" + str(hex(id(i))))
print("\n")
x = 5
while x > 0 :
    print("x = " + str(x) + "\t" + str(hex(id(x))))
    x -= 1
print("\n")
# Note that for each instance of x == i, the variables use the SAME memory address!!! (this doesn't happen for all data types - mutable vs immutable types)
# immutable == all numbers (int, float, bool, etc), strings, tuples, frozen sets, user-defined classes*
# mutable = lists, sets, dictionaries, user-defined classes*
# *user-defined classes: depends on how they're defined
# WARNING: a tuple is immutable and cannot be changed; however, if you create
#   a tuple if LISTS, the lists are MUTABLE and CAN be changed. This is
#   the tuple is storing references to the lists, not the lists themselves

print(0, " uses ", sys.getsizeof(0), " bytes of RAM") # Returns how much memory a variable 
        # is using
print(1000, " uses ", sys.getsizeof(1000), " bytes of RAM")
print(1000000, " uses ", sys.getsizeof(1000000), " bytes of RAM")
