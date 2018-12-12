import sys

def myFunc(mystr) :
	return mystr.lower().count("x") == mystr.lower().count("o")


print("Enter string:")
inputString = input().lower()
print("checking on string:", end = "")
print(inputString)
if myFunc(inputString) :
	print("Xs and Os match")
else :
	print("different counts")