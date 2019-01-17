a = 2
b = 0

while a < 4 :
    print("------------")
    a += 1
    b -= 1
    try :
        a / b
    except ZeroDivisionError:   # https://docs.python.org/3/tutorial/errors.html
        print("{0}, {1} - division by zero error".format(a, b))
        break
    finally:    
        # Still runs regardless of whether you executed the TRY or EXCEPT blocks
        print("Everything in the FINALLY block always runs")
    print("{0}, {1} - main loop".format(a, b))
else :      # Only runs if the BREAK condition wasn't hit
    print("Code executed without a division by zero error")