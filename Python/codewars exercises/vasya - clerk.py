def tickets(people):
    # People will pay with either a $25, $50 or $100 bill; tickets are $25
    returnVal = "NO"
    bills = [0, 0, 0]       # 25, 50, 100
    for payment in people :
        if payment == 25 :
            bills[0] += 1
            returnVal = "YES"
        else :
            if payment == 50 and bills[0] > 0 :
                bills[1] += 1
                bills[0] -= 1
                returnVal = "YES"
            elif payment == 100 :
                if bills[1] > 0 and bills[0] > 0 :
                    bills[2] += 1
                    bills[1] -= 1
                    bills[0] -= 1
                    returnVal = "YES"
                elif bills[0] >= 3 :
                    bills[2] += 1
                    bills[0] -= 3
                    returnVal = "YES"
                else :
                    returnVal = "NO"
                    break
            else :
                returnVal = "NO"
                break
    return returnVal


print(tickets([25, 25, 50]))
print(tickets([25, 100]))
print(tickets([25, 25, 50, 50, 100]))
print(tickets([25, 50, 25, 100]))
print(tickets([25, 25, 25, 25, 25, 100, 100]))
