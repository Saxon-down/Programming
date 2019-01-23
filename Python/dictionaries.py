sentence = "now is the time for all good people to come to the aid of their party"
words = sentence.split(" ")
numWords = {}
for i in range(0, len(words)) :
    if words[i] in numWords :
        numWords[words[i]] += 1
    else :
        numWords[words[i]] = 1
print("Word list and count: ")
for key in numWords.keys() :
    print(key, numWords[key])