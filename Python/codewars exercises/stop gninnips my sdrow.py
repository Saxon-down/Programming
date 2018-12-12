# Write a function that takes in a string of one or more words, and returns
# the same string, but with all five or more letter words reversed (Just like
# the name of this Kata). Strings passed in will consist of only letters and
# spaces. Spaces will be included only when more than one word is present.

sentence = "Hey fellow warriors"
# Mine solution:
def spin_words(sentence):
    returnlist = []
    for word in (sentence.split(" ")):
        if (len(word) >= 5):
            word = word[::-1]
        returnlist.append(word)
    return " ".join(returnlist)


# Best Practice:
def spin_words(sentence):
    # Your code goes here
    return " ".join([x[::-1] if len(x) >= 5 else x for x in sentence.split(" ")])
