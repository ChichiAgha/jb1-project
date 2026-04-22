# TaskApp Day 1

Architecture:

Browser -> React Frontend -> PHP Backend API -> PostgreSQL

Features:

- `GET /api/health` checks PostgreSQL connectivity
- `GET /api/tasks` lists tasks
- `POST /api/tasks` creates a task
- `PATCH /api/tasks/:id` toggles task state or updates fields
- `DELETE /api/tasks/:id` removes a task

Run in your WSL shell:

```bash
cd ~/projects/webforx/job-project
docker compose down -v
docker compose up -d --build
curl http://localhost:8000/api/health
sh scripts/smoke-test.sh
sh scripts/crud-test.sh
```

CI/CD:

- CI workflow: `.github/workflows/ci.yml`
- CD workflow: `.github/workflows/cd.yml`
- CD validates the stack, runs smoke and CRUD tests, then publishes frontend and backend images to GitHub Container Registry.

Open:

- Frontend: `http://localhost:5173`
- Backend health: `http://localhost:8000/api/health`

Notes:

- Database schema changes are handled through backend migration files.
- The frontend is built with Vite and served by Nginx.
- Nginx proxies frontend `/api` requests to the PHP backend.
- PostgreSQL is only exposed inside the Docker network, not on the host.
- Local secret files such as `.env` and `backend-php/.env` are ignored. Use `.env.example` files as templates.
- Stable builds are packaged as versioned Docker images by the CD workflow.
