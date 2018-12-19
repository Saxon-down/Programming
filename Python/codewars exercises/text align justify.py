def justify(text, width) :
    words = text.split()
    sentence = []
    sentenceWidth = 0
    spaces = 0
    returnList = []
    for iteration in range(0, len(words)) :
        if sentenceWidth + len(words[iteration]) + spaces + 1 > width :
            # if sentenceWidth + length_of_this_word + minimum_number_of_spaces > width, this word would the new sentence too long!
            buffer = width - sentenceWidth - spaces
            divisor, remainder = divmod(buffer, spaces)
                # Each pair of words needs at least 'divisor' spaces, but the first 'remainder' pairs need an additional space
            spacer = " " * (divisor + 1)
            for counter in range(0, len(sentence)-1) :
                sentence[counter] += spacer
                if remainder > 0 :
                    remainder -= 1
                    sentence[counter] += " "
            returnList.append("".join(sentence))
            # Reset the sentence and continue
            sentence = [words[iteration]]
            sentenceWidth = len(words[iteration])
        else :
            # New sentence isn't long enough, so add another word
            sentence.append(words[iteration])
            spaces = len(sentence) - 1
            sentenceWidth += len(words[iteration])
        if iteration == len(words) - 1 :
            # everything else is done; return the remaining sentence
            returnList.append(" ".join(sentence))   
    return "\n".join(returnList)




testString = "This is my test string, isn't it pretty? I'm sure it'll do a great job of testing my script, especially if I also throw in a bunch of long words: psychiatrist, psychologist, volcanology, mathematics, pythagoras, continuum, aardvark, cabbage, philosopher, swordfish."
width = 50
ts2 = "123 45 6"
w2 = 7
for count in range(1,width+1) :
    print(count % 10, end='')
print()
print(justify(testString, width))
print(justify(ts2, w2))