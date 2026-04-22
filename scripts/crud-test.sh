#!/bin/sh
set -eu

API_URL="${API_URL:-http://localhost:5173/api}"
TITLE="CRUD test task $$"
DESCRIPTION="Created by scripts/crud-test.sh"

TMP_CREATE="$(mktemp)"
TMP_UPDATE="$(mktemp)"
TMP_LIST="$(mktemp)"
TMP_DELETE="$(mktemp)"
trap 'rm -f "$TMP_CREATE" "$TMP_UPDATE" "$TMP_LIST" "$TMP_DELETE"' EXIT

echo "Creating task through ${API_URL}/tasks"
curl -fsS \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"${TITLE}\",\"description\":\"${DESCRIPTION}\"}" \
  "${API_URL}/tasks" > "$TMP_CREATE"

TASK_ID="$(sed -n 's/.*"id": \([0-9][0-9]*\).*/\1/p' "$TMP_CREATE" | head -n 1)"

if [ -z "$TASK_ID" ]; then
  echo "Failed to read created task id."
  cat "$TMP_CREATE"
  exit 1
fi

grep -q "\"title\": \"${TITLE}\"" "$TMP_CREATE"

echo "Listing tasks and checking created task ${TASK_ID}"
curl -fsS "${API_URL}/tasks" > "$TMP_LIST"
grep -q "\"id\": ${TASK_ID}" "$TMP_LIST"
grep -q "\"title\": \"${TITLE}\"" "$TMP_LIST"

echo "Marking task ${TASK_ID} as done"
curl -fsS \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"is_done":true}' \
  "${API_URL}/tasks/${TASK_ID}" > "$TMP_UPDATE"
grep -q '"is_done": true' "$TMP_UPDATE"

echo "Deleting task ${TASK_ID}"
curl -fsS \
  -X DELETE \
  "${API_URL}/tasks/${TASK_ID}" > "$TMP_DELETE"
grep -q '"Task deleted"' "$TMP_DELETE"

echo "Checking deleted task returns 404"
STATUS_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "${API_URL}/tasks/${TASK_ID}")"
if [ "$STATUS_CODE" != "404" ]; then
  echo "Expected 404 for deleted task, got ${STATUS_CODE}"
  exit 1
fi

echo "CRUD tests passed."
