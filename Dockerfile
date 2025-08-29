# syntax=docker/dockerfile:1.7
FROM python:3.11-slim AS api

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Базовые утилиты и компилятор для nativе-зависимостей (bcrypt, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1) зависимости отдельно — кэшируем слой
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# 2) код
COPY . /app

# 3) каталоги и линк на БД:
#    В репо уже лежит pathrag.db — удалим и сошлём на /state/pathrag.db,
#    чтобы хранить БД на отдельном volume.
RUN mkdir -p /app/data /app/uploads /state \
 && rm -f /app/pathrag.db \
 && ln -s /state/pathrag.db /app/pathrag.db

# Небольшой healthcheck по корневому маршруту
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=5 CMD curl -fsS http://localhost:8000/ || exit 1

# Нерутовый пользователь
RUN useradd -m appuser && chown -R appuser:appuser /app /state
USER appuser

# Запуск uvicorn (main:app — фактическая точка входа)
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]