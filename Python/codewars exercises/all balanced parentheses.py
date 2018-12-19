masterList = []

def buildPossible(myDict, count) :
    for myStr, balance in myDict.items() :
        newDict = dict()
        if len(myStr) == count*2 :
            # time to exit and return the list
            masterList.append(myStr)
        else :
            if balance > 0 :
                # next can be ( or )
                if count*2 > len(myStr) + balance :
                    # Still got enough room to pair off any '(' we add
                    newDict[myStr + "("] = balance + 1
                # Need to counter a previous ')'
                newDict[myStr + ")"] = balance - 1
            else :
                # next has to be (
                newDict[myStr + "("] = balance + 1
            buildPossible(newDict, count)

def balanced_parens(count) :
    masterList.clear()
    if count == 0 : return ['']
    elif count == 1 : return ['()']
    else : buildPossible({"": 0}, count)
    return sorted(masterList)



for count in range(3,4) :
    print(balanced_parens(count))
