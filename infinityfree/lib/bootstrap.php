<?php
declare(strict_types=1);

function config(): array {
    static $value;
    if ($value !== null) return $value;
    $path = __DIR__ . '/../config/config.php';
    if (!is_file($path)) throw new RuntimeException('Server config is missing.');
    $value = require $path;
    return $value;
}

function db(): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $c = config();
    $pdo = new PDO(sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $c['DB_HOST'], $c['DB_NAME']), $c['DB_USER'], $c['DB_PASS'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES => false]);
    return $pdo;
}

function json_response(array $body, int $status = 200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function cors(): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $allowed = array_filter(array_map('trim', explode(',', (string)(config()['ALLOWED_ORIGINS'] ?? ''))));
    if ($origin !== '' && in_array($origin, $allowed, true)) { header('Access-Control-Allow-Origin: ' . $origin); header('Vary: Origin'); }
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') exit;
}

function bearer_token(): string {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    return preg_match('/^Bearer\s+(.+)$/i', $header, $match) ? trim($match[1]) : '';
}

function require_sync_auth(): void {
    $expected = (string)(config()['SYNC_API_KEY'] ?? '');
    if ($expected === '' || !hash_equals($expected, bearer_token())) json_response(['success' => false, 'error' => 'Unauthorized'], 401);
}

function clean_text(mixed $value, int $max = 255): string {
    $text = trim(strip_tags((string)$value));
    if ($text === '' || preg_match('/[<>]/', $text)) throw new InvalidArgumentException('Invalid text value.');
    return mb_substr($text, 0, $max);
}

function canonical_draw(array $input): array {
    $region = strtoupper(clean_text($input['region'] ?? '', 4));
    if (!in_array($region, ['XSMB', 'XSMT', 'XSMN'], true)) throw new InvalidArgumentException('Invalid region.');
    $province = clean_text($input['province'] ?? '', 100);
    $date = (string)($input['draw_date'] ?? '');
    $parsed = DateTimeImmutable::createFromFormat('!Y-m-d', $date);
    if (!$parsed || $parsed->format('Y-m-d') !== $date) throw new InvalidArgumentException('Invalid draw_date.');
    $source = clean_text($input['source'] ?? '', 255);
    $fetchedAt = (string)($input['fetched_at'] ?? '');
    if (strtotime($fetchedAt) === false) throw new InvalidArgumentException('Invalid fetched_at.');
    if (!isset($input['results']) || !is_array($input['results']) || count($input['results']) < 1 || count($input['results']) > 12) throw new InvalidArgumentException('Invalid results.');
    $results = [];
    foreach ($input['results'] as $result) {
        $prize = strtoupper(clean_text($result['prize'] ?? '', 16));
        if (!preg_match('/^(DB|G[1-8]|GDB|SPECIAL)$/', $prize)) throw new InvalidArgumentException('Invalid prize.');
        $numbers = $result['numbers'] ?? null;
        if (!is_array($numbers) || !$numbers || count($numbers) > 30) throw new InvalidArgumentException('Invalid prize numbers.');
        foreach ($numbers as $number) if (!is_string($number) || !preg_match('/^\d{2,6}$/', $number)) throw new InvalidArgumentException('Invalid lottery number.');
        $results[] = ['prize' => $prize, 'numbers' => array_values($numbers)];
    }
    usort($results, fn($a, $b) => strcmp($a['prize'], $b['prize']));
    $checksum = hash('sha256', json_encode(['region' => $region, 'province' => strtolower($province), 'draw_date' => $date, 'results' => $results], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    if (isset($input['checksum']) && !hash_equals($checksum, (string)$input['checksum'])) throw new InvalidArgumentException('Checksum mismatch.');
    return compact('region', 'province', 'date', 'results', 'source', 'fetchedAt', 'checksum');
}

function rate_limit(string $bucket, int $limit, int $windowSeconds): void {
    $key = hash('sha256', $bucket . '|' . ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
    $pdo = db();
    $stmt = $pdo->prepare('INSERT INTO rate_limits (rate_key,hits,window_started) VALUES (?,1,NOW()) ON DUPLICATE KEY UPDATE hits=IF(window_started<DATE_SUB(NOW(),INTERVAL ? SECOND),1,hits+1),window_started=IF(window_started<DATE_SUB(NOW(),INTERVAL ? SECOND),NOW(),window_started)');
    $stmt->execute([$key, $windowSeconds, $windowSeconds]);
    $check = $pdo->prepare('SELECT hits FROM rate_limits WHERE rate_key=?'); $check->execute([$key]);
    if ((int)$check->fetchColumn() > $limit) json_response(['success' => false, 'error' => 'Rate limit exceeded'], 429);
}

function log_event(string $requestId, string $source, string $operation, string $status, int $duration, ?string $details = null): void {
    db()->prepare('INSERT INTO sync_logs(request_id,source,operation,status,duration_ms,details) VALUES (?,?,?,?,?,?)')->execute([$requestId, mb_substr($source,0,100), $operation, $status, $duration, $details ? mb_substr($details,0,500) : null]);
    if (random_int(1, 100) === 1) db()->exec('DELETE FROM sync_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)');
}
