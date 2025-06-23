# No Emo Vibe API Deployment Guide

## Deployment Options

### Development Environment (Docker Compose)

```bash
# Start all services
docker compose up -d

# Check service status
docker compose ps

# Follow logs (API service)
docker compose logs -f api
```

**Service Endpoints (default):**

- API: http://140.113.26.164:8000  
- API Docs (Swagger): http://140.113.26.164:8000/docs  
- Database: 140.113.26.164:5433

---

## 🔧 Key Configuration Changes

### Database Connection

| Context | Connection String |
|---------|-------------------|
| Previous (direct) | `postgresql://[your_db_user]:[your_secure_password]@140.113.26.164:5433/no-emo-vibe` |
| Docker Compose | `postgresql://[your_db_user]:[your_secure_password]@db:5432/no-emo-vibe` |

### Network Topology

```
┌───────────────────┐        ┌─────────────┐       ┌──────────────┐
│ External Access   │        │   FastAPI   │       │  PostgreSQL  │
│   Port: 8000      │  ──►   │   (api)     │  ◄─►  │    (db)      │
└───────────────────┘        │ Port: 8000  │       │ Port: 5432   │
                             └─────────────┘       └──────────────┘
```

### Environment Variables (.env)

All sensitive credentials are stored in a project-root `.env` file which Docker Compose loads automatically. Example:

```env
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=no-emo-vibe

DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
```

These variables are referenced in `docker-compose.yml` via `${VAR}` placeholders and read by the API at runtime via `python-dotenv`. The `.env` file is included in `.gitignore` so it is never committed to version control.

---

## 🛠️ Common Commands

### Service Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Re-build API service
docker compose build api

# Restart API service
docker compose restart api

# Tail logs
docker compose logs -f api
docker compose logs -f db
```

### Database Management

```bash
# Enter psql shell inside the container
docker compose exec db psql -U user -d no-emo-vibe

# Backup database
docker compose exec db pg_dump -U user no-emo-vibe > backup.sql

# Restore database
cat backup.sql | docker compose exec -T db psql -U user -d no-emo-vibe
```

---

## Troubleshooting

1. **Port Conflicts**

   ```bash
   # Check which process is using the port
   lsof -i :8000
   lsof -i :5433

   # Change the host port mapping in docker-compose.yml
   ports:
     - "8001:8000"   # Map host 8001 → container 8000
   ```

2. **Container Fails to Start**

   ```bash
   # View detailed error logs
docker compose logs api
docker compose logs db

   # Re-build from scratch
docker compose build --no-cache api
   ```

---

##  Monitoring & Health Checks

- Database readiness is automatically checked via `pg_isready` in the `db` service health-check.
- Swagger UI is available at `http://140.113.26.164:8000/docs`.

Real-time log streaming:

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api
```

---

## 🌟 Best Practices

1. **Isolated Docker Network** – internal service communication happens on a private Docker bridge network.
2. **Health Checks** – the API waits for the database to become healthy before starting.
3. **Data Persistence** – database files are stored in a named Docker volume.
4. **Environment Separation** – keep distinct compose files for dev / staging / production.
5. **Automatic Restarts** – services are configured to restart on failure.

---

## 📦 Volume Management

The database data is stored in the named volume `no_emo_db`, which Docker Compose prefixes with the project name. By default, the actual volume name becomes **`no-emo-vibe_no_emo_db`**.

To inspect which containers (if any) are using a volume:

```bash
sudo docker volume inspect no-emo-vibe_no_emo_db
```

Remove unused volumes

```bash
sudo docker volume rm VOLUME_NAME
```

