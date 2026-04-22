<?php

declare(strict_types=1);

function migrationPdo(): PDO
{
    $host = getenv('DB_HOST') ?: 'postgres';
    $port = getenv('DB_PORT') ?: '5432';
    $database = getenv('DB_DATABASE') ?: 'taskapp';
    $username = getenv('DB_USERNAME') ?: 'taskuser';
    $password = getenv('DB_PASSWORD') ?: 'taskpass';

    $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', $host, $port, $database);

    return new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

$pdo = migrationPdo();
$pdo->exec(
    'CREATE TABLE IF NOT EXISTS schema_migrations (
        migration VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )'
);

$migrationFiles = glob(__DIR__ . '/../migrations/*.sql') ?: [];
sort($migrationFiles);

foreach ($migrationFiles as $file) {
    $migration = basename($file);
    $statement = $pdo->prepare('SELECT 1 FROM schema_migrations WHERE migration = :migration');
    $statement->execute(['migration' => $migration]);

    if ($statement->fetchColumn()) {
        echo sprintf("Skipping migration: %s\n", $migration);
        continue;
    }

    $sql = file_get_contents($file);
    if ($sql === false) {
        throw new RuntimeException(sprintf('Unable to read migration: %s', $migration));
    }

    $pdo->beginTransaction();
    try {
        $pdo->exec($sql);

        $insert = $pdo->prepare('INSERT INTO schema_migrations (migration) VALUES (:migration)');
        $insert->execute(['migration' => $migration]);

        $pdo->commit();
        echo sprintf("Applied migration: %s\n", $migration);
    } catch (Throwable $exception) {
        $pdo->rollBack();
        throw $exception;
    }
}

echo "Migrations complete.\n";
