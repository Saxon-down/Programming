def fold_array(array, runs):
    for folds in range(runs) :
        newArray = []
        oldLen = len(array)
        newLen = oldLen // 2
        for index in range((newLen)) :
            farIndex = oldLen - index - 1
            newArray.append(array[index] + array[farIndex])
        if len(array) % 2 != 0 :
            newArray.append(array[newLen])
        array = newArray
    return array

test = [1, 2, 3, 4, 5, 5]
test = fold_array(test, 1)
print(test)