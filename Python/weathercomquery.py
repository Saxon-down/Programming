import weathercom
import json
import time
from datetime import datetime

locationList = [
    "Flyinge",
    "Jönköping",
    "Töreboda",
    "Karlstad",
    "Ludvika",
    "Mora Sweden",
    "Östersund",
    "Oslo"
]

wDetails = {}

def getWeather(loc):
    details = weathercom.getCityWeatherDetails(loc)
    details = json.loads(details)
    # all weather details are in the nested structure, "vt1observation"
    myWeatherDetails = details["vt1observation"]    
    # These 3 details aren't included with the weather structure, and need to be added separately
    myWeatherDetails["city"] = details["city"]
    myWeatherDetails["longitude"] = details["longitude"]
    myWeatherDetails["latitude"] = details["latitude"]
    return myWeatherDetails


def archiveWeatherData(location, data):
    print("Writing " + location)
    myFile = location + ".data"
    try:
        print(data, file=open(myFile, "a"))
    except IOError:
        print("I/O error")

# MAIN
while 1:                        # loop indefinitely
    print(datetime.now())       # Want to see last loop run, in case it crashes
    for location in locationList:
        archiveWeatherData(location, getWeather(location))
    print("sleeping ...\n\n")   # show me it's finished the current loop
    time.sleep(60*60)   # in seconds; 60s x 60m = 1h

