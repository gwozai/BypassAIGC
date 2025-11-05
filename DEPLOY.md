# 部署指南

本文档提供生产环境部署和系统服务配置的详细说明。

## 目录

- [系统要求](#系统要求)
- [macOS 部署](#macos-部署)
- [生产环境部署](#生产环境部署)
- [Systemd 服务配置](#systemd-服务配置)
- [Nginx 反向代理](#nginx-反向代理)
- [Docker 部署](#docker-部署)
- [性能优化](#性能优化)
- [监控和日志](#监控和日志)
- [常见问题](#常见问题)

## 系统要求

### 最低配置
- **CPU**: 2 核心
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **操作系统**: Ubuntu 20.04+ / CentOS 8+ / Windows Server 2019+

### 推荐配置
- **CPU**: 4 核心+
- **内存**: 8GB+ RAM
- **存储**: 50GB+ SSD
- **网络**: 100Mbps+

### 软件依赖
- Python 3.10+
- Node.js 16+
- SQLite 3 / PostgreSQL 12+ (推荐生产环境)
- Redis 6+ (可选，用于队列管理)
- Nginx (推荐作为反向代理)

## macOS 部署

### 快速开始

macOS 用户可以使用专门的安装脚本：

```bash
# 1. 克隆项目
git clone https://github.com/chi111i/BypassAIGC.git
cd BypassAIGC

# 2. 添加执行权限
chmod +x setup-macos.sh start-all-macos.sh

# 3. 运行 macOS 安装脚本（会自动安装 Homebrew 和依赖）
./setup-macos.sh

# 4. 配置环境变量
nano backend/.env

# 5. 启动服务
./start-all-macos.sh
```

### macOS 特殊说明

#### 安装 Homebrew (如果尚未安装)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 依赖管理

macOS 脚本会自动通过 Homebrew 安装以下依赖：
- Python 3.11
- Node.js (最新 LTS 版本)
- 其他必要的系统工具

#### 使用 tmux 管理服务 (推荐)

```bash
# 安装 tmux
brew install tmux

# 启动服务（自动使用 tmux）
./start-all-macos.sh

# 查看运行中的会话
tmux ls

# 进入后端会话
tmux attach -t bypassaigc-backend

# 进入前端会话
tmux attach -t bypassaigc-frontend

# 退出会话（不停止服务）
# 按 Ctrl+B 然后按 D

# 停止所有服务
./stop-all.sh
```

#### 使用 launchd 设置开机自启 (macOS 版本的 systemd)

创建后端服务配置 `~/Library/LaunchAgents/com.bypassaigc.backend.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.bypassaigc.backend</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/opt/BypassAIGC/backend/venv/bin/uvicorn</string>
        <string>app.main:app</string>
        <string>--host</string>
        <string>0.0.0.0</string>
        <string>--port</string>
        <string>8000</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>/opt/BypassAIGC/backend</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/opt/BypassAIGC/logs/backend.log</string>
    
    <key>StandardErrorPath</key>
    <string>/opt/BypassAIGC/logs/backend-error.log</string>
</dict>
</plist>
```

创建前端服务配置 `~/Library/LaunchAgents/com.bypassaigc.frontend.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.bypassaigc.frontend</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/npm</string>
        <string>run</string>
        <string>dev</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>/opt/BypassAIGC/frontend</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/opt/BypassAIGC/logs/frontend.log</string>
    
    <key>StandardErrorPath</key>
    <string>/opt/BypassAIGC/logs/frontend-error.log</string>
</dict>
</plist>
```

启用和管理服务：

```bash
# 创建日志目录
mkdir -p /opt/BypassAIGC/logs

# 加载服务
launchctl load ~/Library/LaunchAgents/com.bypassaigc.backend.plist
launchctl load ~/Library/LaunchAgents/com.bypassaigc.frontend.plist

# 启动服务
launchctl start com.bypassaigc.backend
launchctl start com.bypassaigc.frontend

# 查看服务状态
launchctl list | grep bypassaigc

# 停止服务
launchctl stop com.bypassaigc.backend
launchctl stop com.bypassaigc.frontend

# 卸载服务
launchctl unload ~/Library/LaunchAgents/com.bypassaigc.backend.plist
launchctl unload ~/Library/LaunchAgents/com.bypassaigc.frontend.plist
```

#### macOS 防火墙配置

如果启用了防火墙，需要允许 Python 和 Node：

```bash
# 通过系统偏好设置 -> 安全性与隐私 -> 防火墙 -> 防火墙选项
# 添加 Python 和 Node 到允许列表
```

或者使用命令行：

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/python3
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/node
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/python3
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/node
```

#### macOS 常见问题

**Q: 提示 "command not found: python3"**
A: 运行 `brew install python@3.11` 并将其添加到 PATH

**Q: 端口被占用**
A: 使用 `lsof -i :8000` 查看占用进程，使用 `./stop-all.sh` 停止

**Q: npm install 失败**
A: 清除缓存 `npm cache clean --force` 然后重试

**Q: 权限被拒绝**
A: 运行 `chmod +x *.sh` 给所有脚本添加执行权限

## 生产环境部署

### 1. 环境准备

#### Ubuntu/Debian
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装系统依赖
sudo apt install -y python3.10 python3.10-venv python3-pip \
    nodejs npm build-essential git curl

# 安装进程管理工具
sudo apt install -y tmux screen

# 安装 Nginx (可选)
sudo apt install -y nginx
```

#### CentOS/RHEL
```bash
# 更新系统
sudo yum update -y

# 安装 EPEL 仓库
sudo yum install -y epel-release

# 安装系统依赖
sudo yum install -y python3 python3-devel gcc nodejs npm git curl

# 安装 Nginx (可选)
sudo yum install -y nginx
```

### 2. 下载和配置项目

```bash
# 克隆项目
cd /opt
sudo git clone https://github.com/chi111i/BypassAIGC.git
cd BypassAIGC

# 设置权限
sudo chown -R $USER:$USER /opt/BypassAIGC

# 运行安装脚本
chmod +x setup.sh start-backend.sh start-frontend.sh start-all.sh stop-all.sh
./setup.sh
```

### 3. 配置环境变量

编辑 `backend/.env` 文件：

```bash
nano backend/.env
```

**关键配置项：**

```properties
# 生产环境必须修改的配置
SECRET_KEY=<生成强随机密钥>
ADMIN_PASSWORD=<修改默认密码>
OPENAI_API_KEY=<您的API密钥>

# 数据库配置 (推荐使用 PostgreSQL)
DATABASE_URL=postgresql://username:password@localhost/bypassaigc

# Redis 配置 (可选但推荐)
REDIS_URL=redis://localhost:6379/0

# 性能配置
MAX_CONCURRENT_USERS=10
HISTORY_COMPRESSION_THRESHOLD=5000

# 安全配置
ALLOWED_ORIGINS=["https://yourdomain.com"]
```

**生成强随机密钥：**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

### 4. 数据库设置

#### 使用 PostgreSQL (推荐)

```bash
# 安装 PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# 创建数据库和用户
sudo -u postgres psql << EOF
CREATE DATABASE bypassaigc;
CREATE USER bypassuser WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE bypassaigc TO bypassuser;
\q
EOF

# 安装 PostgreSQL Python 驱动
source backend/venv/bin/activate
pip install psycopg2-binary
deactivate
```

#### 使用 SQLite (开发/小规模)

SQLite 会自动创建，无需额外配置。但生产环境建议使用 PostgreSQL。

### 5. Redis 配置 (可选但推荐)

```bash
# 安装 Redis
sudo apt install -y redis-server

# 启动 Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 验证 Redis
redis-cli ping
# 应返回 PONG
```

## Systemd 服务配置

使用 systemd 实现开机自启和服务管理。

### 1. 创建后端服务

创建文件 `/etc/systemd/system/bypassaigc-backend.service`：

```bash
sudo nano /etc/systemd/system/bypassaigc-backend.service
```

内容：

```ini
[Unit]
Description=BypassAIGC Backend Service
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/BypassAIGC/backend
Environment="PATH=/opt/BypassAIGC/backend/venv/bin"

ExecStart=/opt/BypassAIGC/backend/venv/bin/uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 4 \
    --log-level info

Restart=always
RestartSec=10
StandardOutput=append:/var/log/bypassaigc/backend.log
StandardError=append:/var/log/bypassaigc/backend-error.log

[Install]
WantedBy=multi-user.target
```

### 2. 创建前端服务

创建文件 `/etc/systemd/system/bypassaigc-frontend.service`：

```bash
sudo nano /etc/systemd/system/bypassaigc-frontend.service
```

内容：

```ini
[Unit]
Description=BypassAIGC Frontend Service
After=network.target bypassaigc-backend.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/BypassAIGC/frontend

ExecStart=/usr/bin/npm run dev
# 生产环境使用: ExecStart=/usr/bin/npm run start

Restart=always
RestartSec=10
StandardOutput=append:/var/log/bypassaigc/frontend.log
StandardError=append:/var/log/bypassaigc/frontend-error.log

[Install]
WantedBy=multi-user.target
```

### 3. 配置日志目录

```bash
# 创建日志目录
sudo mkdir -p /var/log/bypassaigc
sudo chown www-data:www-data /var/log/bypassaigc

# 配置日志轮转
sudo nano /etc/logrotate.d/bypassaigc
```

日志轮转配置：

```
/var/log/bypassaigc/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    create 0640 www-data www-data
}
```

### 4. 启动和管理服务

```bash
# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start bypassaigc-backend
sudo systemctl start bypassaigc-frontend

# 设置开机自启
sudo systemctl enable bypassaigc-backend
sudo systemctl enable bypassaigc-frontend

# 查看服务状态
sudo systemctl status bypassaigc-backend
sudo systemctl status bypassaigc-frontend

# 查看日志
sudo journalctl -u bypassaigc-backend -f
sudo journalctl -u bypassaigc-frontend -f

# 重启服务
sudo systemctl restart bypassaigc-backend
sudo systemctl restart bypassaigc-frontend

# 停止服务
sudo systemctl stop bypassaigc-backend
sudo systemctl stop bypassaigc-frontend
```

## Nginx 反向代理

### 1. 安装 Nginx

```bash
sudo apt install -y nginx
```

### 2. 配置 Nginx

创建配置文件 `/etc/nginx/sites-available/bypassaigc`：

```bash
sudo nano /etc/nginx/sites-available/bypassaigc
```

配置内容：

```nginx
# 限制请求速率
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# 后端服务
upstream backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

# 前端服务
upstream frontend {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL 配置 (推荐使用 Let's Encrypt)
    # listen 443 ssl http2;
    # ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    client_max_body_size 10M;
    
    # 日志
    access_log /var/log/nginx/bypassaigc-access.log;
    error_log /var/log/nginx/bypassaigc-error.log;
    
    # 前端
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
    }
    
    # 后端 API
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
        
        proxy_pass http://backend/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 10s;
    }
    
    # WebSocket 支持
    location /ws/ {
        proxy_pass http://backend/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf)$ {
        proxy_pass http://frontend;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}

# HTTP 重定向到 HTTPS
# server {
#     listen 80;
#     server_name yourdomain.com www.yourdomain.com;
#     return 301 https://$server_name$request_uri;
# }
```

### 3. 启用配置

```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/bypassaigc /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 4. 配置 SSL (推荐使用 Let's Encrypt)

```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# 自动续期
sudo systemctl enable certbot.timer
```

## Docker 部署

### 1. 创建 Dockerfile (后端)

创建 `backend/Dockerfile`：

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### 2. 创建 Dockerfile (前端)

创建 `frontend/Dockerfile`：

```dockerfile
FROM node:16-alpine

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制应用代码
COPY . .

# 构建应用
RUN npm run build

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["npm", "run", "start"]
```

### 3. 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    container_name: bypassaigc-db
    environment:
      POSTGRES_DB: bypassaigc
      POSTGRES_USER: bypassuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - bypassaigc-network
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: bypassaigc-redis
    networks:
      - bypassaigc-network
    restart: unless-stopped

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: bypassaigc-backend
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://bypassuser:${DB_PASSWORD}@postgres/bypassaigc
      REDIS_URL: redis://redis:6379/0
    env_file:
      - backend/.env
    ports:
      - "8000:8000"
    networks:
      - bypassaigc-network
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: bypassaigc-frontend
    depends_on:
      - backend
    ports:
      - "3000:3000"
    networks:
      - bypassaigc-network
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  bypassaigc-network:
    driver: bridge
```

### 4. 使用 Docker Compose

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 完全清理（包括数据）
docker-compose down -v
```

## 性能优化

### 1. 后端优化

#### Uvicorn Workers 配置
```bash
# 根据 CPU 核心数调整 workers
uvicorn app.main:app --workers $(nproc) --host 0.0.0.0 --port 8000
```

#### 数据库连接池
在 `backend/.env` 中配置：
```properties
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10
```

### 2. 前端优化

#### 生产构建
```bash
cd frontend
npm run build
npm run start
```

#### CDN 加速
将静态资源部署到 CDN，修改前端配置。

### 3. 系统优化

#### 文件描述符限制
```bash
# 编辑 /etc/security/limits.conf
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
```

#### TCP 优化
```bash
# 编辑 /etc/sysctl.conf
sudo tee -a /etc/sysctl.conf << EOF
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_tw_reuse = 1
EOF

sudo sysctl -p
```

## 监控和日志

### 1. 应用监控

#### 健康检查端点
后端提供健康检查 API：
- `http://localhost:8000/health` - 基本健康检查
- `http://localhost:8000/api/metrics` - 性能指标

#### 监控脚本示例
```bash
#!/bin/bash
# 创建 /opt/BypassAIGC/monitor.sh

while true; do
    if ! curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "Backend is down! Restarting..."
        systemctl restart bypassaigc-backend
    fi
    sleep 60
done
```

### 2. 日志管理

#### 查看实时日志
```bash
# Systemd 日志
sudo journalctl -u bypassaigc-backend -f

# 应用日志
tail -f /var/log/bypassaigc/backend.log
```

#### 日志分析
```bash
# 错误统计
grep "ERROR" /var/log/bypassaigc/backend.log | wc -l

# 最近的错误
tail -n 100 /var/log/bypassaigc/backend-error.log
```

## 备份和恢复

### 数据库备份

#### SQLite
```bash
# 备份
sqlite3 backend/ai_polish.db ".backup backup-$(date +%Y%m%d).db"

# 恢复
cp backup-20241105.db backend/ai_polish.db
```

#### PostgreSQL
```bash
# 备份
pg_dump -U bypassuser bypassaigc > backup-$(date +%Y%m%d).sql

# 恢复
psql -U bypassuser bypassaigc < backup-20241105.sql
```

### 自动备份脚本
```bash
#!/bin/bash
# /opt/BypassAIGC/backup.sh

BACKUP_DIR="/backup/bypassaigc"
DATE=$(date +%Y%m%d)

mkdir -p $BACKUP_DIR

# 备份数据库
sqlite3 /opt/BypassAIGC/backend/ai_polish.db ".backup $BACKUP_DIR/db-$DATE.db"

# 备份配置
cp /opt/BypassAIGC/backend/.env $BACKUP_DIR/env-$DATE.bak

# 删除7天前的备份
find $BACKUP_DIR -name "*.db" -mtime +7 -delete

echo "Backup completed: $DATE"
```

添加到 crontab：
```bash
# 每天凌晨2点执行备份
0 2 * * * /opt/BypassAIGC/backup.sh >> /var/log/bypassaigc/backup.log 2>&1
```

## 安全建议

1. **修改默认凭证**
   - 修改 `.env` 中的 `ADMIN_PASSWORD`
   - 生成强 `SECRET_KEY`

2. **使用 HTTPS**
   - 配置 SSL 证书
   - 强制 HTTPS 重定向

3. **防火墙配置**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

4. **定期更新**
   ```bash
   cd /opt/BypassAIGC
   git pull
   ./setup.sh
   sudo systemctl restart bypassaigc-backend bypassaigc-frontend
   ```

5. **限制 API 访问**
   - 在 Nginx 中配置速率限制
   - 使用 IP 白名单

## 常见问题

### Q: 服务无法启动？
**A:** 检查日志：
```bash
sudo journalctl -u bypassaigc-backend -n 50
sudo systemctl status bypassaigc-backend
```

### Q: 端口被占用？
**A:** 查找并停止占用进程：
```bash
sudo lsof -i :8000
sudo kill -9 <PID>
```

### Q: 数据库连接失败？
**A:** 检查：
1. PostgreSQL 服务是否运行
2. 连接字符串是否正确
3. 用户权限是否足够

### Q: 内存不足？
**A:** 优化配置：
1. 减少 `MAX_CONCURRENT_USERS`
2. 减少 Uvicorn workers 数量
3. 配置 swap 空间

### Q: 性能问题？
**A:** 
1. 启用 Redis 缓存
2. 使用 PostgreSQL 替代 SQLite
3. 配置 Nginx 缓存
4. 增加服务器资源

## 技术支持

如遇到问题，请：
1. 查看日志文件
2. 检查系统资源
3. 参考 GitHub Issues
4. 提交详细的错误报告

---

**文档版本**: 1.0  
**最后更新**: 2024-11-05
