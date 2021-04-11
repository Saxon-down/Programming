import weathercom
import json
import time
from datetime import datetime
import os

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


# A couple of constants used for defining date ranges, etc
first = 0   # The first element in the tuple, for readability
last = 1    # The last element in the tuple, for readability
years = (2014,2021) # Tuple to define range of years
months = (1,12)      # Tuple to define range of months
days = (1,31)        # Tuple to define range of days


locationList = [
    "Horsham",
    "Malmö",
    "Östersund",
    "Kiruna",
]

# Define & generate headers for CSV files
header = ""


def archiveWeatherData(fileHeader, data, location, monthly=False, month="no"):
    # Archive either a month's or year's worth of data, depending on whether
    # 'monthly' was set (if it was, there should be a corresponding 'month'
    # value).
    storage = "data"    # Default archive folder is 'data'; create if necessary
    if not os.path.isdir(storage):
        os.mkdir(storage)
    filename = ""
    if monthly:         # We're getting a month of data
        storage = "/".join([storage, location])
        filename = ".".join([month, "txt"])
        print("aWD: archiving month to: ", filename)
        if not os.path.isdir(storage):
            os.mkdir(storage)
    else:               # We're getting all data for the location
        filename = ".".join([location, "txt"])
        print("aWD: archiving location to: ", filename)
    filename = "/".join([storage, filename])
    # write all data to the file we've created
    archive = open(filename, 'w')
    archive.write(fileHeader)
    for entry in data:
        archive.write(";".join(entry)+"\n")
    archive.close()


def buildFileHeader():
    # Generates headers for CSV files; headers are spread across two lines;
    # the first lists the fields, the second the years for each field
    myTopHeader = []
    myTopHeader.append("Weather")
    for y in range(years[first], years[last]-1): myTopHeader.append("")
    myTopHeader.append("Date")
    myTopHeader.append("Low Temp (C)")
    for y in range(years[first], years[last]-1): myTopHeader.append("")
    myTopHeader.append("Date")
    myTopHeader.append("High Temp (C)")
    #
    for y in range(years[first], years[last]-1): myTopHeader.append("")
    myMainHeader = []
    for y in range(years[first], years[last]): myMainHeader.append(str(y))
    myMainHeader.append("")
    for y in range(years[first], years[last]): myMainHeader.append(str(y))
    myMainHeader.append("")
    for y in range(years[first], years[last]): myMainHeader.append(str(y))
    #
    return "\n".join([
        ";".join(myTopHeader), 
        ";".join(myMainHeader),""
    ])



def consolidateWeatherData(data):
    # Once all data has been collected and archived, consolidate it so it's
    # ready to be imported into e.g. Numbers
    # Consolidation means collecting all data for a given location into a 
    # single CSV, with separate columns for each year
    returnData = []
    weather = []
    lowC = []
    highC = []
    for y in data["Results"]:
        weather.append(y["Weather"])
        lowC.append(y["LowTempC"])
        highC.append(y["HighTempC"])
    return weather + [data["Date"]] + lowC + [data["Date"]] + highC


def getDetailsForDate(location, m, d):
    # Connects to weather.com and downloads data for a given day of the year,
    # for each year we've specified. From the data we download, extract the
    # bits we're interested in
    data = {}
    data["Date"] = "/".join([
            str(m).zfill(2),
            str(d).zfill(2)
    ])     # MM/DD
    data["Results"] = []
    for y in range(years[first], years[last]+1):
        # weather.com is missing random data entries all over the place; when
        # we hit one, handle it gracefully rather than crashing
        try:    # data found!
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
            data["Results"].append(extractInterestingData(results))
        except: # data missing OR invalid date
            print("MISSING DATA:", location, data["Date"])
            data["Results"].append({
                "LowTempC": "n/a",
                "HighTempC": "n/a",
                "Weather": "n/a"
            })
    data = consolidateWeatherData(data)
    return data


def extractInterestingData(data):
    # Extract just the data I'm interested in
    results = {}
    results["LowTempC"] = str(data["Temperatures"]["lowC"])
    results["HighTempC"] = str(data["Temperatures"]["highC"])
    # Everything from 2017 on was fine, but in 2016 I found
    # dates which were missing certain data
    try:
        results["Weather"] = str(data["WxDetails"]["wx"])
    except:
        results["Weather"] = "n/a"
    return results


def isValidDate(m, d):
# Take a date and return whether it's valid or not for at least
# one of the years (e.g. Feb 29th is valid if one of the years is
# a leapyear, but not otherwise)
    isValid = False
    for y in range(years[first], years[last]+1):
        try:
            date = datetime(year=y, month=m, day=d)
            now = datetime.now()
            if date <= now: isValid = True
        except ValueError: ()   # ignore 
    return isValid


# MAIN
header = buildFileHeader()
for location in locationList:
    print("location: ", location)
    locationData = []
    for m in range(months[first], months[last]+1):
        print("month: ", "{:02}".format(m))
        monthlyData = []
        for d in range(days[first], days[last]+1):
            if isValidDate(m, d):
                data = getDetailsForDate(location, m, d)
                monthlyData.append(data)
                locationData.append(data)
        archiveWeatherData(
                header,
                monthlyData, 
                location,
                monthly=True, 
                month="{:02}".format(m)
        )
    archiveWeatherData(
        header,
        locationData,
        location
    )