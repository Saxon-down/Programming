def bowling_score(allFrames):
    scoresList = []
    frameList = allFrames.split(" ")
    # Create a list where each entry is a sub-list of the scores of each ball
    for frame in frameList :
        balls = list(frame)
        for index, item in enumerate(balls) :
            if item == "X" :
                balls[index] = 10    
        if "/" in balls:
            balls[1] = 10 - int(balls[0])
        scoresList.append(list(map(int, balls)))
    # Now go through both lists at once, and add in the additional scores
    # from strikes and spares
    for index in range(0,9) :
        if frameList[index] == "X" :
            scoresList[index].append(scoresList[index+1][0])
            if len(scoresList[index+1]) > 1 :
                scoresList[index].append(scoresList[index+1][1])
            else :
                scoresList[index].append(scoresList[index+2][0])
        elif "/" in frameList[index] :
            scoresList[index].append(scoresList[index+1][0])
    # Finally, return the sum of the list of sublists
    return final_score(scoresList)

def final_score(allFrames) :
    total = 0
    for frame in allFrames :
        for score in frame :
            total += score
    return total

print(bowling_score("72 72 72 72 72 72 72 72 72 72"))
print(bowling_score("72 81 80 X 6/ 90 9/ 71 X 81"))
print(bowling_score("X X X X 6/ 90 9/ 71 X 81"))
print(bowling_score("72 81 80 X 6/ 90 9/ 71 X 81"))
print(bowling_score("X X X X X X X X X XXX"))
