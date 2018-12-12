# Return the number (count) of vowels in the given string.
# We will consider a, e, i, o, and u as vowels for this Kata.
# The input string will only consist of lower case letters and/or spaces.

def getCount(inputStr):
    num_vowels = 0
    num_vowels = {c : inputStr.count(c) for c in ["a", "e", "i", "o", "u"]}
    return num_vowels

print(getCount("Mary had a little lamb"))


# Best practices:

def getCount1(s):
    return sum(c in 'aeiou' for c in s)
