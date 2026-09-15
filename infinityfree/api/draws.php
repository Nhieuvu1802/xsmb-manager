<?php
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php'; cors(); rate_limit('read', 120, 60);
$region = strtoupper((string)($_GET['region'] ?? '')); if ($region && !in_array($region,['XSMB','XSMT','XSMN'],true)) json_response(['error'=>'Invalid region'],422);
$from = (string)($_GET['from'] ?? ''); $to = (string)($_GET['to'] ?? ''); $limit = min(max((int)($_GET['limit'] ?? 50),1),500);
$where = []; $params = []; if ($region) { $where[]='d.region=?'; $params[]=$region; } if (preg_match('/^\d{4}-\d{2}-\d{2}$/',$from)) { $where[]='d.draw_date>=?'; $params[]=$from; } if (preg_match('/^\d{4}-\d{2}-\d{2}$/',$to)) { $where[]='d.draw_date<=?'; $params[]=$to; }
$sql='SELECT d.*,r.prize,r.position,r.number FROM lottery_draws d JOIN lottery_results r ON r.draw_id=d.id'.($where?' WHERE '.implode(' AND ',$where):'').' ORDER BY d.draw_date DESC,d.province,r.prize,r.position LIMIT '.($limit*40);
$stmt=db()->prepare($sql); $stmt->execute($params); $draws=[];
foreach($stmt as $row){ $key=$row['id']; if(!isset($draws[$key])) $draws[$key]=['region'=>$row['region'],'province'=>$row['province'],'draw_date'=>$row['draw_date'],'results'=>[],'source'=>$row['source'],'fetched_at'=>date(DATE_ATOM,strtotime($row['fetched_at'])),'checksum'=>$row['checksum']]; $prize=$row['prize']; if(!isset($draws[$key]['results'][$prize])) $draws[$key]['results'][$prize]=['prize'=>$prize,'numbers'=>[]]; $draws[$key]['results'][$prize]['numbers'][]=$row['number']; }
$output=array_slice(array_values($draws),0,$limit); foreach($output as &$draw) $draw['results']=array_values($draw['results']);
json_response(['success'=>true,'draws'=>$output,'stale'=>false,'timestamp'=>gmdate('c')]);
