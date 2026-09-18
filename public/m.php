<?php
 function envDb(string $key, string $default = ''): string { static $env = null; if ($env === null) { $env = []; $file = dirname(__DIR__) . '/.env'; if (is_file($file)) { foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) { $line = trim($line); if ($line === '' || strpos($line, '#') === 0) continue; $pos = strpos($line, '='); if ($pos === false) continue; $env[trim(substr($line, 0, $pos))] = trim(substr($line, $pos + 1), " \t\n\r\0\x0B\"'"); } } } return $env[$key] ?? $default; } define('DB_HOST', envDb('DB_HOST', '127.0.0.1')); define('DB_PORT', (int) envDb('DB_PORT', '3306')); define('DB_NAME', envDb('DB_NAME', '')); define('DB_USER', envDb('DB_USER', '')); define('DB_PASS', envDb('DB_PASS', '')); $requestUri = $_SERVER['REQUEST_URI'] ?? '/'; $path = parse_url($requestUri, PHP_URL_PATH); $path = trim($path, '/'); $segments = explode('/', $path); $pageKey = $segments[1] ?? 'home'; $pageKey = preg_replace('/[^a-z0-9_-]/', '', $pageKey) ?: 'home'; $preview = isset($_GET['preview']) ? (int)$_GET['preview'] : 0; try { $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=utf8mb4'; $pdo = new PDO($dsn, DB_USER, DB_PASS, [ PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, ]); $stmt = $pdo->prepare('SELECT * FROM diy_pages WHERE page_key = ? ORDER BY id DESC LIMIT 1'); $stmt->execute([$pageKey]); $info = $stmt->fetch(); $pageName = '预览'; $items = []; $bgColor = '#f5f6fa'; if ($info) { $value = json_decode($info['value'] ?? '{}', true) ?: []; $pageName = $info['name'] ?? '预览'; $items = $value['items'] ?? []; $bgColor = $value['style']['bgColor'] ?? ($value['page']['bgColor'] ?? '#f5f6fa'); } } catch (Exception $e) { $pageName = '加载失败'; $items = []; $bgColor = '#f5f6fa'; } $itemsJson = json_encode($items, JSON_UNESCAPED_UNICODE); $title = htmlspecialchars($pageName, ENT_QUOTES, 'UTF-8'); $bg = htmlspecialchars($bgColor, ENT_QUOTES, 'UTF-8'); ?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title><?= $title ?> - 预览</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','PingFang SC','Microsoft YaHei',sans-serif;background:<?= $bg ?>;min-height:100vh;font-size:14px;color:#303133}
.preview-header{background:linear-gradient(135deg,#667eea,#764ba2);padding:12px 16px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100}
.preview-header .back-btn{color:#fff;font-size:18px;text-decoration:none;padding:4px 8px;border-radius:4px;background:rgba(255,255,255,0.15)}
.preview-header .title{color:#fff;font-size:16px;font-weight:600;flex:1}
.preview-header .badge{background:rgba(255,255,255,0.2);color:#fff;font-size:11px;padding:2px 8px;border-radius:10px}
.preview-item{background:#fff;border-radius:10px;margin:8px 12px;padding:12px 14px;box-shadow:0 1px 4px rgba(0,0,0,0.04);overflow:hidden}
.preview-item .item-label{font-size:10px;color:#909399;margin-bottom:2px;text-transform:uppercase}
.preview-item .item-type{font-weight:600;color:#1a1a2e;font-size:14px;margin-bottom:4px}
.preview-item .item-data{font-size:12px;color:#606266;line-height:1.6;word-break:break-all}
.preview-item .item-data img{max-width:100%;border-radius:6px;margin-top:4px}
.preview-empty{text-align:center;padding:60px 20px;color:#c0c4cc}
.preview-empty .empty-icon{font-size:48px;margin-bottom:12px;display:block}
.preview-empty .empty-text{font-size:14px;line-height:1.8}
.preview-footer{text-align:center;padding:16px;font-size:11px;color:#c0c4cc}
</style>
</head>
<body>
<div class="preview-header">
  <a class="back-btn" href="javascript:history.back()">‹</a>
  <span class="title"><?= $title ?></span>
  <span class="badge">预览</span>
</div>
<div id="app"></div>
<div class="preview-footer">— 预览模式 —</div>
<script>
(function(){var items=<?= $itemsJson ?>||[];var c=document.getElementById('app');if(!items.length){c.innerHTML='<div class="preview-empty"><span class="empty-icon">📐</span><div class="empty-text">页面暂无内容</div></div>';return}
var h='';items.forEach(function(it){var d=it.data||{},s=it.style||{};var mt=(s.marginTop||0)+'px',mb=(s.marginBottom||8)+'px';h+='<div class="preview-item" style="margin-top:'+mt+';margin-bottom:'+mb+'">';
h+='<div class="item-label">'+it.type+'</div><div class="item-type">'+L(it.type)+'</div>';
if(d.text) h+='<div class="item-data">📝 '+E(d.text)+'</div>';if(d.title) h+='<div class="item-data">📋 '+E(d.title)+'</div>';
if(d.content) h+='<div class="item-data">📄 '+E(d.content.substr(0,200))+'</div>';
if(d.url){if(d.url.match(/\.(jpg|jpeg|png|gif|webp|svg)/i))h+='<div class="item-data"><img src="'+E(d.url)+'" alt="image"></div>';else h+='<div class="item-data">🔗 '+E(d.url)+'</div>'}
if(d.images&&d.images.length){h+='<div class="item-data">';d.images.slice(0,3).forEach(function(img){if(img.url)h+='<img src="'+E(img.url)+'" style="width:31%;margin:1%">'});h+='</div>'}
if(d.items&&d.items.length)h+='<div class="item-data">📋 '+d.items.length+' 条数据</div>';if(d.value)h+='<div class="item-data">📊 '+E(d.value)+'</div>';
if(d.batchNo)h+='<div class="item-data">🔖 批次: '+E(d.batchNo)+'</div>';if(d.status)h+='<div class="item-data">📌 状态: '+E(d.status)+'</div>';
if(d.name)h+='<div class="item-data">🏷️ '+E(d.name)+'</div>';if(d.planNo)h+='<div class="item-data">📋 '+E(d.planNo)+'</div>';
if(d.orderNo)h+='<div class="item-data">📋 '+E(d.orderNo)+'</div>';if(d.applicant)h+='<div class="item-data">👤 '+E(d.applicant)+'</div>';
h+='</div>'});c.innerHTML=h;
function L(t){var m={'top-nav':'顶部导航栏','bottom-nav':'底部导航栏','search-bar':'搜索栏','swiper':'轮播图','title-text':'标题文字','rich-text':'富文本','divider':'分割线','blank':'空白','image':'图片','image-group':'图片组','video':'视频','audio':'音频','countdown':'倒计时','notice-scroll':'公告滚动','notice-bar':'提示条','tag-group':'标签组','badge':'徽标','icon':'图标','article-list':'图文列表','notice-list':'公告列表','menu-grid':'网格菜单','product-list':'商品列表','comment-list':'评论列表','order-list':'订单列表','rank-list':'排行榜','timeline':'时间线','user-card':'个人信息卡','todo-list':'待办任务','quick-approval':'快捷审批','attendance-card':'考勤卡片','message-list':'消息通知','quick-buttons':'快捷操作','employee-list':'员工列表','approval-progress':'审批进度','stats-card':'数据统计','calendar':'日历','inventory-overview':'库存概览','inventory-alert':'库存预警','inbound-order':'入库单','outbound-order':'出库单','stock-count':'库存盘点','inventory-log':'库存流水','location-mgmt':'货位管理','batch-mgmt':'批次管理','stock-transfer':'库存调拨','warehouse-dashboard':'仓库看板','production-plan':'生产计划','work-order':'生产工单','production-progress':'生产进度','line-dashboard':'产线看板','process-mgmt':'工序管理','wip-mgmt':'在制品管理','work-report':'生产报工','production-quality':'生产质量','downtime-log':'设备停机','energy-monitor':'车间能耗','my-approvals':'我的审批','my-initiated':'我发起的','approval-detail':'审批详情','approval-stats':'审批统计','leave-approval':'请假审批','expense-approval':'报销审批','purchase-approval':'采购审批','contract-approval':'合同审批','payment-approval':'付款审批','overtime-approval':'加班审批','equipment-list':'设备列表','equipment-status':'设备状态','maintenance-record':'维修记录','inspection-record':'巡检记录','maintenance-plan':'保养计划','spare-parts':'备件','equipment-profile':'设备档案','fault-analysis':'故障分析','quality-inspection':'质检记录','nonconforming':'不合格品','quality-analysis':'质量分析','inspection-standard':'检验标准','quality-trace':'质量追溯','complaint-mgmt':'客诉管理','safety-hazard':'安全隐患','safety-patrol':'安全巡检','safety-incident':'安全事故','safety-training':'安全培训','safety-notice':'安全公告','ppe-mgmt':'劳保用品','org-chart':'组织架构','address-book':'通讯录','salary-query':'工资查询','attendance-stats':'考勤统计','overtime-record':'加班记录','leave-record':'请假记录','business-trip':'出差记录','employee-profile':'员工档案','bar-chart':'柱状图','line-chart':'折线图','pie-chart':'饼图','donut-chart':'环形图','radar-chart':'雷达图','scatter-chart':'散点图','gauge':'仪表盘','heatmap':'热力图','tree-map':'树图','progress-ring':'进度环','container':'容器','card':'卡片','tabs':'标签页','collapse':'折叠','float-container':'浮动','footer-copyright':'版权'};return m[t]||t}
function E(s){if(!s)return '';return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}
})();
</script>
</body>
</html>
