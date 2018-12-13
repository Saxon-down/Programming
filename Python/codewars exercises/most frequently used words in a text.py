import string

def top_3_words(text):
    myPunctuation = "\",./;:+=-_)([]{}!?"
    translator = str.maketrans(myPunctuation, '                  ')
    text = text.translate(translator)
    wordList = {}
    for word in text.lower().split() :
        if len(set(word)) == 1 and word.count("'") : break
        if not word in wordList :
            wordList[word] = 1
        else :
            wordList[word] += 1
    count = 0
    returnList = []
    search = [(key, wordList[key]) for key in sorted(wordList, key=wordList.get, reverse=True)]
    for key, value in search:
        returnList.append(key)
        count += 1
        if count == 3 : break
    return returnList


myText = "Tiger, Tiger, burning bright, in  the  forests  of  the  night,  what immortal hand or eye can frame thy fearful symmetry? There's a  tiger over there there's there's"
print(top_3_words(myText))
