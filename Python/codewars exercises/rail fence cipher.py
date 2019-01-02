def fence(string, numrails):
    fence = [[None] * len(string) for n in range(numrails)] # empty list of lists
    rails = list(range(numrails - 1)) + list(range(numrails - 1, 0, -1))    # [0, 1, 2, ... 2, 1]
    for index, char in enumerate(string):
        # Place each character in the string onto the correct rail, keeping the index the same .. this will result in a list-of-lists with a lot of empty nodes; each index will only have a character on one of the rails
        fence[rails[index % len(rails)]][index] = char
    # Now return the list-of-lists as a single list, skipping each empty node
    return [char for rail in fence for char in rail if char is not None]

def encode_rail_fence_cipher(string, rails):
    return ''.join(fence(string, rails))

def decode_rail_fence_cipher(string, rails):
    strRange = range(len(string))
    pos = fence(strRange, rails)
    return ''.join(string[pos.index(rails)] for rails in strRange)


encodedStr = encode_rail_fence_cipher('Going to write another really, really long input string to test this mother$£!)&^@ out!!!', 5)  
print(encodedStr)
decodedStr = decode_rail_fence_cipher(encodedStr, 5)
print(decodedStr)
