FROM python:3.11-slim

WORKDIR /app

# Install system dependencies that might be needed for Python packages like psycopg2
RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*

COPY guess_game-main/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY guess_game-main/ .

ENV FLASK_APP=run.py

# Create a wrapper script to monitor application health
RUN apt-get update && apt-get install -y curl && \
    echo '#!/bin/sh\n\
flask run --host=0.0.0.0 --port=5000 &\n\
FLASK_PID=$!\n\
sleep 10\n\
while true; do\n\
  # Make a fake guess to trigger a database interaction\n\
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"guess\":\"a\"}" http://127.0.0.1:5000/guess/123)\n\
  if [ "$STATUS" = "500" ]; then\n\
    echo "Backend detected 500 Error (Likely broken DB connection). Crashing to trigger Docker restart..."\n\
    kill -9 $FLASK_PID\n\
    exit 1\n\
  fi\n\
  sleep 5\n\
done\n\
' > /app/run_wrapper.sh && chmod +x /app/run_wrapper.sh

# The application is run via the wrapper
CMD ["/app/run_wrapper.sh"]
