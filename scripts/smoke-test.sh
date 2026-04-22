#!/bin/sh
set -eu

FRONTEND_URL="${FRONTEND_URL:-http://localhost:5173}"
BACKEND_URL="${BACKEND_URL:-http://localhost:8000}"

echo "Checking frontend: ${FRONTEND_URL}"
curl -fsS "${FRONTEND_URL}" > /dev/null

echo "Checking frontend API proxy: ${FRONTEND_URL}/api/health"
curl -fsS "${FRONTEND_URL}/api/health" | grep -q '"database": "connected"'

echo "Checking backend health: ${BACKEND_URL}/api/health"
curl -fsS "${BACKEND_URL}/api/health" | grep -q '"database": "connected"'

echo "Checking tasks endpoint: ${FRONTEND_URL}/api/tasks"
curl -fsS "${FRONTEND_URL}/api/tasks" | grep -q '"tasks"'

echo "Smoke tests passed."
