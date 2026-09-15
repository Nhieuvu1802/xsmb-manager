<?php
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') json_response(['success' => false, 'error' => 'Method not allowed'], 405);
require_sync_auth(); rate_limit('sync', 30, 60);
$started = microtime(true); $requestId = bin2hex(random_bytes(8));
try {
    $body = json_decode(file_get_contents('php://input'), true, 64, JSON_THROW_ON_ERROR);
    $items = isset($body['draws']) ? $body['draws'] : [$body];
    $max = (int)(config()['MAX_BATCH_SIZE'] ?? 50);
    if (!is_array($items) || !$items || count($items) > $max) throw new InvalidArgumentException("Batch must contain 1-$max draws.");
    $draws = array_map('canonical_draw', $items);
    $pdo = db(); $pdo->beginTransaction(); $inserted = 0; $updated = 0; $unchanged = 0; $conflicts = 0;
    foreach ($draws as $draw) {
        $find = $pdo->prepare('SELECT id,checksum FROM lottery_draws WHERE region=? AND province=? AND draw_date=? FOR UPDATE');
        $find->execute([$draw['region'], $draw['province'], $draw['date']]); $existing = $find->fetch();
        if ($existing && hash_equals($existing['checksum'], $draw['checksum'])) { $unchanged++; continue; }
        if ($existing) {
            $conflicts++;
            log_event($requestId, $draw['source'], 'sync', 'conflict', (int)((microtime(true)-$started)*1000), $draw['region'].'/'.$draw['province'].'/'.$draw['date']);
            continue;
        }
        $stmt = $pdo->prepare('INSERT INTO lottery_draws(region,province,draw_date,source,fetched_at,checksum) VALUES (?,?,?,?,?,?)');
        $stmt->execute([$draw['region'],$draw['province'],$draw['date'],$draw['source'],date('Y-m-d H:i:s',strtotime($draw['fetchedAt'])),$draw['checksum']]);
        $drawId = (int)$pdo->lastInsertId(); $position = [];
        $resultStmt = $pdo->prepare('INSERT INTO lottery_results(draw_id,prize,position,number) VALUES (?,?,?,?)');
        foreach ($draw['results'] as $result) foreach ($result['numbers'] as $number) { $position[$result['prize']] = ($position[$result['prize']] ?? 0) + 1; $resultStmt->execute([$drawId,$result['prize'],$position[$result['prize']],$number]); }
        $inserted++;
    }
    $pdo->commit();
    log_event($requestId, 'vercel', 'sync', $conflicts ? 'partial' : 'success', (int)((microtime(true)-$started)*1000), "inserted=$inserted unchanged=$unchanged conflicts=$conflicts");
    json_response(compact('inserted','updated','unchanged','conflicts') + ['success' => $conflicts === 0, 'request_id' => $requestId], $conflicts ? 409 : 200);
} catch (JsonException|InvalidArgumentException $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    json_response(['success' => false, 'error' => $e->getMessage(), 'request_id' => $requestId], 422);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    error_log("sync request $requestId failed: " . $e->getMessage());
    json_response(['success' => false, 'error' => 'Service unavailable', 'request_id' => $requestId], 503);
}
