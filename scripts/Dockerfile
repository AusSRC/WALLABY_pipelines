FROM python:3.8
WORKDIR /app

# Install requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy templates
COPY templates templates

# Copy files
COPY download.py \
    generate_linmos_config.py \
    generate_sofia_config.py \
    verify_checksum.py \
    /app/
