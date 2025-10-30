FROM python:3.12-slim

# Install uv (package manager)
ENV UV_LINK_MODE=copy
RUN pip install --no-cache-dir uv

WORKDIR /app

# Copy dependency files and sync
COPY pyproject.toml ./
RUN uv sync --frozen || uv sync

# Copy application code
COPY src ./src

ENV PYTHONPATH=/app
EXPOSE 8000

CMD ["uv", "run", "uvicorn", "src.app.main:app", "--host", "0.0.0.0", "--port", "8000"]


