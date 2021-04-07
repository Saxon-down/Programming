import weathercom
import json
import time
from datetime import datetime

# json structure returned by weather.com
# {
#    Temperatures {
#        highF
#        highC
#        HighTm         # High temp time
#        HighTmISO
#        HighTmISOLocal
#        LowF
#        LowC
#        LowTm
#        LowTmISO
#        LowTmISOLocal
#    }
#    WxDetails {        # weather
#        icon
#        wx
#    }
#    Precips {          # rainfall
#        sevenDayPrecipIn
#        sevenDayPrecipCm
#        mtdPrecipIn
#        mtdPrecipCm
#        precip24In
#        precip24cm
#    }
#    SunData {
#        sunrise
#        sunset
#        sunriseISO
#        sunsetISO
#        sunriseISOLocal
#        sunsetISOLocal
#    }
#    Moon {
#        moonriseLocal
#        moonsetLocal
#        moonriseISO
#        moonsetISO
#    }
#    city
#    longitude
#    latitude
#    weather.comCityCode
# }


collectedData = []

locationList = [
    "Malmö",
    "Östersund",
    "Kiruna",
]

# Define & generate headers for CSV files
topHeader = ["City ->"]
for location in locationList:
    topHeader.append(location)
    topHeader.append("")
    topHeader.append("")
mainHeader = ["Date"]
for location in locationList:
    mainHeader.append("LowTempC")
    mainHeader.append("HighTempC")
    mainHeader.append("Weather")



def archiveWeatherData(year, month, data):
    # ønce a month of data has been collected, write it to disk
    myFile = "weatherdata/" + str(year) + "-" + str(month) + ".txt"
    print("Writing " + myFile)
    archive = open(myFile, 'w')
    archive.write(";".join(topHeader))
    archive.write("\n")
    archive.write(";".join(mainHeader))
    archive.write("\n")
    for currentDate in data:
        newLine = []
        newLine.append(currentDate["Date"])
        for nextCity in currentDate["Results"]:
            newLine.append(nextCity["LowTempC"])
            newLine.append(nextCity["HighTempC"])
            newLine.append(nextCity["Weather"])
        archive.write("\n")
        archive.write(";".join(newLine))
    archive.close()
    print("... saved")


def isValidDate(y, m, d):
# Take a date and return whether it's valid or not
    try:
        datetime(year=y, month=m, day=d)
        return True
    except ValueError:
        return False


def getInterestingData(data):
    # Extract just the data I'm interested in
    results = {}
    results["Name"] = str(data["city"])
    results["LowTempC"] = str(data["Temperatures"]["lowC"])
    results["HighTempC"] = str(data["Temperatures"]["highC"])
    # Everything from 2017 on was fine, but in 2016 I found
    # dates which were missing certain data
    try:
        results["Weather"] = str(data["WxDetails"]["wx"])
    except:
        results["Weather"] = "n/a"
    return results


def getDetailsForDate(y, m, d):
    if isValidDate(y, m, d):
        today = {}
        today["Date"] = "/".join([str(y),str(m).zfill(2),str(d).zfill(2)])     # YYYY/MM/DD
        print(today["Date"])    # just shows that something's still happening
        today["Results"] = []
        for location in locationList:
            try:
                results = json.loads(
                    weathercom.getCityWeatherDetails(
                        location, 
                        queryType="particular-date-data", 
                        date={
                            "year":"{:04}".format(y),
                            "month":"{:02}".format(m),
                            "date":"{:02}".format(d)
                        }
                    )
                )
                today["Results"].append(getInterestingData(results))
            except:
                print("MISSING DATA:", location, today["Date"])
                results = {
                    "Name": location,
                    "LowTempC": "n/a",
                    "HighTempC": "n/a",
                    "Weather": "n/a"
                }
                today["Results"].append(results)
        return True, today
    else:
        return False, ""

# MAIN
for y in range(2013, 2022):
    for m in range(1,13):
        for d in range(1,32):
            wasValidDate, data = getDetailsForDate(y, m, d)
            if wasValidDate:
                collectedData.append(data)
        archiveWeatherData("{:04}".format(y), "{:02}".format(m), collectedData)