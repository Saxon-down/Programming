import re

# FIXME:
# This one was hard; the code works but I'm still failing on the performance side. I think I need to look at whether RIGHT is closer to 2^n (lower) or 2^n+1 (higher), and work from there
# .. so compare (2^n + 2^n+1)/2 vs RIGHT ... if RIGHT is lower, use the current method, otherwise use a different approach
# Even with those modifications, I still couldn't get it to complete within the time-limit ><

def subCountOnes(left, right):
    total = 0
    print("SUBCOUNTONES.1 // left, right, range", left, right, right-left)
    for integer in range(left,right+1) :
        if integer % 1000000 == 0 :
            print("SUBCOUNTONES.2 // integer", integer)
        toMatch = "1"
        allMatches = re.findall(toMatch, str(bin(integer)))
        total += len(allMatches)
    print("SUBCOUNTONES.3 // left, right, total", left, right, total)
    return total


def twoToPower(num) :
    binNum = bin(num)
    power = len(binNum) - 3	        # reduce by 2 because it starts with '0x'
        # and then by another 1 because 5 == 101, so closest would be 2^2 (3-1)
#    print("twoToPower: num, bin, power", num, binNum, power)
    return power

def powerOf(num) :
    total = 1
    for _ in range (0, num) :
        total *= 2
    print("POWEROF // num, total", num, total)
    return total

def sumForPower(num) :
    # 2^n == 2 * v[2^n-1] + (2^n-1)-1
    power = 2
    total = 5
    while power < num :
        power += 1
        total = (2 * total) + powerOf(power-1) - 1
    print("SUMFORPOWER // power, total", num, total)
    return total

def count_ones(num1, num2) :
    lowPower = twoToPower(num1) + 1	    # 2^lowPower must be >= num1
    highPower = twoToPower(num2)        # 2^highPower must be <= num2
    print("\nCOUNT_ONES // num1, lowPower, num2, highPower", num1, lowPower, num2, highPower)
    total = subCountOnes(num1, powerOf(lowPower)) 
    total += sumForPower(highPower) 
    total -= sumForPower(lowPower)
    if num2 <= (powerOf(highPower) + powerOf(highPower+1))/2:
        print("COUNTONES // branch_low")
        total += subCountOnes(powerOf(highPower)+1,num2) 
    else :
        print("COUNTONES // branch_high")
        total -= subCountOnes(num2+1, powerOf(highPower)) 
    print("Clever total vs Sanity Check = ", total, subCountOnes(num1, num2))
    return total

count_ones(18, 1025)
count_ones(1223, 1234567890)
