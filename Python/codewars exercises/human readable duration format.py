from datetime import timedelta
seconds = (1*365*24*3600) + (5*24*3600) + (25*60) + 17

output = []
years, seconds = divmod(seconds, 365*24*3600)
if years : output.append(str(years) + " years")
days, seconds = divmod(seconds, 24*3600)
if days: output.append(str(days) + " days")
hours, seconds = divmod(seconds, 3600)
if hours : output.append(str(hours) + " hours")
minutes, seconds = divmod(seconds, 60)
if minutes : output.append(str(minutes) + " minutes")
if seconds : output.append(str(seconds) + " seconds")
outStr = []
for iteration in range(len(output)) :
    if len(output) > 1 and iteration == len(output)-1 :
        outStr.append(" and ")
    elif len(output) > 1 and 0 < iteration < len(output) :
        outStr.append(", ")
    outStr.append(output[iteration])
print("".join(outStr))

