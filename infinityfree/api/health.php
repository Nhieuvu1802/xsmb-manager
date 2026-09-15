<?php
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php'; cors(); rate_limit('read', 120, 60);
$database = 'offline'; $lastSync = null; $lastData = null;
try {
    $pdo = db(); $pdo->query('SELECT 1'); $database = 'online';
    $lastSync = $pdo->query("SELECT MAX(created_at) FROM sync_logs WHERE status IN ('success','partial')")->fetchColumn() ?: null;
    $lastData = $pdo->query('SELECT MAX(draw_date) FROM lottery_draws')->fetchColumn() ?: null;
} catch (Throwable $e) { error_log('health database check failed: ' . $e->getMessage()); }
json_response(['status' => 'online', 'database' => $database, 'last_sync' => $lastSync, 'last_data' => $lastData, 'version' => config()['APP_VERSION'] ?? '1.0.0', 'timestamp' => gmdate('c')], $database === 'online' ? 200 : 503);
