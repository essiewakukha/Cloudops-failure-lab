FROM python:3.12-slim
WORKDIR /app
RUN useradd -r -u 10001 app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
USER 10001
ENV HOST=0.0.0.0 PORT=8080
EXPOSE 8080
CMD["sh", "-c", "exec uvicorn main:app --host $HOST --port $PORT"]