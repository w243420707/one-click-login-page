#!/bin/bash

# ============================================
# 一键登录页面部署脚本
# 自动检测依赖 | 开机自启 | 持久化运行
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "\n${BLUE}[$1]${NC} $2"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}   一键登录页面部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# ==================== 系统检测 ====================
log_step "1/6" "检测系统信息..."

OS=$(uname -s)
ARCH=$(uname -m)
log_info "系统: $OS | 架构: $ARCH"

# 检测发行版和包管理器
PKG_MANAGER=""
INSTALL_CMD=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    log_info "发行版: $DISTRO"
fi

# 检测包管理器
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="apt-get install -y"
        UPDATE_CMD="apt-get update"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y"
        UPDATE_CMD="yum makecache"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
        UPDATE_CMD="dnf makecache"
    elif command -v apk &>/dev/null; then
        PKG_MANAGER="apk"
        INSTALL_CMD="apk add"
        UPDATE_CMD="apk update"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="pacman -S --noconfirm"
        UPDATE_CMD="pacman -Sy"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="zypper install -y"
        UPDATE_CMD="zypper refresh"
    else
        log_error "未检测到支持的包管理器"
        exit 1
    fi
    log_info "包管理器: $PKG_MANAGER"
}

detect_pkg_manager

# ==================== 依赖检测与安装 ====================
log_step "2/6" "检测并安装依赖..."

NEED_UPDATE=false

# 检查命令是否存在
check_and_install() {
    local cmd=$1
    local pkg=$2
    
    if command -v $cmd &>/dev/null; then
        log_info "$cmd 已安装，跳过"
        return 0
    else
        log_warn "$cmd 未安装，正在安装 $pkg..."
        if [ "$NEED_UPDATE" = false ]; then
            $UPDATE_CMD &>/dev/null || true
            NEED_UPDATE=true
        fi
        $INSTALL_CMD $pkg
        if command -v $cmd &>/dev/null; then
            log_info "$cmd 安装成功"
            return 0
        else
            log_error "$cmd 安装失败"
            return 1
        fi
    fi
}

# Python 检测（核心依赖）
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
    log_info "Python3 已安装: $(python3 --version 2>&1)"
elif command -v python &>/dev/null; then
    # 检查是否为 Python 3
    if python --version 2>&1 | grep -q "Python 3"; then
        PYTHON_CMD="python"
        log_info "Python 已安装: $(python --version 2>&1)"
    fi
fi

if [ -z "$PYTHON_CMD" ]; then
    log_warn "Python3 未安装，正在安装..."
    case $PKG_MANAGER in
        apt) $UPDATE_CMD &>/dev/null; $INSTALL_CMD python3 ;;
        yum|dnf) $INSTALL_CMD python3 ;;
        apk) $INSTALL_CMD python3 ;;
        pacman) $INSTALL_CMD python ;;
        zypper) $INSTALL_CMD python3 ;;
    esac
    PYTHON_CMD="python3"
    log_info "Python3 安装完成"
fi

# curl 检测（用于获取 IP）
check_and_install "curl" "curl"

# lsof 检测（用于端口检查，可选）
if ! command -v lsof &>/dev/null; then
    case $PKG_MANAGER in
        apt) $INSTALL_CMD lsof &>/dev/null || true ;;
        yum|dnf) $INSTALL_CMD lsof &>/dev/null || true ;;
        apk) $INSTALL_CMD lsof &>/dev/null || true ;;
        *) true ;;
    esac
fi

# ==================== 创建网站目录 ====================
log_step "3/6" "创建网站目录..."

WEB_DIR="/var/www/login"
if [ -d "$WEB_DIR" ]; then
    log_info "目录已存在: $WEB_DIR"
else
    mkdir -p $WEB_DIR
    log_info "目录已创建: $WEB_DIR"
fi

# ==================== 创建登录页面 ====================
log_step "4/6" "创建登录页面..."

cat > $WEB_DIR/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户登录</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        .login-box {
            background: rgba(255, 255, 255, 0.95);
            padding: 40px;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            width: 100%;
            max-width: 400px;
            margin: 20px;
        }
        .login-box h1 {
            text-align: center;
            color: #333;
            margin-bottom: 30px;
            font-size: 28px;
            font-weight: 600;
        }
        .input-group { margin-bottom: 20px; }
        .input-group label {
            display: block;
            margin-bottom: 8px;
            color: #555;
            font-weight: 500;
        }
        .input-group input {
            width: 100%;
            padding: 14px 16px;
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            font-size: 16px;
            transition: all 0.3s ease;
        }
        .input-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        }
        .login-btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .login-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }
        .login-btn:active { transform: translateY(0); }
        .links {
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
        }
        .links a {
            color: #667eea;
            text-decoration: none;
            font-size: 14px;
        }
        .links a:hover { text-decoration: underline; }
        .error-msg {
            display: none;
            background: #fee2e2;
            border: 1px solid #fecaca;
            color: #dc2626;
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
            font-size: 14px;
            animation: shake 0.5s ease-in-out;
        }
        .error-msg.show { display: block; }
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            20%, 60% { transform: translateX(-5px); }
            40%, 80% { transform: translateX(5px); }
        }
    </style>
</head>
<body>
    <div class="login-box">
        <h1>用户登录</h1>
        <div class="error-msg" id="errorMsg">账户不存在，请检查用户名后重试</div>
        <form id="loginForm">
            <div class="input-group">
                <label for="username">用户名</label>
                <input type="text" id="username" placeholder="请输入用户名" required>
            </div>
            <div class="input-group">
                <label for="password">密码</label>
                <input type="password" id="password" placeholder="请输入密码" required>
            </div>
            <button type="submit" class="login-btn">登 录</button>
        </form>
        <div class="links">
            <a href="#">忘记密码？</a>
            <a href="#">注册账号</a>
        </div>
    </div>
    <script>
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            e.preventDefault();
            var errorMsg = document.getElementById('errorMsg');
            errorMsg.classList.remove('show');
            void errorMsg.offsetWidth;
            errorMsg.classList.add('show');
        });
    </script>
</body>
</html>
EOF
log_info "登录页面已创建"

# ==================== 释放 80 端口 ====================
log_step "5/6" "检查并释放 80 端口..."

# 停止已存在的 login-page 服务（只停止本脚本创建的服务）
if systemctl is-active --quiet login-page 2>/dev/null; then
    systemctl stop login-page
    log_info "已停止旧的 login-page 服务"
fi

# 检查 80 端口是否被占用
PORT_IN_USE=false
if command -v ss &>/dev/null && ss -tuln | grep -q ':80 '; then
    PORT_IN_USE=true
elif command -v netstat &>/dev/null && netstat -tuln | grep -q ':80 '; then
    PORT_IN_USE=true
fi

if [ "$PORT_IN_USE" = true ]; then
    log_warn "80 端口被占用，请手动释放后重新运行脚本"
    log_warn "查看占用进程: lsof -i:80 或 ss -tuln | grep :80"
    log_warn "如果是 nginx/apache，可使用: systemctl stop nginx"
    # 不自动杀死进程，避免影响用户的其他服务
else
    log_info "80 端口可用"
fi

# 配置 iptables 允许 80 端口入站（仅添加规则，不保存/持久化）
log_info "配置防火墙规则..."

# 检查是否存在 REJECT 规则（常见于 Oracle Cloud 等）
if iptables -L INPUT -n --line-numbers 2>/dev/null | grep -q "REJECT"; then
    # 获取 REJECT 规则的行号
    REJECT_LINE=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep "REJECT" | head -1 | awk '{print $1}')
    
    # 检查 80 端口规则是否已存在
    if ! iptables -L INPUT -n 2>/dev/null | grep -q "dpt:80"; then
        # 在 REJECT 规则之前插入 80 端口规则
        iptables -I INPUT $REJECT_LINE -p tcp --dport 80 -m state --state NEW -j ACCEPT 2>/dev/null && \
            log_info "iptables 规则已添加（在 REJECT 之前）"
    else
        log_info "iptables 80 端口规则已存在"
    fi
else
    # 没有 REJECT 规则，直接添加 ACCEPT 规则
    if ! iptables -L INPUT -n 2>/dev/null | grep -q "dpt:80"; then
        iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT 2>/dev/null && \
            log_info "iptables 规则已添加"
    else
        log_info "iptables 80 端口规则已存在"
    fi
fi

# NOTE: 不保存 iptables 规则，避免影响用户的其他端口配置
# 如需持久化 80 端口规则，用户可手动执行: iptables-save > /etc/iptables/rules.v4
log_info "提示: 80 端口规则已添加到运行时，如需持久化请手动保存"

# ==================== 配置持久化服务 ====================
log_step "6/6" "配置开机自启服务..."

# 创建启动脚本
cat > /usr/local/bin/login-server << SCRIPT
#!/bin/bash
cd $WEB_DIR
exec $PYTHON_CMD -m http.server 80 --bind 0.0.0.0
SCRIPT
chmod +x /usr/local/bin/login-server
log_info "启动脚本已创建: /usr/local/bin/login-server"

# 检测 init 系统
if command -v systemctl &>/dev/null && [ -d /etc/systemd/system ]; then
    # systemd 系统
    cat > /etc/systemd/system/login-page.service << SERVICE
[Unit]
Description=Login Page Web Server
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/login-server
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable login-page
    systemctl start login-page
    log_info "systemd 服务已配置并启动"
    
elif [ -d /etc/init.d ]; then
    # SysVinit 系统
    cat > /etc/init.d/login-page << 'INITSCRIPT'
#!/bin/bash
### BEGIN INIT INFO
# Provides:          login-page
# Required-Start:    $network $remote_fs
# Required-Stop:     $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Login Page Web Server
### END INIT INFO

PIDFILE=/var/run/login-page.pid

case "$1" in
    start)
        echo "Starting login-page..."
        nohup /usr/local/bin/login-server > /var/log/login-page.log 2>&1 &
        echo $! > $PIDFILE
        ;;
    stop)
        echo "Stopping login-page..."
        [ -f $PIDFILE ] && kill $(cat $PIDFILE) && rm -f $PIDFILE
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    status)
        [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null && echo "Running" || echo "Stopped"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
INITSCRIPT
    chmod +x /etc/init.d/login-page
    
    # 添加到开机启动
    if command -v update-rc.d &>/dev/null; then
        update-rc.d login-page defaults
    elif command -v chkconfig &>/dev/null; then
        chkconfig --add login-page
        chkconfig login-page on
    fi
    
    /etc/init.d/login-page start
    log_info "SysVinit 服务已配置并启动"
    
else
    # 无 init 系统，使用 rc.local
    RCLOCAL=""
    [ -f /etc/rc.local ] && RCLOCAL="/etc/rc.local"
    [ -f /etc/rc.d/rc.local ] && RCLOCAL="/etc/rc.d/rc.local"
    
    if [ -n "$RCLOCAL" ]; then
        if ! grep -q "login-server" "$RCLOCAL"; then
            sed -i '/^exit 0/d' "$RCLOCAL" 2>/dev/null || true
            echo "/usr/local/bin/login-server &" >> "$RCLOCAL"
            echo "exit 0" >> "$RCLOCAL"
            chmod +x "$RCLOCAL"
        fi
    fi
    
    # 直接启动
    nohup /usr/local/bin/login-server > /var/log/login-page.log 2>&1 &
    log_info "服务已通过 rc.local 配置并启动"
fi

# ==================== 完成 ====================
sleep 1

# 获取 IP 地址
IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || \
     curl -s --connect-timeout 5 ip.sb 2>/dev/null || \
     curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || \
     hostname -I 2>/dev/null | awk '{print $1}')

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}   ✓ 部署完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "\n  ${GREEN}访问地址:${NC} http://$IP"
echo -e "\n  ${YELLOW}服务管理:${NC}"
echo -e "    启动: systemctl start login-page"
echo -e "    停止: systemctl stop login-page"
echo -e "    重启: systemctl restart login-page"
echo -e "    状态: systemctl status login-page"
echo -e "\n  ${YELLOW}配置文件:${NC}"
echo -e "    网页: $WEB_DIR/index.html"
echo -e "    启动脚本: /usr/local/bin/login-server"
echo -e "    服务配置: /etc/systemd/system/login-page.service"
echo -e "\n  ${GREEN}✓ 已配置开机自动启动${NC}"
echo -e "\n"
