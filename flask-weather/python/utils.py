from datetime import datetime

def convert_to_C(temp):
    return round(temp - 273.15, 2)

def convert_to_in(pressure):
    return round(pressure / 33.86, 2)

def convert_std(time, timezone):
    return datetime.fromtimestamp(time + timezone).strftime('%-I:%M')

def convert_to_mph(speed):
    return round(speed * 2.23694, 1)

direction = ["N","N/NE","NE","E/NE","E","E/SE","SE","S/SE","S","S/SW","SW","W/SW","W","W/NW","NW","N/NW","N"]
def convert_dir(deg):
    idx = deg % 360
    idx = round(idx / 22.5, 0) + 1
    return direction[int(idx)]