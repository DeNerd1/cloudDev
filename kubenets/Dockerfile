FROM python:3

WORKDIR /home

COPY . .

RUN pip3 install flask


VOLUME [ "${pwd}/data:/web-data" ]

CMD [ "python","app.py" ]