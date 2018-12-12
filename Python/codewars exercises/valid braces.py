# Write a function that takes a string of braces, and determines if the
# order of the braces is valid. It should return true if the string is
# valid, and false if it's invalid.
#
# This Kata is similar to the Valid Parentheses Kata, but introduces
# new characters: brackets [], and curly braces {}. Thanks to @arnedag
# for the idea!
#
# All input strings will be nonempty, and will only consist of parentheses,
# brackets and curly braces: ()[]{}.
#
# What is considered Valid?
#
# A string of braces is considered valid if all braces are matched with the
# correct brace.

def validBraces(myStr) :
    if len(myStr) == 1 :
        myResult = False
    elif len(myStr) == 0 :
        myResult = True
    elif len(myStr) > 1 :
        if (((myStr[0] == '(') and (myStr[1] == ')'))
            or ((myStr[0] == '[') and (myStr[1] == ']'))
            or ((myStr[0] == '{') and (myStr[1] == '}'))) :
            myResult = validBraces(myStr[2:len(myStr)])
        elif (((myStr[-2] == '(') and (myStr[-1] == ')'))
            or ((myStr[-2] == '[') and (myStr[-1] == ']'))
            or ((myStr[-2] == '{') and (myStr[-1] == '}'))) :
            myResult = validBraces(myStr[0:len(myStr)-2])
        elif (((myStr[0] == '(') and (myStr[-1] == ')'))
            or ((myStr[0] == '{') and (myStr[-1] == '}'))
            or ((myStr[0] == '[') and (myStr[-1] == ']'))) :
            myResult = validBraces(myStr[1:len(myStr)-1])
        else :
            myResult = False
    return myResult

mytests = ['[[)]]', '[{}]', '(({}))', '{[}]', '({[})]', '(){}[]', '[{(]}]', '{}({})[]']
for test in mytests :
    if validBraces(test) :
        print(test + ": TRUE")
    else :
        print(test + ": FALSE")


# Best Practice:

def validBraces2(string):
    braces = {"(": ")", "[": "]", "{": "}"}
    stack = []
    for character in string:
        if character in braces.keys():
            stack.append(character)
        else:
            if len(stack) == 0 or braces[stack.pop()] != character:
                return False
    return len(stack) == 0


def validBraces3(s):
  while '{}' in s or '()' in s or '[]' in s:
      s=s.replace('{}','')
      s=s.replace('[]','')
      s=s.replace('()','')
  return s==''
