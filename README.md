# no-emo-vibe

A SwiftUI-based iOS application designed to help users track and manage their mood with interactive features and a calming UI.

<br />

<div align="center">
  <img src="https://github.com/user-attachments/assets/2509cc74-8f60-4316-9a52-e504a088dc02" width="400"/>
</div>

# Backend API (FastAPI)

Backend API service for the **No Emo Vibe** mood-diary application, powered by **FastAPI** and **PostgreSQL**.


##  Quick Start (using `uv`)

### 1 — Create environment file

Create a `.env` file in the project root with your database credentials:

```env
POSTGRES_USER=user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=no-emo-vibe

DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
```

### 2 — Install dependencies & start

```bash
cd api
uv sync           # install Python dependencies
uv run python run.py  # start the API on port 8000
```

Alternatively, run **Uvicorn** directly:

```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```