FROM python:3.8
WORKDIR /app

# Install requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy templates
COPY templates .

# Copy files
COPY *.py .
