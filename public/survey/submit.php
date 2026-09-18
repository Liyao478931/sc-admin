<?php
/**
 * 员工食堂满意度问卷 - 提交接口（匿名）
 * 存储：data/surveys.jsonl（每行一条记录，含提交时间）
 */
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');

$dataDir = __DIR__ . '/data';
if (!is_dir($dataDir)) @mkdir($dataDir, 0755, true);

// 仅接受 POST JSON
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    echo json_encode(['ok' => false, 'msg' => '请求方式错误'], JSON_UNESCAPED_UNICODE);
    exit;
}
$raw = file_get_contents('php://input');
if ($raw === false || strlen($raw) > 256 * 1024) {
    echo json_encode(['ok' => false, 'msg' => '请求体过大'], JSON_UNESCAPED_UNICODE);
    exit;
}
$d = json_decode($raw, true);
if (!is_array($d)) {
    echo json_encode(['ok' => false, 'msg' => '数据格式错误'], JSON_UNESCAPED_UNICODE);
    exit;
}

/* ---------- 维度定义（服务端重算总分，防伪造） ---------- */
$scoreDims = [
    ['菜品品质', [6,6,6,6,6]],
    ['卫生状况', [5,5,5,5,5]],
    ['用餐环境与设施', [4,4,4,4,4]],
    ['服务与供应保障', [5,5,5]],
    ['性价比', [5,5]],
];

/* ---------- 基础校验 ---------- */
$post = $d['post'] ?? '';
$dineFreq = $d['dine_freq'] ?? '';
$dineTime = $d['dine_time'] ?? [];
$eatOut   = $d['eat_out'] ?? '';
if ($post === '' || $dineFreq === '' || !is_array($dineTime) || count($dineTime) === 0 || $eatOut === '') {
    echo json_encode(['ok' => false, 'msg' => '第一部分必填项未完成'], JSON_UNESCAPED_UNICODE);
    exit;
}
foreach (['best3','worst3'] as $k) {
    $v = $d[$k] ?? [];
    if (!is_array($v) || count($v) === 0) {
        echo json_encode(['ok' => false, 'msg' => '第6/7题请至少选择1项'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if (count($v) > 3) {
        echo json_encode(['ok' => false, 'msg' => '第6/7题最多选择3项'], JSON_UNESCAPED_UNICODE);
        exit;
    }
}

/* ---------- 校验并重算评分（每项 0~分项分值） ---------- */
$scores = $d['scores'] ?? [];
if (!is_array($scores)) {
    echo json_encode(['ok' => false, 'msg' => '评分数据错误'], JSON_UNESCAPED_UNICODE);
    exit;
}
$expectCount = 0; foreach ($scoreDims as $dim) { $expectCount += count($dim[1]); }
if (count($scores) !== $expectCount) {
    echo json_encode(['ok' => false, 'msg' => '评分项不完整'], JSON_UNESCAPED_UNICODE);
    exit;
}
$dimTotal = []; $total = 0; $idx = 0; $dimIdxMap = [];
foreach ($scoreDims as $di => $dim) { foreach ($dim[1] as $max) { $dimIdxMap[$idx] = [$di, $max]; $idx++; } }
$norm = [];
foreach ($scores as $i => $s) {
    if (!is_array($s) || !isset($dimIdxMap[$i])) {
        echo json_encode(['ok' => false, 'msg' => '评分数据异常'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    [$di, $max] = $dimIdxMap[$i];
    $v = (int)($s['val'] ?? -1);
    if ($v < 0 || $v > $max) {
        echo json_encode(['ok' => false, 'msg' => '评分超出范围'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $norm[] = ['dim' => $di, 'val' => $v];
    $total += $v;
    $dimTotal[$di] = ($dimTotal[$di] ?? 0) + $v;
}
$grade = '超差';
if ($total >= 90) $grade = '好';
elseif ($total >= 75) $grade = '较好';
elseif ($total >= 60) $grade = '一般';
elseif ($total >= 40) $grade = '较差';

/* ---------- 存储（JSONL 追加，加锁防并发） ---------- */
$file = $dataDir . '/surveys.jsonl';
$record = [
    'ts'       => date('Y-m-d H:i:s'),
    'dept'     => mb_substr((string)($d['dept'] ?? ''), 0, 100),
    'post'     => mb_substr((string)$post, 0, 30),
    'dine_freq'=> mb_substr((string)$dineFreq, 0, 60),
    'dine_time'=> array_slice(array_map(fn($x) => mb_substr((string)$x, 0, 10), $dineTime), 0, 3),
    'eat_out'  => mb_substr((string)$eatOut, 0, 60),
    'scores'   => $norm,
    'dim_total'=> $dimTotal,
    'total'    => $total,
    'grade'    => $grade,
    'best3'    => array_map(fn($x) => mb_substr((string)$x, 0, 30), $d['best3'] ?? []),
    'worst3'   => array_map(fn($x) => mb_substr((string)$x, 0, 30), $d['worst3'] ?? []),
    'new_cat'  => array_map(fn($x) => mb_substr((string)$x, 0, 30), $d['new_cat'] ?? []),
    'empty_dish' => mb_substr((string)($d['empty_dish'] ?? ''), 0, 20),
    'waste'    => mb_substr((string)($d['waste'] ?? ''), 0, 40),
    'diet'     => mb_substr((string)($d['diet'] ?? ''), 0, 100),
    'suggestion' => mb_substr((string)($d['suggestion'] ?? ''), 0, 2000),
    'other'    => mb_substr((string)($d['other'] ?? ''), 0, 2000),
];

// 简单防滥用：同一 IP 5 秒内仅 1 次
$ip = (string)($_SERVER['REMOTE_ADDR'] ?? '');
$lockFile = $dataDir . '/ratelimit_' . md5($ip);
if (is_file($lockFile) && time() - (int)filemtime($lockFile) < 5) {
    echo json_encode(['ok' => false, 'msg' => '提交过于频繁，请稍后再试'], JSON_UNESCAPED_UNICODE);
    exit;
}
@touch($lockFile);

$fp = @fopen($file, 'a');
if (!$fp) {
    echo json_encode(['ok' => false, 'msg' => '服务器存储不可用'], JSON_UNESCAPED_UNICODE);
    exit;
}
if (!flock($fp, LOCK_EX)) { fclose($fp); echo json_encode(['ok' => false, 'msg' => '服务器繁忙'], JSON_UNESCAPED_UNICODE); exit; }
fwrite($fp, json_encode($record, JSON_UNESCAPED_UNICODE) . "\n");
flock($fp, LOCK_UN);
fclose($fp);

echo json_encode(['ok' => true, 'msg' => '提交成功'], JSON_UNESCAPED_UNICODE);
