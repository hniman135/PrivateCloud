# Multi-stage Dockerfile for FastAPI app
FROM registry.redhat.io/ubi8/python-39:latest AS builder

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM registry.redhat.io/ubi8/python-39:latest

# Copy installed packages
COPY --from=builder /opt/app-root/lib/python3.9/site-packages /opt/app-root/lib/python3.9/site-packages

# Copy application code
COPY . /opt/app-root/src

# Set working directory
WORKDIR /opt/app-root/src

# Expose port
EXPOSE 8000

# Run the application
CMD ["./.s2i/bin/run"]