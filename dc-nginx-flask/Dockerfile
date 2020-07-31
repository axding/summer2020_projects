FROM python:3
RUN pip install flask
WORKDIR /code
COPY ./python /code
ENV FLASK_APP /code/main.py
RUN flask run --host=0.0.0.0
