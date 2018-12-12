from itertools import permutations

def middle_permutation(string) :
    # This was the first attempt - works fine, but takes too long to 
    # complete, so it was failing the codewars tests
    all_perms = [''.join(current) for current in permutations(string)]
    all_perms.sort()
    mid = len(all_perms)//2
    if len(all_perms) % 2 == 0 :
        return all_perms[mid-1]
    else :
        return all_perms[mid]


def middle_permutation2(string) :
    # Time to be clever! Rather than finding the mid-point of all
    # permutations, , let's just generate the middle permutation directly
    # and skip all the others
    string = ''.join(sorted(string))        # sort the string first!
    midString = len(string) // 2
    returnStr = ""
    if len(string) % 2 == 0 :
        # In an even-length string, for the middle permutation it always
        # starts with the middle (rounded down) character
        returnStr = string[midString-1]
        # Then it takes each character from the end of the string, down to
        # the character we started with
        for count in reversed(range(midString,len(string))):
            returnStr += string[count]
        # .. and then it adds the remaining characters before the mid-point,
        # again in reverse order
        for count in reversed(range(0,midString-1)) :
            returnStr += string[count]
    else :
        # In an odd-length string, the middle permutation always starts 
        # with the middle character AND the one before it
        returnStr = string[midString] + string[midString-1]
        # Next, it has all of the characters after the ones we've already 
        # used, in reverse order
        for count in reversed(range(midString+1, len(string))) :
            returnStr += string[count]
        # .. and it finished off with all the characters before the ones
        # we've already used, in reverse order
        for count in reversed(range(0, midString-1)) :
            returnStr += string[count]
    return returnStr

# EXAMPLES;
# str is 1234:  2 43 1
# str is 123~456:  3 654 21
# str is 1234~5678:  4 8765 321
# str is 12345-6789A: 5 A9876 4321
# str is 1234-5-6789: 54 9876 321
# str is 123-4-567: 43 765 21
# str is 12-3-45: 32 54 1

print(middle_permutation2("1234567"))
# As a sanity check that the second version does actually work correctly,
# we'll run the 'proper' method and compare the two outputs
print(middle_permutation("1234567"))