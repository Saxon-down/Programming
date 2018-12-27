def rgb(r, g, b):
    # Smaller and neater
    limited = lambda x: min(255, max(x, 0))     # Constrains all values to 0-255 range
    return ''.join([format(colour, '02X') for colour in [limited(r), limited(g), limited(b)]])


def rgb3 (r,g,b) :
    # Long-winded version
    returnString = ""
    for colour in [r,g,b] :
        if colour > 255 : returnString += "FF"
        elif colour <= 0 : returnString += "00"
        else :
            returnString += format(colour, '02X')
    return returnString


print(rgb(255, 255, 255)) # returns FFFFFF
print(rgb(255, 255, 300)) # returns FFFFFF
print(rgb(0,0,0)) # returns 000000
print(rgb(148, 0, 211)) # returns 9400D3