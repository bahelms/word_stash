# Slim Python base
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    # set by Fly; good to default our app to it
    PORT=8080

# System deps for trafilatura/lxml and sumy tokenizers
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates libxml2-dev libxslt1-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/

# Install base requirements first (without torch/transformers), then add them.
# Using the CPU wheels index for torch to avoid bringing CUDA.
RUN pip install --upgrade pip \
    && pip install --no-cache-dir fastapi==0.115.0 uvicorn[standard]==0.30.6 trafilatura==1.9.0 sumy==0.11.0 yake==0.4.8

# Optional: install abstractive stack. If you don't need it, comment this block out
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch==2.3.1+cpu \
    && pip install --no-cache-dir transformers==4.43.3 huggingface_hub==0.24.5

# Pre-download the small summarization model to avoid cold starts (only if abstractive is enabled)
# This step won't fail if model isn't used at runtime, but it keeps image warm.
RUN python - <<'PY'
from transformers import pipeline
pipe = pipeline('summarization', model='sshleifer/distilbart-cnn-12-6', device=-1)
print('Model ready')
PY


COPY app.py /app/app.py

EXPOSE 8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]

