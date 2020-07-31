FROM python:3
RUN pip install flask
COPY ./dc-nginx-flask/python/main.py /code/main.py
ENV FLASK_APP /code/main.py
WORKDIR /code
CMD ["flask", "run", "--host=0.0.0.0"]

