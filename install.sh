#!/bin/bash
# ============================================================
# beast 解密扩展一键安装脚本（客户服务器运行）
# 用法：解压项目包后执行  bash install.sh
# 自动：定位 PHP 扩展目录与 php.ini → 复制 beast.so → 启用扩展
# 最后提示重启 PHP-FPM（宝塔/常规环境）
# ============================================================
set -e

echo "==> 检测 PHP 环境..."
PHP_BIN=$(command -v php || true)
if [ -z "$PHP_BIN" ]; then
    # 宝塔多版本：尝试 php81
    for p in /www/server/php/*/bin/php; do
        [ -x "$p" ] && PHP_BIN="$p" && break
    done
fi
if [ -z "$PHP_BIN" ]; then
    echo "错误：未找到 PHP，请安装 PHP 8.0+ 后重试"
    exit 1
fi

PHP_VER=$("$PHP_BIN" -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "?")
echo "    PHP: $PHP_VER ($PHP_BIN)"

EXT_DIR=$("$PHP_BIN" -i 2>/dev/null | grep '^extension_dir' | awk '{print $3}')
INI_FILE=$("$PHP_BIN" --ini 2>/dev/null | grep 'Loaded Configuration' | awk -F': ' '{print $2}')
if [ -z "$EXT_DIR" ] || [ -z "$INI_FILE" ]; then
    echo "错误：无法定位 PHP 扩展目录或 php.ini"
    exit 1
fi
echo "    扩展目录: $EXT_DIR"
echo "    php.ini: $INI_FILE"

echo "==> 复制 beast.so 到扩展目录..."
cp -f beast.so "$EXT_DIR/beast.so"
chmod 644 "$EXT_DIR/beast.so"

echo "==> 启用扩展（php.ini 追加配置）..."
if grep -q '^extension=beast.so' "$INI_FILE"; then
    echo "    beast 已启用，跳过"
else
    # 若未配置过 beast.log_file 则补充
    if ! grep -q '^beast.log_file' "$INI_FILE"; then
        printf '\n; beast 代码解密扩展\nextension=beast.so\nbeast.log_file=/tmp/php-beast.log\n' >> "$INI_FILE"
    else
        printf '\n; beast 代码解密扩展\nextension=beast.so\n' >> "$INI_FILE"
    fi
    echo "    已追加 extension=beast.so"
fi

echo "==> 尝试重启 PHP-FPM..."
RESTARTED=0
# 宝塔环境
if [ -x /etc/init.d/php-fpm-81 ]; then /etc/init.d/php-fpm-81 restart >/dev/null 2>&1 && RESTARTED=1; fi
if [ "$RESTARTED" = "0" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl restart php-fpm >/dev/null 2>&1 && RESTARTED=1 || true
    systemctl restart "php$PHP_VER-fpm" >/dev/null 2>&1 && RESTARTED=1 || true
fi
if [ "$RESTARTED" = "1" ]; then
    echo "    PHP-FPM 已重启"
else
    echo "    未能自动重启，请手动重启 PHP-FPM（宝塔：服务 → PHP 设置 → 重启，或 systemctl restart php-fpm）"
fi

echo "==> 验证 beast 加载..."
if "$PHP_BIN" -m 2>/dev/null | grep -qi beast; then
    echo "    beast 扩展已加载 ✅"
else
    echo "    请重启 PHP-FPM 后执行: $PHP_BIN -m | grep beast 确认加载"
fi

echo
echo "安装完成！接下来："
echo "  1) 配置 .env（数据库/Redis/JWT）"
echo "  2) 配置授权（见 DEPLOY.txt）"
echo "  3) 访问站点完成授权校验"
