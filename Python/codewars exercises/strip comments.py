def solution(string,markers):
    returnList = []
    for current in string.split("\n") :
        for m in markers:
            index = current.find(m)
            if index >= 0 and index < len(current) :
                current = current[:index]
        returnList.append(current.strip())
    return "\n".join(returnList)

def solution_best_practices(string,markers):
    # Copied from codewars 'best practices' solutions after submission
    parts = string.split('\n')
    for m in markers:
        parts = [current.split(m)[0].rstrip() for current in parts]
    return '\n'.join(parts)

# print(solution("apples, pears # and bananas\ngrapes\nbananas !apples", ["#", "!"]))
# print(solution("a #b\nc\nd $e f g", ["#", "$"]))
print(solution("#", ["#"]))