FROM python:3
EXPOSE 5000

COPY . .

RUN pip install flask

RUN python3 test.py 

CMD [ "python3", "app.py" ]