# ─── Clash of Minds Production Dockerfile for Hugging Face & Cloud ───
FROM python:3.11-slim

# Prevent Python from writing .pyc files & buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=7860

# Install minimal OS dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set up user named "user" with UID 1000 (Hugging Face requirement)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Install lightweight CPU-only PyTorch first (saves ~2.5 GB)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# Copy and install Python dependencies
COPY --chown=user backend/requirements.txt $HOME/app/backend/requirements.txt
RUN pip install --no-cache-dir -r $HOME/app/backend/requirements.txt

# Copy backend and frontend code
COPY --chown=user backend $HOME/app/backend
COPY --chown=user frontend $HOME/app/frontend

# Set Python module search path to backend
ENV PYTHONPATH=$HOME/app/backend

WORKDIR $HOME/app/backend

EXPOSE 7860

# Launch Uvicorn on dynamic port (7860 for Hugging Face, or dynamic $PORT on Render)
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-7860}"]
