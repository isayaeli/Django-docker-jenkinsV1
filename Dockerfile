# Stage 1: Build stage
FROM python:3.12 as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential libpq-dev --no-install-recommends

# Copy only requirements first to leverage caching
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --prefix=/install -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.12-slim

WORKDIR /app

# Copy installed dependencies from builder
COPY --from=builder /install /usr/local

# Copy project files
COPY . .

# Expose port
EXPOSE 8000

# Run Django app
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
