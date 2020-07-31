FROM python:3
RUN pip install flask
RUN pwd
RUN ls -lR .
COPY ./python/main.py /code/main.py
ENV FLASK_APP /code/main.py
WORKDIR /code
CMD ["flask", "run", "--host=0.0.0.0"]

