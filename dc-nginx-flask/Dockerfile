FROM python:3
RUN pip install flask
WORKDIR /code
RUN pwd
RUN ls -r
COPY ./python/main.py /code/main.py
ENV FLASK_APP /code/main.py
CMD ["flask", "run", "--host=0.0.0.0"]

