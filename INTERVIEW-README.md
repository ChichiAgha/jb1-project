# TaskApp Interview README

This project is a small full-stack task manager built to demonstrate how a React frontend, PHP backend API, and PostgreSQL database can be containerized and run together with Docker Compose.

## Architecture

```text
Browser
  |
  v
Nginx frontend container
  |
  | serves React/Vite static files
  | proxies /api requests
  v
PHP backend API container
  |
  v
PostgreSQL database container
```

Services:

- `frontend`: React app built with Vite, compiled into static files, served by Nginx.
- `backend`: Plain PHP API using PDO to connect to PostgreSQL.
- `postgres`: PostgreSQL database used to persist tasks.

## What This Showcases

This project shows that I can:

- Build and containerize a frontend application.
- Use a multi-stage Docker build for production-style frontend delivery.
- Serve a compiled React app with Nginx instead of running a development server.
- Proxy frontend `/api` requests to a backend service through Nginx.
- Containerize a PHP backend with required PostgreSQL extensions.
- Connect backend and database services through Docker networking.
- Add Docker Compose healthchecks and startup dependencies.
- Keep the database internal to the Docker network instead of exposing it publicly.
- Add smoke tests to verify the app after deployment.
- Run database migrations before the backend starts.
- Use GitHub Actions for CI checks.
- Use GitHub Actions for CD image publishing.

## Frontend Production Build

The frontend uses a multi-stage Dockerfile:

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

The first stage uses Node to install dependencies and build the Vite app.

The second stage uses Nginx to serve only the final static files. This is better than running `npm run dev` in production because the runtime image is smaller, simpler, and does not include the full Node development environment.

Vite outputs production files to:

```text
dist/
```

So the Dockerfile copies:

```dockerfile
COPY --from=build /app/dist /usr/share/nginx/html
```

## Why `npm ci` Is Used

The frontend Dockerfile uses:

```dockerfile
RUN npm ci
```

instead of:

```dockerfile
RUN npm install
```

`npm ci` installs dependencies exactly from `package-lock.json`. That makes Docker builds more predictable and repeatable.

Interview explanation:

> I use `npm ci` in the Docker build because it installs exactly from the lockfile. That means the image build is reproducible and does not accidentally update dependency versions. I still use `npm install` locally when I intentionally add or update packages.

## Nginx Configuration

Nginx serves the built frontend and proxies API traffic:

```nginx
location /api/ {
    proxy_pass http://backend:8000;
}

location / {
    try_files $uri $uri/ /index.html;
}
```

This means:

- Browser requests to `/` return the React app.
- Browser requests to `/api/health` or `/api/tasks` are forwarded to the PHP backend.
- React can use relative API paths like `/api/tasks`.

The Nginx config also includes:

- gzip compression
- cache headers for static assets
- no-cache headers for the app shell
- no-store headers for API responses
- basic security headers

## Backend API

The backend is a plain PHP API located at:

```text
backend-php/public/index.php
```

It exposes:

```text
GET    /api/health
GET    /api/tasks
POST   /api/tasks
PATCH  /api/tasks/:id
DELETE /api/tasks/:id
```

The backend connects to PostgreSQL using environment variables passed by Docker Compose.

Local environment templates are available at:

```text
./.env.example
backend-php/.env.example
```

The committed templates show the expected variables, while local `.env` files are ignored so secrets do not need to be committed.

Database schema is handled through migration files:

```text
backend-php/migrations/
```

The backend container runs migrations before starting the PHP server.

Interview explanation:

> The backend is intentionally simple. I used plain PHP and PDO so the project clearly shows the request flow, database connection, routing, migrations, validation, and JSON responses without hiding those details behind a framework.

## Docker Compose Setup

Docker Compose runs three services:

```text
frontend
backend
postgres
```

The frontend is exposed on:

```text
http://localhost:5173
```

The backend is exposed on:

```text
http://localhost:8000
```

PostgreSQL is not exposed to the host. It is only available inside Docker as:

```text
postgres:5432
```

Interview explanation:

> I kept PostgreSQL internal to the Docker network because the frontend and backend are the only services that need to communicate with it. This reduces unnecessary exposure.

## Healthchecks

The Compose file includes healthchecks for all services:

- PostgreSQL uses `pg_isready`.
- Backend checks `/api/health`.
- Frontend checks that Nginx responds.

The startup order uses health conditions:

```text
postgres healthy -> backend starts
backend healthy  -> frontend starts
```

Interview explanation:

> Instead of only starting containers in order, I added healthchecks so services wait for actual readiness. This avoids cases where the backend starts before the database is ready, or the frontend starts before the API is available.

## Smoke Test

The project includes:

```text
scripts/smoke-test.sh
```

It checks:

- the frontend loads
- the frontend Nginx API proxy works
- the backend health endpoint works
- the tasks endpoint works

The project also includes:

```text
scripts/crud-test.sh
```

It tests the backend CRUD flow through the API:

- create task
- list tasks
- mark task as done
- delete task
- verify deleted task returns `404`

Run the smoke test with:

```bash
sh scripts/smoke-test.sh
```

Run the CRUD test with:

```bash
sh scripts/crud-test.sh
```

Expected output:

```text
Checking frontend: http://localhost:5173
Checking frontend API proxy: http://localhost:5173/api/health
Checking backend health: http://localhost:8000/api/health
Checking tasks endpoint: http://localhost:5173/api/tasks
Smoke tests passed.
```

Interview explanation:

> I added a smoke test so I can quickly prove the stack is working after a build or deployment. It checks the most important paths without needing a full test suite.

## CI Pipeline

The project includes a GitHub Actions workflow at:

```text
.github/workflows/ci.yml
```

The CI pipeline runs on pushes to `main` and on pull requests.

It performs:

- Docker Compose config validation
- full Docker build
- container startup
- smoke tests
- backend CRUD tests
- logs on failure
- cleanup after the job

Interview explanation:

> I added CI so every push validates the Docker Compose setup, builds the stack, starts the services, and runs smoke and CRUD tests. That gives quick feedback before code is merged or demoed.

## CD Pipeline

The project includes a GitHub Actions CD workflow at:

```text
.github/workflows/cd.yml
```

The CD pipeline runs on:

- pushes to `main`
- version tags like `v1.0.0`
- manual workflow dispatch

It performs:

- Docker Compose config validation
- full Docker build
- container startup with healthchecks
- smoke tests
- backend CRUD tests
- Docker Buildx setup
- GitHub Container Registry login
- frontend image build and push
- backend image build and push

Images are published to GitHub Container Registry:

```text
ghcr.io/<github-owner>/taskapp-frontend:<commit-sha>
ghcr.io/<github-owner>/taskapp-frontend:latest
ghcr.io/<github-owner>/taskapp-backend:<commit-sha>
ghcr.io/<github-owner>/taskapp-backend:latest
```

This is continuous delivery: after the app passes checks, it produces versioned Docker images that are ready to deploy.

A future deployment target could extend this workflow to:

1. Pull the published images onto a server.
2. Restart the production stack.
3. Run post-deployment smoke tests.
4. Roll back or fail the deployment if post-deployment checks fail.

Interview explanation:

> CI validates every change. CD runs the same checks, then builds and publishes versioned frontend and backend Docker images to GitHub Container Registry. That means a stable commit produces deployable artifacts automatically.

## Implementation Steps

These are the main steps used to move the app from a development setup to a more production-style setup.

1. Started with a working React, PHP, and PostgreSQL app.

2. Added a frontend Dockerfile with a build stage:

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
```

3. Added an Nginx runtime stage:

```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

4. Added a frontend `build` script:

```json
"scripts": {
  "dev": "vite",
  "build": "vite build"
}
```

5. Updated Docker Compose so the frontend builds from its Dockerfile:

```yaml
frontend:
  build:
    context: ./frontend-react
    dockerfile: Dockerfile
  ports:
    - "5173:80"
```

6. Added Nginx proxying so `/api` requests go to the backend:

```nginx
location /api/ {
    proxy_pass http://backend:8000;
}
```

7. Removed the public PostgreSQL port mapping:

```yaml
postgres:
  image: postgres:15
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

8. Added healthchecks and service readiness dependencies.

9. Added a `.dockerignore` file to avoid copying `node_modules` and `dist` into the Docker build context.

10. Added migration files and a migration runner so schema changes happen before the backend starts.

11. Added a smoke test script to verify the app.

12. Added a backend CRUD test script to verify task create, list, update, delete, and 404 behavior.

13. Added a GitHub Actions CI workflow to build and test the stack automatically.

14. Added a GitHub Actions CD workflow to publish versioned frontend and backend images after tests pass.

15. Rebuilt and verified the stack:

```bash
docker compose up -d --build
docker compose ps
sh scripts/smoke-test.sh
sh scripts/crud-test.sh
```

## How To Run

From the project root:

```bash
docker compose up -d --build
```

Check containers:

```bash
docker compose ps
```

Run smoke tests:

```bash
sh scripts/smoke-test.sh
```

Run backend CRUD tests:

```bash
sh scripts/crud-test.sh
```

Open the app:

```text
http://localhost:5173
```

Check backend health directly:

```text
http://localhost:8000/api/health
```

Check backend health through Nginx:

```text
http://localhost:5173/api/health
```

## Interview Demo Flow

A simple way to present the project:

1. Show the app running at `http://localhost:5173`.
2. Create a task.
3. Mark the task done.
4. Delete the task.
5. Show the API health endpoint at `http://localhost:5173/api/health`.
6. Show `docker compose ps` with all services healthy.
7. Show the frontend Dockerfile and explain the two stages.
8. Show the Nginx config and explain `/api` proxying.
9. Show the smoke test and run it.
10. Show the CRUD test and run it.
11. Show the GitHub Actions CI workflow.
12. Show the GitHub Actions CD workflow and explain the GHCR image tags.

## Strong Interview Summary

You can say:

> This is a Dockerized full-stack task app. The frontend is a React app built with Vite, compiled in a Node build stage, and served by Nginx in a separate runtime image. Nginx also proxies `/api` requests to a PHP backend. The backend uses PDO to connect to PostgreSQL, runs database migrations before startup, and the database is only available inside the Docker network. I added healthchecks, service readiness dependencies, cache headers, gzip, smoke tests, CRUD tests, CI, and CD image publishing to GitHub Container Registry.

## Tradeoffs And Next Improvements

This project is production-style, but there are still improvements I would make for a real deployment:

- Add authentication if tasks are user-specific.
- Use a production-grade PHP runtime setup, such as PHP-FPM behind Nginx.
- Add structured logs and monitoring.
- Use HTTPS and domain-level reverse proxying in a deployed environment.
- Add server deployment steps that pull the published CD images and restart the production stack.

Interview explanation:

> This is a production-style full-stack Docker setup with a Vite frontend served by Nginx, a PHP API, PostgreSQL, migrations, healthchecks, internal service networking, caching headers, smoke tests, CRUD tests, basic secrets cleanup, CI, and CD image publishing, with the next production improvements being server deployment automation, observability, HTTPS, and a production PHP-FPM runtime.
