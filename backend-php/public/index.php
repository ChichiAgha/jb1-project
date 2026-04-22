<?php

declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function jsonResponse(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_PRETTY_PRINT);
    exit;
}

function db(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $host = getenv('DB_HOST') ?: 'postgres';
    $port = getenv('DB_PORT') ?: '5432';
    $database = getenv('DB_DATABASE') ?: 'taskapp';
    $username = getenv('DB_USERNAME') ?: 'taskuser';
    $password = getenv('DB_PASSWORD') ?: 'taskpass';

    $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', $host, $port, $database);
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    return $pdo;
}

function requestBody(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || $raw === '') {
        return [];
    }

    $data = json_decode($raw, true);
    if (!is_array($data)) {
        jsonResponse(400, [
            'status' => 'error',
            'message' => 'Invalid JSON payload',
        ]);
    }

    return $data;
}

function listTasks(PDO $pdo): void
{
    $statement = $pdo->query('SELECT id, title, description, is_done, created_at FROM tasks ORDER BY id DESC');
    $tasks = array_map(static function (array $task): array {
        $task['is_done'] = (bool) $task['is_done'];
        return $task;
    }, $statement->fetchAll());

    jsonResponse(200, [
        'status' => 'ok',
        'tasks' => $tasks,
    ]);
}

function createTask(PDO $pdo): void
{
    $payload = requestBody();
    $title = trim((string) ($payload['title'] ?? ''));
    $description = trim((string) ($payload['description'] ?? ''));

    if ($title === '') {
        jsonResponse(422, [
            'status' => 'error',
            'message' => 'Title is required',
        ]);
    }

    $statement = $pdo->prepare(
        'INSERT INTO tasks (title, description) VALUES (:title, :description) RETURNING id, title, description, is_done, created_at'
    );
    $statement->execute([
        'title' => $title,
        'description' => $description === '' ? null : $description,
    ]);

    $task = $statement->fetch();
    $task['is_done'] = (bool) $task['is_done'];

    jsonResponse(201, [
        'status' => 'ok',
        'task' => $task,
    ]);
}

function updateTask(PDO $pdo, int $id): void
{
    $payload = requestBody();
    $statement = $pdo->prepare(
        'UPDATE tasks
         SET title = COALESCE(:title, title),
             description = COALESCE(:description, description),
             is_done = COALESCE(:is_done, is_done)
         WHERE id = :id
         RETURNING id, title, description, is_done, created_at'
    );
    $statement->bindValue('id', $id, PDO::PARAM_INT);
    $statement->bindValue('title', array_key_exists('title', $payload) ? trim((string) $payload['title']) : null);
    $statement->bindValue('description', array_key_exists('description', $payload) ? trim((string) $payload['description']) : null);
    $statement->bindValue('is_done', array_key_exists('is_done', $payload) ? (bool) $payload['is_done'] : null, PDO::PARAM_BOOL);
    $statement->execute();

    $task = $statement->fetch();
    if ($task === false) {
        jsonResponse(404, [
            'status' => 'error',
            'message' => 'Task not found',
        ]);
    }

    $task['is_done'] = (bool) $task['is_done'];

    jsonResponse(200, [
        'status' => 'ok',
        'task' => $task,
    ]);
}

function deleteTask(PDO $pdo, int $id): void
{
    $statement = $pdo->prepare('DELETE FROM tasks WHERE id = :id');
    $statement->execute([
        'id' => $id,
    ]);

    if ($statement->rowCount() === 0) {
        jsonResponse(404, [
            'status' => 'error',
            'message' => 'Task not found',
        ]);
    }

    jsonResponse(200, [
        'status' => 'ok',
        'message' => 'Task deleted',
    ]);
}

try {
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $pdo = db();

    if ($path === '/api/health' && $method === 'GET') {
        $result = $pdo->query('SELECT 1')->fetchColumn();
        jsonResponse(200, [
            'status' => 'ok',
            'database' => $result == 1 ? 'connected' : 'unexpected-response',
        ]);
    }

    if ($path === '/api/tasks' && $method === 'GET') {
        listTasks($pdo);
    }

    if ($path === '/api/tasks' && $method === 'POST') {
        createTask($pdo);
    }

    if (preg_match('#^/api/tasks/(\d+)$#', $path, $matches) === 1) {
        $id = (int) $matches[1];

        if ($method === 'PATCH') {
            updateTask($pdo, $id);
        }

        if ($method === 'DELETE') {
            deleteTask($pdo, $id);
        }
    }

    jsonResponse(404, [
        'status' => 'error',
        'message' => 'Route not found',
    ]);
} catch (Throwable $exception) {
    jsonResponse(500, [
        'status' => 'error',
        'message' => $exception->getMessage(),
    ]);
}
