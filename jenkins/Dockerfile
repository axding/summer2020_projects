FROM python:3

RUN pip install flask

# copies my personal main.py file onto the container
COPY ./jenkins/python/main.py /code/main.py

ENV FLASK_APP /code/main.py

WORKDIR /code

# runs the flask app
CMD ["flask", "run", "--host=0.0.0.0"]
