<?php
/**
 * 员工食堂满意度问卷 - 后台统计（需密码登录）
 * 访问: /survey/admin.php
 */
declare(strict_types=1);
session_start();

/* ===== 后台登录密码（请自行修改） ===== */
$ADMIN_PASS = 'ghiA1pw0rU';

$dataDir = __DIR__ . '/data';
$dataFile = $dataDir . '/surveys.jsonl';

$SCORE_DIMS = [
    ['菜品品质', 30, ['菜品口味适口度','菜品种类丰富度','食材新鲜程度','热菜保温效果','菜品更新频率']],
    ['卫生状况', 25, ['取餐台清洁','餐具清洁消毒','就餐区域清洁度','后厨卫生可视性','工作人员卫生规范']],
    ['用餐环境与设施', 20, ['座位数量充足性','取餐动线合理性','通风采光温度','餐具取用便利性','就餐秩序与噪音']],
    ['服务与供应保障', 15, ['空盘补餐及时性','服务人员态度响应','开餐时长安排']],
    ['性价比', 10, ['自助餐定价合理性','整体就餐性价比']],
];

/* ---------- 认证 ---------- */
if (($_POST['action'] ?? '') === 'login') {
    if (hash_equals($ADMIN_PASS, (string)($_POST['password'] ?? ''))) {
        $_SESSION['survey_admin'] = true;
        header('Location: admin.php');
        exit;
    }
    $loginErr = '密码错误';
}
if (($_GET['action'] ?? '') === 'logout') { unset($_SESSION['survey_admin']); header('Location: admin.php'); exit; }
$authed = !empty($_SESSION['survey_admin']);

if (!$authed) {
    ?><!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>问卷后台登录</title>
    <style>body{font-family:sans-serif;background:#f2f3f5;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
    .box{background:#fff;padding:30px;border-radius:10px;width:300px;box-shadow:0 2px 10px rgba(0,0,0,.08)}
    input{width:100%;padding:10px;margin:10px 0;border:1px solid #ddd;border-radius:6px;box-sizing:border-box}
    button{width:100%;padding:11px;background:#1e6fff;color:#fff;border:none;border-radius:6px;cursor:pointer}
    .err{color:#e53935;font-size:13px}</style></head>
    <body><div class="box"><h2 style="margin-top:0">问卷统计后台</h2>
    <?php if (!empty($loginErr)) echo '<div class="err">'.$loginErr.'</div>'; ?>
    <form method="post"><input type="password" name="password" placeholder="请输入后台密码" required><input type="hidden" name="action" value="login"><button>登 录</button></form></div></body></html>
    <?php exit;
}

/* ---------- 读取数据 ---------- */
$rows = [];
if (is_file($dataFile)) {
    foreach (file($dataFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        $r = json_decode($line, true);
        if (is_array($r)) $rows[] = $r;
    }
}

/* ---------- CSV 导出 ---------- */
if (($_GET['export'] ?? '') === 'csv') {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="canteen_survey_' . date('Ymd_His') . '.csv"');
    $out = fopen('php://output', 'w');
    fwrite($out, "\xEF\xBB\xBF"); // BOM
    $cols = ['提交时间','部门','岗位类型','就餐频率','就餐时段','是否外出就餐'];
    foreach ($SCORE_DIMS as $di => $dim) { foreach ($dim[2] as $ii => $it) { $cols[] = $dim[0] . '-' . $it; } }
    $cols = array_merge($cols, ['总分','等级','做得最好3','需改进3','希望新增','高峰空盘','杜绝浪费看法','特殊饮食','改进建议','其他反馈']);
    fputcsv($out, $cols);
    foreach ($rows as $r) {
        $row = [
            $r['ts'] ?? '', $r['dept'] ?? '', $r['post'] ?? '', $r['dine_freq'] ?? '',
            implode('/', $r['dine_time'] ?? []), $r['eat_out'] ?? ''
        ];
        // 评分按序输出（scores: dim,val）
        $byDim = [];
        foreach (($r['scores'] ?? []) as $s) { $byDim[$s['dim']][] = $s['val']; }
        foreach ($SCORE_DIMS as $di => $dim) { foreach (($byDim[$di] ?? []) as $v) { $row[] = $v; } }
        $row = array_merge($row, [
            $r['total'] ?? '', $r['grade'] ?? '', implode('/', $r['best3'] ?? []),
            implode('/', $r['worst3'] ?? []), implode('/', $r['new_cat'] ?? []),
            $r['empty_dish'] ?? '', $r['waste'] ?? '', $r['diet'] ?? '',
            $r['suggestion'] ?? '', $r['other'] ?? ''
        ]);
        fputcsv($out, $row);
    }
    fclose($out);
    exit;
}

/* ---------- 统计 ---------- */
$n = count($rows);
$avgDim = array_fill(0, count($SCORE_DIMS), 0);
$sumTotal = 0; $gradeCnt = []; $cntPost = []; $cntFreq = []; $cntTime = []; $cntEat = [];
$cntBest = []; $cntWorst = []; $cntNew = []; $cntEmpty = []; $cntWaste = []; $dietYes = 0; $deptCnt = [];
foreach ($rows as $r) {
    $sumTotal += (int)($r['total'] ?? 0);
    $g = $r['grade'] ?? ''; $gradeCnt[$g] = ($gradeCnt[$g] ?? 0) + 1;
    foreach (($r['dim_total'] ?? []) as $di => $v) { $avgDim[(int)$di] += (int)$v; }
    if (!empty($r['post'])) $cntPost[$r['post']] = ($cntPost[$r['post']] ?? 0) + 1;
    if (!empty($r['dine_freq'])) $cntFreq[$r['dine_freq']] = ($cntFreq[$r['dine_freq']] ?? 0) + 1;
    foreach (($r['dine_time'] ?? []) as $t) $cntTime[$t] = ($cntTime[$t] ?? 0) + 1;
    if (!empty($r['eat_out'])) $cntEat[$r['eat_out']] = ($cntEat[$r['eat_out']] ?? 0) + 1;
    foreach (($r['best3'] ?? []) as $x) $cntBest[$x] = ($cntBest[$x] ?? 0) + 1;
    foreach (($r['worst3'] ?? []) as $x) $cntWorst[$x] = ($cntWorst[$x] ?? 0) + 1;
    foreach (($r['new_cat'] ?? []) as $x) $cntNew[$x] = ($cntNew[$x] ?? 0) + 1;
    if (!empty($r['empty_dish'])) $cntEmpty[$r['empty_dish']] = ($cntEmpty[$r['empty_dish']] ?? 0) + 1;
    if (!empty($r['waste'])) $cntWaste[$r['waste']] = ($cntWaste[$r['waste']] ?? 0) + 1;
    if (str_starts_with((string)($r['diet'] ?? ''), '是')) $dietYes++;
    if (!empty($r['dept'])) $deptCnt[$r['dept']] = ($deptCnt[$r['dept']] ?? 0) + 1;
}
$avgTotal = $n ? round($sumTotal / $n, 1) : 0;
$gradeOrder = ['好','较好','一般','较差','超差'];
$suggestions = [];
foreach ($rows as $r) { if (!empty($r['suggestion']) || !empty($r['other'])) $suggestions[] = $r; }
?>
<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>食堂问卷统计后台</title>
<style>
body{font-family:-apple-system,"PingFang SC","Microsoft YaHei",sans-serif;background:#f2f3f5;margin:0;color:#333}
.top{background:#1e6fff;color:#fff;padding:14px 20px;display:flex;justify-content:space-between;align-items:center}
.top h1{font-size:17px;margin:0}
.wrap{max-width:960px;margin:16px auto;padding:0 12px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin-bottom:14px}
.card{background:#fff;border-radius:8px;padding:14px;text-align:center;box-shadow:0 1px 4px rgba(0,0,0,.05)}
.card .num{font-size:26px;font-weight:700;color:#1e6fff}
.card .lab{font-size:12px;color:#888;margin-top:4px}
.sec{background:#fff;border-radius:8px;padding:16px;margin-bottom:14px;box-shadow:0 1px 4px rgba(0,0,0,.05)}
.sec h2{font-size:15px;margin:0 0 12px;padding-left:8px;border-left:4px solid #1e6fff}
.bar-row{margin-bottom:8px;font-size:13px}
.bar-row .lbl{display:inline-block;width:170px;vertical-align:middle}
.bar-row .pct{display:inline-block;width:48px;text-align:right;color:#888}
.bar{display:inline-block;height:16px;background:#1e6fff;border-radius:3px;vertical-align:middle;min-width:2px}
.bar.orange{background:#ff9800}
.bar.gray{background:#bdbdbd}
table{width:100%;border-collapse:collapse;font-size:13px}
th,td{border:1px solid #e8e8e8;padding:7px 8px;text-align:left}
th{background:#f7f8fa}
.msg{background:#fff8e1;border:1px solid #ffe082;border-radius:6px;padding:10px;font-size:13px;margin-bottom:12px}
a.btn{background:#1e6fff;color:#fff;padding:6px 14px;border-radius:4px;text-decoration:none;font-size:13px}
a.logout{color:#fff;opacity:.85;font-size:13px;text-decoration:none}
.empty{color:#999;text-align:center;padding:30px;font-size:14px}
</style></head>
<body>
<div class="top"><h1>🍽️ 食堂满意度问卷 · 统计后台</h1>
  <span><a class="btn" href="?export=csv">导出 CSV</a> &nbsp; <a class="logout" href="?action=logout">退出</a></span>
</div>
<div class="wrap">
<?php if ($n === 0): ?>
  <div class="empty">暂无提交数据。问卷地址：<b><?php echo htmlspecialchars((($_SERVER['HTTPS'] ?? '') ? 'https' : 'http') . '://' . ($_SERVER['HTTP_HOST'] ?? '') . '/survey/'); ?></b></div>
<?php else: ?>
  <div class="cards">
    <div class="card"><div class="num"><?php echo $n; ?></div><div class="lab">总提交份数</div></div>
    <div class="card"><div class="num"><?php echo $avgTotal; ?></div><div class="lab">总分平均</div></div>
    <?php foreach ($SCORE_DIMS as $di => $dim): ?>
      <div class="card"><div class="num" style="font-size:20px"><?php echo $n ? round($avgDim[$di] / $n, 1) : 0; ?>/<?php echo $dim[1]; ?></div><div class="lab"><?php echo htmlspecialchars($dim[0]); ?> 均分</div></div>
    <?php endforeach; ?>
  </div>

  <div class="sec"><h2>总得分等级分布（满分 100）</h2>
    <?php foreach ($gradeOrder as $g): $c = $gradeCnt[$g] ?? 0; $p = $n ? round($c / $n * 100, 1) : 0; ?>
      <div class="bar-row"><span class="lbl"><?php echo $g; ?>（<?php echo $c; ?> 人）</span><span class="bar" style="width:<?php echo max($p, 1); ?>%;background:<?php echo $p >= 20 ? '#1e6fff' : ($p > 0 ? '#ff9800' : '#bdbdbd'); ?>"></span><span class="pct"><?php echo $p; ?>%</span></div>
    <?php endforeach; ?>
  </div>

  <div class="sec"><h2>基本信息分布</h2>
    <?php echo distRow('岗位类型', $cntPost, $n); ?>
    <?php echo distRow('就餐频率', $cntFreq, $n); ?>
    <?php echo distRow('就餐时段(多选)', $cntTime, $n); ?>
    <?php echo distRow('是否外出就餐', $cntEat, $n); ?>
    <?php echo distRow('特殊饮食需求', ['是' => $dietYes, '否' => $n - $dietYes], $n); ?>
  </div>

  <div class="sec"><h2>专项调研分布（多选按被选次数统计）</h2>
    <?php echo distRow('做得最好的方面', $cntBest, $n); ?>
    <?php echo distRow('最需改进的方面', $cntWorst, $n); ?>
    <?php echo distRow('希望新增品类', $cntNew, $n); ?>
    <?php echo distRow('高峰空盘情况', $cntEmpty, $n); ?>
    <?php echo distRow('杜绝浪费倡议看法', $cntWaste, $n); ?>
  </div>

  <?php if ($deptCnt): ?>
  <div class="sec"><h2>参与部门（按提交数 Top）</h2>
    <?php arsort($deptCnt); echo distRow('部门', array_slice($deptCnt, 0, 12), $n); ?>
  </div>
  <?php endif; ?>

  <div class="sec"><h2>意见与建议（<?php echo count($suggestions); ?> 条）</h2>
    <?php if (!$suggestions): ?><div class="empty">暂无文字建议</div>
    <?php else: ?>
    <table><tr><th style="width:140px">提交时间</th><th>内容</th></tr>
    <?php foreach ($suggestions as $s): ?>
      <tr><td><?php echo htmlspecialchars((string)($s['ts'] ?? '')); ?></td>
      <td>
        <?php if (!empty($s['suggestion'])): ?><div><b>改进建议：</b><?php echo nl2br(htmlspecialchars((string)$s['suggestion'])); ?></div><?php endif; ?>
        <?php if (!empty($s['other'])): ?><div style="margin-top:4px"><b>其他反馈：</b><?php echo nl2br(htmlspecialchars((string)$s['other'])); ?></div><?php endif; ?>
        <?php if (!empty($s['diet']) && !str_starts_with((string)$s['diet'], '否')): ?><div style="margin-top:4px;color:#e65100"><b>特殊饮食：</b><?php echo htmlspecialchars((string)$s['diet']); ?></div><?php endif; ?>
        <div style="color:#999;font-size:12px;margin-top:3px">总分 <?php echo (int)($s['total'] ?? 0); ?>（<?php echo htmlspecialchars((string)($s['grade'] ?? '')); ?>）· 岗位：<?php echo htmlspecialchars((string)($s['post'] ?? '')); ?></div>
      </td></tr>
    <?php endforeach; ?>
    </table>
    <?php endif; ?>
  </div>
<?php endif; ?>
</div>
</body></html>
<?php
function distRow(string $title, array $cnt, int $n): string {
    if (!$cnt) return '';
    arsort($cnt);
    $max = max($cnt);
    $h = '<h3 style="font-size:13px;color:#555;margin:14px 0 8px">' . htmlspecialchars($title) . '</h3>';
    foreach ($cnt as $k => $c) {
        $p = $n ? round($c / $n * 100, 1) : 0;
        $w = $max ? round($c / $max * 100) : 1;
        $h .= '<div class="bar-row"><span class="lbl">' . htmlspecialchars((string)$k) . '</span><span class="bar" style="width:' . $w . '%"></span><span class="pct">' . $c . '（' . $p . '%）</span></div>';
    }
    return $h;
}
