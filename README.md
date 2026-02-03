# 一键登录页面部署

一键在 VPS 上部署轻量级登录页面，专为甲骨文云 (Oracle Cloud) 等免费实例设计，防止因闲置被回收。

## ✨ 特性

- 🚀 **一键部署** - 单条命令完成全部安装配置
- 🔍 **智能检测** - 自动识别系统、架构和包管理器
- 📦 **自动安装依赖** - 已安装则跳过，未安装则自动安装
- 🔄 **开机自启** - 支持 systemd / SysVinit / rc.local
- 🔥 **自动配置防火墙** - 自动开放 80 端口 iptables 规则（支持 Oracle Cloud 等）
- 🪶 **极致轻量** - 使用 Python 内置 HTTP 服务器，几乎零负载
- 🎨 **美观界面** - 现代化渐变设计，响应式布局
- 🔒 **登录模拟** - 点击登录显示"账户不存在"，模拟真实登录页面

## 📋 支持的系统

| 发行版 | 包管理器 | 状态 |
|--------|----------|------|
| Ubuntu / Debian | apt | ✅ |
| CentOS / RHEL 7 | yum | ✅ |
| Fedora / RHEL 8+ | dnf | ✅ |
| Alpine | apk | ✅ |
| Arch Linux | pacman | ✅ |
| openSUSE | zypper | ✅ |

支持架构：`x86_64` / `aarch64` / `arm64`

## 🚀 快速开始

### 方式一：在线安装（推荐）

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/w243420707/one-click-login-page/master/install.sh)"
```

### 方式二：手动安装

```bash
# 克隆仓库
git clone https://github.com/w243420707/one-click-login-page.git
cd one-click-login-page

# 运行安装脚本（需要 root 权限）
chmod +x install.sh
sudo ./install.sh
```

## 📁 安装后的文件

| 文件路径 | 说明 |
|----------|------|
| `/var/www/login/index.html` | 登录页面 HTML |
| `/usr/local/bin/login-server` | 启动脚本 |
| `/etc/systemd/system/login-page.service` | systemd 服务配置 |

## 🔧 服务管理

```bash
# 启动服务
sudo systemctl start login-page

# 停止服务
sudo systemctl stop login-page

# 重启服务
sudo systemctl restart login-page

# 查看状态
sudo systemctl status login-page

# 查看日志
sudo journalctl -u login-page -f
```

## 🎨 自定义页面

编辑 `/var/www/login/index.html` 文件即可自定义登录页面样式。

```bash
sudo nano /var/www/login/index.html
```

修改后无需重启服务，刷新浏览器即可生效。

## ❓ 常见问题

### 80 端口被占用怎么办？

脚本会自动尝试释放 80 端口。如果仍有问题，可手动停止占用端口的服务：

```bash
# 查看占用 80 端口的进程
sudo lsof -i:80

# 停止 nginx（如果有）
sudo systemctl stop nginx

# 停止 apache（如果有）
sudo systemctl stop apache2
```

### 访问时显示 502 或无法连接？

脚本已自动配置 iptables 规则。如果仍有问题，请检查云服务商的安全组/安全列表：

- **Oracle Cloud**: 进入 VCN → Security Lists → 添加 Ingress Rule (TCP 80)
- **AWS**: 检查 Security Group 入站规则
- **阿里云/腾讯云**: 检查安全组规则

### 如何卸载？

```bash
# 停止并禁用服务
sudo systemctl stop login-page
sudo systemctl disable login-page

# 删除文件
sudo rm -f /etc/systemd/system/login-page.service
sudo rm -f /usr/local/bin/login-server
sudo rm -rf /var/www/login

# 重载 systemd
sudo systemctl daemon-reload
```

## 📜 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
