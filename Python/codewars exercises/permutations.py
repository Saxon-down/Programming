def permutations(string):
    result = set([string])      # Creates set (hash table with no vals, only keys)
    if len(string) == 2:        # There's only two possibles: ab and ba
        result.add(string[1] + string[0])
    elif len(string) > 2:
        for index, character in enumerate(string):
            # for each character in the string, return the char and it's position in the list
            for substring in permutations(string[:index] + string[index + 1:]):
                # Recursively call this function, with the specified char removed from string
                result.add(character + substring)
    return list(result)