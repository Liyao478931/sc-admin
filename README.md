

# 数智管控平台（SC Admin）

## 项目简介

数智管控平台是一款面向制造与装备企业的数字化管理解决方案，涵盖人事管理、经营分析、仓储物流、生产制造、安全环保、设备运维、财务审批、企业网盘等核心业务模块。平台配套移动端 H5 应用与数据驾驶舱，支持多端协同办公，助力企业实现智能化管理与数字化转型。

> **注意**：本源码经过 beast 加密处理，部署后可直接运行，无需额外解密。

---

## 技术架构

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| 后端框架 | ThinkPHP 8.x | 企业级 PHP MVC 框架 |
| PHP 版本 | 8.1.x | 必须使用 PHP 8.1（与 beast 扩展绑定） |
| 数据库 | MySQL 5.7+ / 8.0 | 采用 utf8mb4 编码 |
| 缓存 | Redis | 会话、权限、验证码等缓存管理 |
| 前端框架 | Vue 3.x + Element Plus | 企业级后台管理系统 |
| 认证机制 | JWT（JSON Web Token） | 无状态安全认证 |
| 定时任务 | ThinkPHP Command | 业务调度与数据处理 |

---

## 核心功能模块

### 智能应用（AI）
- **智能客服 Agent**：AI 客服对话管理
- **知识库管理**：向量知识库构建与检索
- **AI 应用市场**：预置 AI 工具与应用模板
- **工作流引擎**：可视化 AI 工作流编排
- **数据洞察**：AI 预测与数据分析

### 生产制造（Production）
- **生产订单**：订单创建、跟踪与闭环管理
- **工艺路线**：产品 BOM 与工艺流程配置
- **生产调度**：排程计划与进度跟踪
- **质量管控**：质检任务、报表与统计分析
- **OEE 监控**：设备综合效率实时监控

### 仓储物流（Warehouse）
- **库存管理**：实时库存监控与预警
- **出入库**：采购入库、销售出库、调拨管理
- **盘点管理**：定期盘点与差异处理
- **物料追溯**：全链路物料追踪
- **库存分析**：库存周转与成本分析

### 设备管理（Device）
- **设备档案**：设备全生命周期管理
- **设备巡检**：巡检计划与记录管理
- **设备保养**：保养计划与执行跟踪
- **设备维修**：报修流程与维修记录
- **设备状态**：状态变更与看板展示

### 安全管理（Safety）
- **隐患排查**：隐患上报与整改闭环
- **安全检查**：检查计划与执行记录
- **风险评估**：风险辨识与分级管控
- **事故管理**：事故调查与处理跟踪
- **安全培训**：培训计划与考核记录

### 人力资源（HR）
- **员工管理**：员工档案与组织架构
- **考勤管理**：排班、考勤记录与统计
- **薪资核算**：工资条与薪资统计
- **绩效评估**：考核模板与任务管理
- **审批流程**：人事相关审批工作流

### 财务管理（Finance）
- **费用报销**：报销申请与审批
- **合同管理**：合同签署与履约跟踪
- **付款管理**：付款计划与执行
- **财务报表**：经营数据分析与报表

### 企业网盘（Drive）
- **文件管理**：文件夹与文件操作
- **权限控制**：细粒度访问权限管理
- **分享协作**：文件共享与协作
- **回收站**：误删文件恢复

### 审批中心（Approval）
- **自定义流程**：可视化流程配置
- **多级审批**：支持会签、或签、转签
- **移动审批**：H5 端便捷审批
- **审批历史**：完整审批轨迹追溯

### 移动端（Mobile）
- **H5 应用**：适配移动端的工作界面
- **消息推送**：实时通知与提醒
- **扫码功能**：条码/二维码扫描识别
- **定位服务**：地理位置相关功能

---

## 目录结构

```
sc-admin/
├── app/                    # 应用核心代码（加密）
│   ├── api/               # API 控制器
│   │   ├── controller/    # 业务控制器
│   │   ├── command/       # 命令行任务
│   │   └── route/         # 路由定义
│   ├── model/             # 数据模型
│   ├── service/           # 业务服务层
│   ├── middleware/        # 中间件
│   ├── library/           # 公共类库
│   └── common/            # 公共函数与 Trait
├── database/              # 数据库相关
│   ├── migrations/        # 数据迁移脚本
│   └── seeds/             # 数据填充脚本
├── public/                # Web 入口目录
│   ├── admin/             # 后台前端资源
│   └── index.php          # 入口文件
├── config/                # 配置文件目录
├── runtime/               # 运行时缓存
├── storage/               # 存储目录
├── database.sql           # 数据库初始化脚本
├── install.sh             # beast 扩展安装脚本
└── code_sync.php          # 授权验证驱动
```

---

## 环境要求

### 服务器要求
- **操作系统**：CentOS 7+ / Ubuntu 18+ / 宝塔面板
- **Web 服务器**：Nginx（推荐）或 Apache
- **PHP 版本**：8.1.x（必须使用 PHP 8.1）
- **数据库**：MySQL 5.7+ / 8.0（utf8mb4 编码）
- **Redis**：任意版本（需配置密码）

### PHP 扩展要求
| 扩展 | 用途 |
|------|------|
| beast | 源码解密核心扩展（随包提供） |
| pdo_mysql | 数据库连接 |
| mbstring | 中文处理 |
| openssl | 加密与签名 |
| curl | 网络请求 |
| gd | 图片处理 |
| fileinfo | 文件类型识别 |
| zip | 压缩处理 |
| redis | 缓存服务 |
| json | 接口数据 |

---

## 安装部署

### 1. 环境准备

```bash
# 安装 PHP 8.1 及所需扩展（宝塔面板可通过软件商店一键安装）
# 安装 MySQL 5.7+ / 8.0
# 安装 Redis 并配置密码
```

### 2. 上传代码

```bash
cd /www/wwwroot
git clone https://gitee.com/li-yao11111/sc-admin.git your-site
# 或下载压缩包解压
unzip sc-admin.zip -d your-site
```

### 3. 设置权限

```bash
chmod -R 777 config runtime public storage database
chown -R www:www /www/wwwroot/your-site
```

### 4. 安装 beast 扩展

```bash
cd /www/wwwroot/your-site
bash install.sh
```

安装完成后**重启 PHP-FPM**使扩展生效。

### 5. 配置 Nginx

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /www/wwwroot/your-site/public;
    index index.php;

    location / {
        if (!-e $request_filename) {
            rewrite ^(.*)$ /index.php?s=$1 last;
        }
    }

    location ~ \.php(.*)$ {
        fastcgi_pass unix:/tmp/php-cgi-81.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2?|ttf|svg)$ {
        expires 30d;
        access_log off;
    }

    client_max_body_size 50m;
}
```

### 6. 运行安装向导

浏览器访问 **http://你的域名/install**，按向导完成：
1. 环境检测（PHP 版本、扩展、权限）
2. 数据库配置（数据库信息 + Redis 密码）
3. 管理员账号设置
4. 执行安装（自动建表并生成 .env 配置）

---

## 许可证说明

- **试用模式**：首次安装自动激活 30 天试用，自动绑定当前域名
- **正式授权**：访问授权平台（aa.yywyrh.cn）购买授权码
- **授权配置**：在后台「系统维护 → 授权管理」或 `.env` 中配置授权码

---

## 常见问题

| 问题现象 | 解决方案 |
|---------|---------|
| 页面空白/500 错误 | 检查 beast 扩展是否生效，确认 PHP 8.1，重启 PHP-FPM |
| 扩展检测不通过 | 在 php.ini 中启用所需扩展并重启 PHP-FPM |
| 目录无写权限 | 执行 `chmod -R 777 config runtime public storage database` |
| 除首页外 404 | 检查 Nginx 伪静态配置 |
| 验证码不显示 | 检查 Redis 连接配置与密码设置 |
| 授权验证失败 | 确认服务器可访问外网，检查授权码与域名绑定 |

---

## 更新日志

每次版本更新会自动记录变更内容，可在后台「系统维护 → 版本更新」中查看。

---

## 技术支持

如遇部署问题，请通过以下方式获取支持：
- 查阅项目内的 `DEPLOY.txt` 部署文档
- 联系技术支持团队

---

**SC Admin - 助力企业数字化转型**