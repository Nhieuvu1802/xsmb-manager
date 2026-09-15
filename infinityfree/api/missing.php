<?php
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') json_response(['success'=>false,'error'=>'Method not allowed'],405);
require_sync_auth(); rate_limit('write',20,60);
try {
    $body=json_decode(file_get_contents('php://input'),true,32,JSON_THROW_ON_ERROR);
    $dates=$body['dates']??[]; $region=strtoupper((string)($body['region']??'')); $province=clean_text($body['province']??'',100);
    if(!is_array($dates)||count($dates)>366||!in_array($region,['XSMB','XSMT','XSMN'],true)) throw new InvalidArgumentException('Invalid request.');
    $valid=array_values(array_filter($dates,fn($date)=>is_string($date)&&preg_match('/^\d{4}-\d{2}-\d{2}$/',$date)));
    if(!$valid) json_response(['success'=>true,'missing'=>[]]);
    $marks=implode(',',array_fill(0,count($valid),'?')); $stmt=db()->prepare("SELECT draw_date FROM lottery_draws WHERE region=? AND province=? AND draw_date IN ($marks)");
    $stmt->execute(array_merge([$region,$province],$valid)); $present=$stmt->fetchAll(PDO::FETCH_COLUMN);
    json_response(['success'=>true,'missing'=>array_values(array_diff($valid,$present)),'checked'=>count($valid)]);
} catch(Throwable $e){ json_response(['success'=>false,'error'=>$e instanceof InvalidArgumentException?$e->getMessage():'Service unavailable'], $e instanceof InvalidArgumentException?422:503); }
