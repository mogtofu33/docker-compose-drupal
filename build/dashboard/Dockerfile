FROM python:3-alpine

LABEL maintainer="moimog33@gmail.com"

COPY ./app /app

RUN ls -lAh /app \
  && ls -lAh /app/static \
  && ls -lAh /app/static/assets

WORKDIR /app

RUN pip install --upgrade pip \
  && pip install -r requirements.txt

RUN ls -lAh /app \
  && ls -lAh /app/static \
  && ls -lAh /app/static/assets

EXPOSE 5000

ENTRYPOINT ["python"]

CMD ["main.py"]
