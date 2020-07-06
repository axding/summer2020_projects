from flask import Flask
app = Flask(__name__)

@app.route('/app1')
def index():
    return 'Hello world!'
