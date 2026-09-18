<div align="center">

# 数智管控平台（SC Admin）

**制造 / 装备企业一体化数智管理系统 · v19.0.0**

</div>

<div align="center">

<a href='https://gitee.com/li-yao11111/sc-admin/stargazers'>
  <img src='https://gitee.com/li-yao11111/sc-admin/badge/star.svg?theme=gvp' alt='star'></img>
</a>
<a href="https://img.shields.io/badge/版本-v19.0.0-blue">
  <img src="https://img.shields.io/badge/版本-v19.0.0-blue" />
</a>
<a href="https://img.shields.io/badge/试用-30天-orange">
  <img src="https://img.shields.io/badge/试用-30天-orange" />
</a>
<a href="https://img.shields.io/badge/授权-绑定域名-green">
  <img src="https://img.shields.io/badge/授权-绑定域名-green" />
</a>

</div>

<div align="center">

[在线体验](http://test-install.yywyrh.cn/admin/) | [移动端 H5](http://test-install.yywyrh.cn/h5/) | [提交反馈](https://gitee.com/li-yao11111/sc-admin/issues)

</div>

<div align="center">

🖥 **在线体验（含演示数据）**：后台 http://test-install.yywyrh.cn/admin/ ｜ 移动端 http://test-install.yywyrh.cn/h5/
👤 **演示账号（只读）**：demo ／ admin123　※ 仅可查看数据，无新增 / 编辑 / 删除等操作权限

</div>

---

### 📝 项目介绍

**平台定位**

面向制造 / 装备企业的数智管控平台，覆盖**人事、经营、仓储、生产、安全、设备、财务、审批、企业网盘**等全业务场景，配套**移动端 H5**与**数据驾驶舱大屏**，一套系统打通企业管理全链路。

**技术架构**

采用 **ThinkPHP 8 + Vue 2.7 + UniApp** 技术栈，前后端分离设计；后台 Web 端 + 移动端 H5 双端数据实时联动，支持部署于宝塔面板 / 云服务器 / 物理机。

**核心亮点**

- **数据驾驶舱**：经营驾驶舱、安全驾驶舱、安全生产大屏、系统监控四大看板，深色科技风设计，支持全屏投屏（会议室 / LED 大屏）
- **全场景覆盖**：后台管理、移动办公、审批流转、实时消息、扫码出入库、质量追溯一应俱全
- **开箱即用**：内置安装向导，自动建库、自动导入数据、自动生成环境配置，10 分钟完成部署
- **授权灵活**：30 天试用 → 授权码激活，授权码与绑定域名一一对应，换域名需重新授权

---

### 🧩 功能特性

#### 管理后台（Web 端）

| 模块 | 主要功能 |
|---|---|
| 首页控制台 | 待办提醒、快捷入口、关键经营数据一览 |
| 组织人事 | 员工档案、部门/岗位、考勤打卡、薪资核算、招聘、劳动合同 |
| 经营管理 | 客户管理、供应商档案/评级、询比价、订单、合同履约跟踪 |
| 仓储物流 | 库存查询/盘点/预警/调拨、扫码出入库、批次/库位、库存分析 |
| 生产制造 | 工艺路线、MRP 需求计划、生产计划、成本核算、异常呼叫（Andon）、ECN 变更、质量追溯 |
| 设备管理 | 设备台账、点检保养、维修工单 |
| 安全管理 | 隐患管理、巡检任务、安全培训、证书管理、安全驾驶舱、安全生产大屏 |
| 财务中心 | 记账凭证、总账/明细账、财务报表、费用报销、应付账款、固定资产、个人资产调拨 |
| 审批中心 | 统一审批流、我的待办/已办、审批消息通知 |
| 企业网盘 | 文件/文件夹管理、按部门/员工授权、密码文件夹、回收站 |
| 数据驾驶舱 | 经营驾驶舱、安全驾驶舱、安全生产大屏、系统监控（支持全屏投屏） |
| 系统设置 | 用户/角色/权限、菜单、数据字典、公告、协议管理、系统监控 |

#### 移动端（H5）

| 模块 | 主要功能 |
|---|---|
| 首页 | 快捷功能入口、公告中心、待办提醒 |
| 通讯录 / 消息 | 组织架构、员工资料、实时聊天（文字 / 图片 / 文件 / 表情） |
| 工作台 | 考勤打卡、工资查询、审批发起、我的证书 |
| 我的 | 个人资料与头像、账号设置、帮助与反馈、关于 |
| 更多 | 全部功能菜单聚合入口 |

---

### 🖥 系统界面展示

**后台登录页**

![后台登录页](docs/screenshots/admin-login.png)

**经营驾驶舱**（经营管理 · 数据大屏）

![经营驾驶舱](docs/screenshots/biz-cockpit.png)

**安全驾驶舱**（安全管理 · 深色科技大屏）

![安全驾驶舱](docs/screenshots/safety-cockpit.png)

**安全生产专题大屏**（LED 大屏展示）

![安全生产专题大屏](docs/screenshots/safety-board.png)

**系统监控**（服务器运行状态实时监控）

![系统监控](docs/screenshots/system-monitor.png)

---

### ⚙️ 技术特点

- **权限管理**：RBAC 角色权限模型，可精细控制到每个菜单/按钮
- **统一审批**：所有业务（报销、合同、采购、调拨等）走统一审批流，移动端/后台同步处理
- **安全体系**：操作日志、登录验证码、JWT 鉴权、数据安全存储、授权域名绑定
- **实时消息**：通讯录实时聊天（文字/图片/文件/表情），本地缓存优先，消息不占用服务器存储
- **大屏能力**：多套数据大屏（经营/安全/生产/监控），深色科技风，60 秒自动刷新
- **扩展友好**：代码分层清晰、注释齐全，支持二次开发与模块扩展
- **多端适配**：后台（PC）+ 移动端（H5）同一套数据，手机扫码即用

---

### 🚀 部署安装

#### 一、环境要求

| 组件 | 要求 | 说明 |
|---|---|---|
| 操作系统 | CentOS 7+ / Ubuntu 18+ / 宝塔面板均可 | 已适配宝塔多版本 PHP |
| Web 服务器 | Nginx（推荐）或 Apache | 站点 root 指向 `public/` |
| PHP | **8.1.x（务必 8.1）** | 运行扩展与 PHP 8.1 版本绑定 |
| MySQL | 5.7+ / 8.0（utf8mb4） | 安装向导自动建库 |
| Redis | 任意版本（含密码） | 缓存/验证码依赖 |

#### 二、PHP 扩展清单（安装向导会自动检测）

必须开启以下扩展，缺一不可：

| 扩展 | 用途 |
|---|---|
| **beast**（随包提供的运行扩展） | 核心依赖，见下方安装 |
| pdo_mysql | 数据库连接 |
| mbstring | 中文/多字节处理 |
| openssl | 签名校验、HTTPS |
| json | 接口数据 |
| curl | 授权平台验证、外部请求 |
| gd | 图片处理（验证码/头像/图片上传） |
| fileinfo | 文件类型识别 |
| zip | 压缩/导出 |
| bcmath | 高精度计算（财务/成本） |
| intl | 国际化/字符处理 |
| redis | 缓存（验证码、权限、会话） |
| xml / SimpleXML | 导入导出 |

> 宝塔面板：软件商店 → PHP 8.1 → 安装扩展，勾选以上全部即可（beast 按下文单独装）。

#### 三、PHP 配置项（php.ini）建议

| 配置项 | 建议值 | 说明 |
|---|---|---|
| `memory_limit` | ≥ **256M**（建议 512M） | 安装向导硬性检测，低于 256M 会拦截 |
| `file_uploads` | On | 文件上传 |
| `allow_url_fopen` | On | 授权回调/远程请求 |
| `post_max_size` / `upload_max_filesize` | ≥ 50M | 附件/凭证上传 |
| `max_execution_time` | ≥ 300（CLI 不限） | 导入大 SQL、报表导出 |
| `date.timezone` | Asia/Shanghai | 避免时间偏差 |

##### ⚠️ 禁用函数（disable_functions）注意事项

系统 PHP 层**不依赖** `exec` / `shell_exec` / `proc_open` 等命令执行函数，但仍请**不要禁用以下函数**，否则授权验证、文件上传、安装向导会失败：

**严禁禁用：**
- `curl_exec`（授权平台验证、远程请求）
- `file_get_contents` / `file_put_contents`（授权回调、写缓存）
- `copy` / `unlink` / `rename` / `mkdir` / `rmdir` / `chmod`（文件操作、热更新）
- `password_hash` / `password_verify`（登录）
- `random_bytes`（JWT/密钥生成）
- `session_start` / `json_encode` / `json_decode`

**可以禁用（不影响运行）：**
- `shell_exec` / `exec` / `system` / `passthru` / `proc_open` / `popen` / `pcntl_exec` 等命令执行类
- 若使用宝塔默认安全配置（已禁用 putenv/proc_open 等），无需调整，系统可正常运行。

#### 四、安装步骤

**1. 解压部署**

将仓库内容上传至站点目录（如 `/www/wwwroot/your-site`），**保留完整目录结构**：

```bash
cd /www/wwwroot
# 方式一：git 克隆（需安装 git）
git clone https://gitee.com/li-yao11111/sc-admin.git your-site
# 方式二：下载压缩包解压
unzip sc-admin.zip -d your-site
cd your-site
```

**2. 设置目录权限**

```bash
chmod -R 777 config runtime public storage database
chown -R www:www /www/wwwroot/your-site   # 宝塔默认运行用户为 www
```

> 安装向导会检测 `config / runtime / public / storage / database` 五个目录可写，权限不足会拦截。

**3. 创建数据库**

- 新建空数据库，编码选 **utf8mb4 / utf8mb4_unicode_ci**
- 数据库账号需对库有 **ALL（增删改查建表）** 权限
- 数据库名/账号/密码稍后在安装向导中填写（向导也支持自动建库）

**4. 安装运行扩展（核心）**

```bash
cd /www/wwwroot/your-site
bash install.sh
```

脚本会自动：定位 PHP 8.1 扩展目录 → 复制运行扩展 → 写入 `php.ini` 启用 → 提示重启 PHP-FPM。

**完成后务必重启 PHP-FPM**：
- 宝塔：软件商店 → PHP 8.1 → 服务 → 重启
- 命令行：`systemctl restart php-fpm`（或宝塔对应命令）

> ⚠️ **重要**：`beast.so` 与 PHP 版本严格绑定（当前为 PHP 8.1 编译）。若服务器 PHP 不是 8.1，请先切换/安装 PHP 8.1 再运行本脚本；否则安装后系统无法正常运行。

**5. 配置 Nginx**

站点 root 指向 `public/`，并配置 ThinkPHP 伪静态：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /www/wwwroot/your-site/public;   # ← 必须指向 public/
    index index.php index.html;

    # 伪静态（重要：否则除首页外全部 404）
    location / {
        if (!-e $request_filename) {
            rewrite ^(.*)$ /index.php?s=$1 last;
        }
    }

    location ~ \.php(.*)$ {
        fastcgi_pass unix:/tmp/php-cgi-81.sock;  # 宝塔：对应 PHP 8.1 的 sock
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2?|ttf|svg|mp4)$ {
        expires 30d;
        access_log off;
    }

    client_max_body_size 50m;   # 上传大小
}
```

- 宝塔面板：站点 → 设置 → 配置文件，粘贴上述 server 块（root 与伪静态为关键）
- Apache 环境：开启 `mod_rewrite`，将 `.htaccess`（public/ 下已内置）启用即可

配置完成后 `nginx -t` 测试并 reload。

**6. 运行安装向导**

浏览器访问：**http://你的域名/install**

按四步完成：
1. **环境检测**：PHP 版本、全部扩展、目录权限、PHP 配置逐项检测，全绿才可继续
2. **数据库配置**：填写数据库主机/端口/库名/账号/密码 + **Redis 密码**（与服务器 Redis 一致）
3. **管理员账号**：设置后台管理员用户名/密码/邮箱
4. **执行安装**：自动导入数据表（约 1.2 万条语句 + 增量迁移）→ 生成 `.env`（含随机 JWT 密钥）→ 创建管理员 → 写入安装锁

安装完成自动跳转后台登录页（`/admin`）。

**7. 授权（试用 → 正式）**

- 首次访问后台自动进入 **30 天试用**，自动绑定当前域名
- 试用满意后：前往授权平台（aa.yywyrh.cn）购买授权码，在后台「系统维护 → 授权管理」输入授权码，或在 `.env` 配置：
  ```ini
  AA_VERIFY_URL = https://aa.yywyrh.cn/api/v1/verify
  AA_PROJECT_CODE = SC_ADMIN
  AA_LICENSE_KEY = SC_ADMIN-XXXXXXXX
  ```
- **授权码与首次绑定的域名一一对应**，更换域名需重新购买
- 试用到期未授权将限制登录，输入有效授权码即恢复

---

### ❓ 常见问题

| 现象 | 原因与解决 |
|---|---|
| 安装向导提示扩展未开启 | 按扩展清单在宝塔开启对应扩展后刷新 |
| 提示目录不可写 | `chmod -R 777 config runtime public storage database` |
| 安装后页面空白/500 | 运行扩展未生效：确认 PHP 为 8.1、`php -m | grep beast` 有输出、已重启 PHP-FPM |
| 除首页外全 404 | Nginx 未配置伪静态（见安装步骤 5） |
| 验证码不显示 | Redis 扩展/密码配置错误，检查 `.env` 的 REDIS_PASSWORD |
| 授权验证失败 | 确认服务器可访问外网（curl 扩展已开），检查授权码与域名 |

---

### 📁 目录结构

```
├── app/            # 应用代码（PHP）
├── config/         # 配置（安装向导生成 install.lock）
├── database/       # 数据库脚本与增量迁移
├── public/         # Web 根目录（nginx root 指向此）
├── resources/      # 视图/模板
├── route/          # 路由
└── vendor/         # 依赖（已内置，无需 composer install）
```

> 其余扩展组件、初始化脚本、部署说明等均随包内置，按上方安装步骤使用即可。`.env` 由安装向导生成随机密钥，无需手动配置。详细部署说明见 `DEPLOY.txt`。

---

### 📮 联系我们

- **Gitee 仓库**：https://gitee.com/li-yao11111/sc-admin
- **在线体验**：http://test-install.yywyrh.cn/admin/（只读演示账号 demo / admin123）｜ 移动端：http://test-install.yywyrh.cn/h5/
- **提交反馈 / 问题**：https://gitee.com/li-yao11111/sc-admin/issues

如果本项目对你有帮助，欢迎右上角 Star ⭐ 支持一下！
