#!/bin/bash
# =====================================================
# ThinkPHP 一键 Nginx 配置脚本
# 用法：解压项目后，在站点目录执行：bash setup-nginx.sh
# 功能：自动写入 安装向导 / 管理后台 / ThinkPHP 伪静态 配置
# 前提：站点 root 已指向本目录的 public/（面板建站时填写）
# =====================================================
set -e

# 检测站点目录（脚本所在目录）
SITE_DIR=$(cd "$(dirname "$0")" && pwd)
SITE_NAME=$(basename "$SITE_DIR")

echo "=============================================="
echo "站点目录: $SITE_DIR"
echo "站点标识: $SITE_NAME"
echo "=============================================="

# 检查站点 root 是否正确（应指向 public）
PUBLIC_DIR="$SITE_DIR/public"
if [ ! -f "$PUBLIC_DIR/index.php" ]; then
    echo "❌ 未找到 $PUBLIC_DIR/index.php"
    echo "   请确认项目已完整解压（含 public/ 目录）"
    exit 1
fi
echo "✅ public/index.php 存在"

# 写入 extension 配置（宝塔面板重生成主配置时保留）
EXT_DIR="/www/server/panel/vhost/nginx/extension/$SITE_NAME"
EXT_FILE="$EXT_DIR/thinkphp-install.conf"
mkdir -p "$EXT_DIR"

cat > "$EXT_FILE" <<EOF
# ThinkPHP 安装向导 / 后台 / 伪静态（由 setup-nginx.sh 生成）
# ---- 系统安装向导 ----
location = /install {
    return 301 /install/;
}
location = /install/ {
    rewrite ^ /index.php/api/install last;
}
location /install/ {
    rewrite ^/install/(.*)\$ /index.php/api/install/\$1 last;
    add_header Cache-Control "no-store, no-cache, must-revalidate";
}
# ---- 管理后台 ----
location ^~ /admin/ {
    alias $SITE_DIR/public/admin/;
    index index.html;
    try_files \$uri \$uri/ /admin/index.html;
    add_header Cache-Control "no-store, no-cache, must-revalidate";
    add_header X-Content-Type-Options "nosniff";
}
# ---- ThinkPHP 伪静态（PATH_INFO） ----
location / {
    if (!-e \$request_filename) {
        rewrite ^(.*)\$ /index.php/\$1 last;
    }
}
EOF

echo "✅ 已写入: $EXT_FILE"

# 检查 rewrite 文件是否已有 location /（避免与伪静态冲突）
REWRITE_FILE="/www/server/panel/vhost/rewrite/$SITE_NAME.conf"
if [ -f "$REWRITE_FILE" ] && grep -q "location /" "$REWRITE_FILE"; then
    echo "⚠️  检测到伪静态文件已有 location /（$REWRITE_FILE）"
    echo "   如访问异常，请到 面板→网站→伪静态 清空或改为【无】，避免与 extension 冲突"
fi

# 提示用户确认 root
echo "=============================================="
echo "✅ 配置已生成。请确认："
echo "  1. 站点 root 指向: $PUBLIC_DIR （面板→网站→设置→网站目录）"
echo "  2. 执行以下命令生效："
echo "     nginx -t && nginx -s reload"
echo "  3. 访问: http://你的域名/install/ 开始安装"
echo "=============================================="

# ==================== beast 扩展安装（复制/编译 + 启用） ====================
# 功能：检测 beast 扩展 → 未安装时自动安装（优先随包 beast.so，其次编译）→ 启用 → 重启 PHP-FPM → 验证
# 注意：beast 密钥在编译时固定，加密代码必须用与打包一致的扩展解密。
#       因此【优先使用随包 beast.so】（密钥已匹配）；编译仅作无 .so 时的回退，且源码必须为同一版本（beast_encryption fork）。
install_beast() {
    echo "=============================================="
    echo "==> beast 扩展安装/检查..."

    # ---- 1. 定位 PHP（宝塔多版本：优先 php81【加密扩展随包为 8.1 编译】，其次其他版本）----
    local PHP_BIN=""
    for p in /www/server/php/81/bin/php /www/server/php/*/bin/php /usr/bin/php; do
        [ -x "$p" ] && PHP_BIN="$p" && break
    done
    if [ -z "$PHP_BIN" ]; then
        echo "❌ 未找到 PHP，请先安装 PHP 8.0+"
        return 1
    fi
    local PHP_VER=$("$PHP_BIN" -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "?")
    echo "    PHP: $PHP_VER ($PHP_BIN)"

    # ---- 2. 已启用则跳过 ----
    if "$PHP_BIN" -m 2>/dev/null | grep -qi beast; then
        echo "✅ beast 扩展已启用（无需重复安装）"
        return 0
    fi

    # ---- 3. 定位扩展目录 / php.ini ----
    local EXT_DIR=$("$PHP_BIN" -i 2>/dev/null | sed -n 's/^extension_dir => //p' | head -1 | awk '{print $1}')
    [ -z "$EXT_DIR" ] && EXT_DIR="/www/server/php/$PHP_VER/lib/php/extensions/no-debug-non-zts-$(ls /www/server/php/$PHP_VER/lib/php/extensions/ 2>/dev/null | head -1)/"
    local PHP_INI="/www/server/php/$PHP_VER/etc/php.ini"   # 优先 php-fpm 的 php.ini（写这里才影响网站运行）
    [ -f "$PHP_INI" ] || PHP_INI=$("$PHP_BIN" -i 2>/dev/null | sed -n 's/^Loaded Configuration File => //p' | head -1 | awk '{print $1}')
    [ -z "$PHP_INI" ] && PHP_INI="/www/server/php/$PHP_VER/etc/php.ini"
    echo "    扩展目录: $EXT_DIR"
    echo "    php.ini : $PHP_INI"

    # ---- 4. beast.so 来源：①扩展目录已有 ②随包 .so（密钥匹配，推荐）③编译 ----
    local BEAST_SO=""
    if [ -f "$EXT_DIR/beast.so" ]; then
        echo "    📦 使用扩展目录已有 beast.so: $EXT_DIR/beast.so"
    else
    for cand in "$SITE_DIR/beast.so" "$SITE_DIR/public/beast.so"; do
        [ -f "$cand" ] && BEAST_SO="$cand" && break
    done
    if [ -n "$BEAST_SO" ]; then
        echo "    📦 使用随包 beast.so: $BEAST_SO"
        cp -f "$BEAST_SO" "$EXT_DIR/beast.so" && chmod 755 "$EXT_DIR/beast.so"
    else
        # ---- 5. 无随包 .so → 尝试编译（源码需与加密密钥一致）----
        echo "    ⚠️ 未找到随包 beast.so，尝试编译（源码必须为 beast_encryption 同款，否则密钥不匹配无法解密）..."
        local SRC=""
        for cand in "$SITE_DIR/beast_encryption" "$SITE_DIR/beast_encryption-main" /tmp/beast_encryption-main; do
            [ -f "$cand/beast.c" ] && SRC="$cand" && break
        done
        if [ -z "$SRC" ]; then
            echo "❌ 无 beast 源码，无法编译。请将匹配的 beast.so 放到站点目录后重新执行本脚本"
            echo "   注意：beast 密钥编译固定，必须使用与加密代码一致的版本（随包 beast.so 已匹配）"
            return 1
        fi
        echo "    编译源码: $SRC"
        cd "$SRC" || return 1
        "$PHP_BIN" ../../bin/phpize >/dev/null 2>&1 || /www/server/php/$PHP_VER/bin/phpize >/dev/null 2>&1
        ./configure --with-php-config="/www/server/php/$PHP_VER/bin/php-config" >/dev/null 2>&1
        make -j"$(nproc)" >/dev/null 2>&1
        make install >/dev/null 2>&1
        if [ -f "$EXT_DIR/beast.so" ]; then
            echo "    ✅ beast 编译安装完成"
        else
            echo "❌ 编译失败（可能缺少 gcc/autoconf/phpize），请安装后重试或将随包 beast.so 放到站点目录"
            return 1
        fi
    fi
    fi

    # ---- 6. 启用扩展（php.ini）----
    if ! grep -q "extension=beast.so" "$PHP_INI" 2>/dev/null; then
        echo "extension=beast.so" >> "$PHP_INI"
        echo "    已写入 php.ini: extension=beast.so"
    else
        echo "    php.ini 已有 beast 启用行"
    fi

    # ---- 7. 重启 PHP-FPM ----
    if [ -x "/etc/init.d/php-fpm-$PHP_VER" ]; then
        /etc/init.d/php-fpm-$PHP_VER restart >/dev/null 2>&1
        echo "    ✅ PHP-FPM 已重启"
    else
        echo "    ⚠️ 未找到 /etc/init.d/php-fpm-$PHP_VER，请手动重启 PHP-FPM"
    fi

    # ---- 8. 验证 ----
    if "$PHP_BIN" -m 2>/dev/null | grep -qi beast; then
        echo "✅ beast 扩展安装成功并验证通过（加密代码可正常运行）"
    else
        echo "❌ beast 启用失败，请检查扩展目录与 php.ini 配置"
    fi
}
install_beast
echo "=============================================="
echo "✅ 全部配置完成：nginx 伪静态 + beast 扩展"
echo "=============================================="

# ==================== 定时任务配置（cron） ====================
# 功能：自动写入 授权心跳/远程控制 + 业务计划任务（去重，重复执行安全）
# 说明：也可用宝塔面板→计划任务手动添加（命令见下方注释）
setup_cron() {
    echo "=============================================="
    echo "==> 配置定时任务..."

    # 定位 PHP（code_sync/think 均需 beast 扩展，优先 /usr/bin/php 或站点 php）
    local PHP_BIN="/usr/bin/php"
    [ -x "$PHP_BIN" ] || PHP_BIN=$(command -v php || echo "/www/server/php/81/bin/php")
    echo "    PHP: $PHP_BIN"

    # 统一调度：cron 仅 1 行，schedule.php 内部按频率分发全部 27 个定时任务
    local LINE="* * * * * $PHP_BIN $SITE_DIR/schedule.php > /dev/null 2>&1"

    # 去重写入 crontab（移除旧的 code_sync/think 任务行与本站点行，追加新行）
    local TMP_FILE=$(mktemp)
    if crontab -l > "$TMP_FILE" 2>/dev/null; then
        grep -vE "code_sync\.php|schedule\.php|$SITE_DIR" "$TMP_FILE" > "${TMP_FILE}.new" 2>/dev/null || true
        mv -f "${TMP_FILE}.new" "$TMP_FILE" 2>/dev/null || true
    fi
    printf '%s\n' "$LINE" >> "$TMP_FILE"
    if crontab "$TMP_FILE" 2>/dev/null; then
        rm -f "$TMP_FILE"
        echo "✅ 定时任务已配置（1 行统一调度：授权心跳/远程控制 + 26 个业务任务）"
    else
        rm -f "$TMP_FILE"
        echo "⚠️ crontab 写入失败，请手动添加：$LINE"
    fi
    echo "    查看: crontab -l"
    echo "=============================================="
}
setup_cron
