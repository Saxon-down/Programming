def tickets(people):
    # People will pay with either a $25, $50 or $100 bill; tickets are $25
    bills = { 25 : 0, 50 : 0, 100 : 0 }
    for payment in people :
        bills[payment] += 1
        if payment > 25 : bills[25] -= 1
        if payment == 100 :
            if bills[50] > 0 : bills[50] -= 1
            else : bills[25] -= 2
        if '-' in str(bills.values()) :
            return "NO"
    return "YES"

print(tickets([50,50,50]))
print(tickets([25, 25, 50]))
print(tickets([25, 100]))
print(tickets([25, 25, 50, 50, 100]))
print(tickets([25, 50, 25, 100]))
print(tickets([25, 25, 25, 25, 25, 100, 100]))
