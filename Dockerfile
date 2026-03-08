FROM python:3.11-slim

WORKDIR /app

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 5000

CMD ["python", "app.py"]
```

### 📚 Пояснение каждой строки Dockerfile:
```
FROM python:3.11-slim
  └─ Берём базовый образ Python 3.11 (slim = лёгкая версия, без лишнего)

WORKDIR /app
  └─ Все следующие команды выполняются в папке /app внутри контейнера

COPY app/requirements.txt .
  └─ Копируем ТОЛЬКО requirements.txt (хитрость: Docker кэширует этот слой
     и не будет переустанавливать пакеты если код изменился, а зависимости нет)

RUN pip install --no-cache-dir -r requirements.txt
  └─ Устанавливаем зависимости (--no-cache-dir = не сохранять кэш pip,
     образ будет меньше)

COPY app/ .
  └─ Копируем весь остальной код приложения

EXPOSE 5000
  └─ Документируем что контейнер слушает порт 5000

CMD ["python", "app.py"]
  └─ Команда запуска при старте контейнера