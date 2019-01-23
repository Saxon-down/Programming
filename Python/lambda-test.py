# lambdas are anonymous functions which return the result of a single calculation
# These nested lambda functions: 
#   the inner one takes a word and returns the first character
#   the outer one takes a sentence, feeds the words into the inner lambda and
#           stitches the results together
acronym = lambda sentence: ''.join(list(map((lambda word: word[0]), sentence.split()))).upper()

print(acronym("in my humble opinion"))
print(acronym("problem exists between keyboard and chair"))