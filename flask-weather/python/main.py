import requests
from flask import Flask, request, render_template
import utils
app = Flask(__name__)

@app.route('/app', methods = ['POST', 'GET'])
def search_city():
    if request.method == 'POST':
        city = request.form['city']
    else:
        data = {
        }
        return render_template('index.html', data = data) 
    
    API_KEY = '' # my API key

    # call API and convert response into Python dictionary
    url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&APPID={API_KEY}'
    response = requests.get(url).json()

    # error like unknown city name, inavalid api key
    if response.get('cod') != 200:
        message = response.get('message', '')
        data = {
            "error": f'Error getting information for {city.title()}. {message}'
        }
        return render_template('index.html', data = data) 

    temp_inC = utils.convert_to_C(response['main']['temp'])
    minTemp = utils.convert_to_C(response['main']['temp_min'])
    maxTemp = utils.convert_to_C(response['main']['temp_max'])
    feelsTemp = utils.convert_to_C(response['main']['feels_like'])
    time_sunrise = utils.convert_std(response['sys']['sunrise'], response['timezone'])
    time_sunset = utils.convert_std(response['sys']['sunset'], response['timezone'])

    data = {
        "city": str(response['name']),
        "country_code": str(response['sys']['country']),
        "temp": str(temp_inC) + '°C',
        "temp_min": str(minTemp) + '°C',
        "temp_max": str(maxTemp) + '°C',
        "feel": str(feelsTemp) + '°C',
        "pressure": str(utils.convert_to_in(response['main']['pressure'])) + ' in',
        "humidity": str(response['main']['humidity']) + '%',
        "weather": str(response['weather'][0]['main']),
        "desc": str(response['weather'][0]['description']),
        "vis": str(response['visibility']),
        "wind_speed": str(utils.convert_to_mph(response['wind']['speed'])) + 'mph',
        "wind_dir": utils.convert_dir(response['wind']['deg']),
        "sunrise": time_sunrise,
        "sunset": time_sunset
    }

    return render_template('index.html', data = data) 
