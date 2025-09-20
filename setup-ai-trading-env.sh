#!/bin/bash
# setup-ai-trading-env.sh - 一鍵安裝腳本

set -e
clear

echo "🚀 AI 量化交易開發環境安裝程式"
echo "================================="
echo ""

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查是否為 Ubuntu
check_ubuntu() {
    if [[ ! -f /etc/lsb-release ]]; then
        log_error "此腳本僅支援 Ubuntu 系統"
        exit 1
    fi
    
    UBUNTU_VERSION=$(lsb_release -rs)
    log_info "檢測到 Ubuntu $UBUNTU_VERSION"
    
    if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "20.04" ]]; then
        log_warning "建議使用 Ubuntu 22.04 LTS 或 20.04 LTS"
    fi
}

# 更新系統
update_system() {
    log_info "更新系統套件..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    log_success "系統更新完成"
}

# 安裝 Cursor IDE
install_cursor() {
    log_info "安裝 Cursor IDE..."
    
    # 下載 Cursor
    if ! command -v cursor &> /dev/null; then
        wget -qO- https://download.todesktop.com/210313leapz2w/linux | tar -xz
        sudo mv cursor-*/cursor /usr/local/bin/
        sudo chmod +x /usr/local/bin/cursor
        
        # 創建桌面快捷方式
        cat > ~/.local/share/applications/cursor.desktop << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-first Code Editor
Exec=/usr/local/bin/cursor %F
Icon=cursor
Terminal=false
Type=Application
Categories=Development;TextEditor;
StartupWMClass=cursor
EOF
        
        log_success "Cursor IDE 安裝完成"
    else
        log_success "Cursor IDE 已安裝"
    fi
}

# 安裝 Docker
install_docker() {
    log_info "安裝 Docker..."
    
    if ! command -v docker &> /dev/null; then
        # 移除舊版本
        sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # 添加 Docker 官方 GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # 添加 Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # 安裝 Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # 將用戶加入 docker 群組
        sudo usermod -aG docker $USER
        
        # 啟動 Docker 服務
        sudo systemctl start docker
        sudo systemctl enable docker
        
        log_success "Docker 安裝完成"
    else
        log_success "Docker 已安裝"
    fi
}

# 安裝 Docker Compose
install_docker_compose() {
    log_info "安裝 Docker Compose..."
    
    if ! command -v docker-compose &> /dev/null; then
        # 下載最新版本的 Docker Compose
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        log_success "Docker Compose 安裝完成"
    else
        log_success "Docker Compose 已安裝"
    fi
}

# 安裝 Python 和 uv
install_python_uv() {
    log_info "安裝 Python 環境和 uv..."
    
    # 安裝 Python 3.11
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt update
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
    
    # 設置 Python 3.11 為預設
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
    
    # 安裝 uv (超快的 Python 包管理器)
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.cargo/bin:$PATH"
        log_success "uv 安裝完成"
    else
        log_success "uv 已安裝"
    fi
}

# 安裝 Node.js 和 pnpm
install_nodejs() {
    log_info "安裝 Node.js 和 pnpm..."
    
    # 安裝 Node.js 20 LTS
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # 安裝 pnpm
    if ! command -v pnpm &> /dev/null; then
        npm install -g pnpm
        log_success "pnpm 安裝完成"
    else
        log_success "pnpm 已安裝"
    fi
}

# 創建專案目錄結構
create_project_structure() {
    log_info "創建專案目錄結構..."
    
    # 創建主要專案目錄
    mkdir -p ~/ai-quant-trading
    cd ~/ai-quant-trading
    
    # 創建子目錄
    mkdir -p {
        trading-engine/{strategies,core,tests},
        backtest-engine/{backtester,performance,tests},
        data-collector/{collectors,processors,tests},
        risk-manager/{rules,monitors,tests},
        dashboard/{components,pages,hooks,utils},
        content-engine/{generators,publishers,templates},
        rss-generator/{feeds,templates},
        api-gateway/{routes,middleware,models},
        monitoring/{prometheus,grafana,dashboards},
        docs/{api,deployment,strategies},
        scripts/{deployment,backup,maintenance},
        .devcontainer,
        .github/workflows,
        data/{market,backtest,logs},
        config/{development,production,testing}
    }
    
    log_success "專案目錄結構創建完成"
}

# 創建 Dev Container 配置
create_devcontainer() {
    log_info "創建 Dev Container 配置..."
    
    cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "AI Quantitative Trading Environment",
  "image": "python:3.11-slim",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20",
      "nodeGypDependencies": true
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.black-formatter", 
        "charliermarsh.ruff",
        "ms-toolsai.jupyter",
        "ms-vscode.vscode-docker",
        "bradlc.vscode-tailwindcss",
        "ms-vscode.vscode-json",
        "redhat.vscode-yaml",
        "ms-vscode-remote.remote-containers"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "python.formatting.provider": "none",
        "[python]": {
          "editor.defaultFormatter": "ms-python.black-formatter",
          "editor.formatOnSave": true,
          "editor.codeActionsOnSave": {
            "source.organizeImports": true
          }
        },
        "python.linting.enabled": true,
        "python.linting.ruffEnabled": true
      }
    }
  },
  "postCreateCommand": "pip install uv && uv pip install -r requirements.txt && npm install",
  "remoteUser": "vscode",
  "mounts": [
    "source=${localWorkspaceFolder}/data,target=/workspace/data,type=bind",
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],
  "forwardPorts": [3000, 5000, 8000, 8080],
  "portsAttributes": {
    "3000": {"label": "Frontend"},
    "5000": {"label": "API Gateway"},
    "8000": {"label": "Trading Engine"},
    "8080": {"label": "Monitoring"}
  }
}
EOF

    log_success "Dev Container 配置創建完成"
}

# 創建 Python 專案配置
create_python_config() {
    log_info "創建 Python 專案配置..."
    
    cat > pyproject.toml << 'EOF'
[project]
name = "ai-quant-trading"
version = "0.1.0" 
description = "AI-powered quantitative trading system"
authors = [{name = "Your Name", email = "your.email@example.com"}]
readme = "README.md"
requires-python = ">=3.11"
license = {text = "MIT"}

dependencies = [
    # 量化交易核心
    "ccxt>=4.0.0",
    "pandas>=2.0.0",
    "numpy>=1.24.0",
    "ta-lib>=0.4.0",
    "yfinance>=0.2.0",
    
    # AI/ML 框架
    "scikit-learn>=1.3.0",
    "torch>=2.0.0", 
    "transformers>=4.30.0",
    "openai>=1.0.0",
    
    # API 和後端
    "fastapi>=0.100.0",
    "uvicorn[standard]>=0.23.0",
    "pydantic>=2.0.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.11.0",
    
    # 資料庫和快取
    "asyncpg>=0.28.0",
    "redis>=4.6.0",
    "supabase>=1.0.0",
    
    # 數據處理和分析
    "polars>=0.18.0",
    "plotly>=5.15.0",
    "streamlit>=1.25.0",
    "jupyter>=1.0.0",
    
    # HTTP 客戶端
    "httpx>=0.24.0",
    "aiohttp>=3.8.0",
    
    # 任務排程和背景作業
    "celery>=5.3.0",
    "apscheduler>=3.10.0",
    
    # 工具和輔助
    "python-dotenv>=1.0.0",
    "loguru>=0.7.0",
    "typer>=0.9.0",
    "rich>=13.4.0",
    
    # 內容生成和推播
    "feedgen>=0.9.0",
    "google-api-python-client>=2.90.0",
    "spotipy>=2.23.0",
    "tweepy>=4.14.0"
]

[tool.uv]
dev-dependencies = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",
    "black>=23.0.0",
    "ruff>=0.0.280", 
    "mypy>=1.5.0",
    "pre-commit>=3.3.0"
]

[tool.black]
line-length = 88
target-version = ['py311']

[tool.ruff]
target-version = "py311"
line-length = 88
select = ["E", "F", "W", "C90", "I", "N", "UP", "YTT", "S", "BLE", "FBT", "B", "A", "COM", "C4", "DTZ", "T10", "EM", "EXE", "FA", "ISC", "ICN", "G", "INP", "PIE", "T20", "PYI", "PT", "Q", "RSE", "RET", "SLF", "SLOT", "SIM", "TID", "TCH", "INT", "ARG", "PTH", "PGH", "TRY", "FLY", "PERF", "RUF"]
ignore = ["S101", "S104", "S301", "S401", "S403", "S501", "S602", "S603", "S604", "S605", "S607"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
show_error_codes = true
EOF

    log_success "Python 專案配置創建完成"
}

# 創建 Docker 配置
create_docker_config() {
    log_info "創建 Docker 配置..."
    
    # 本地開發 Docker Compose
    cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  # 開發資料庫
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ai_trading_dev
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d

  # Redis 快取
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_dev_data:/data

  # 開發用 API Gateway
  api_gateway:
    build: 
      context: ./api-gateway
      dockerfile: Dockerfile.dev
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://dev_user:dev_password@postgres:5432/ai_trading_dev
      - REDIS_URL=redis://redis:6379
      - DEBUG=true
    volumes:
      - ./api-gateway:/app
      - /app/node_modules
    depends_on:
      - postgres
      - redis

  # 本地 Jupyter Lab
  jupyter:
    build: ./jupyter
    ports:
      - "8888:8888"
    environment:
      - JUPYTER_TOKEN=dev-token
    volumes:
      - ./notebooks:/home/jovyan/work
      - ./data:/home/jovyan/data

volumes:
  postgres_dev_data:
  redis_dev_data:
EOF

    # 主要的 Docker Compose (生產用)
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # 反向代理
  traefik:
    image: traefik:v3.0
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

  # 交易引擎
  trading_engine:
    build: ./trading-engine
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
      - GROK_API_KEY=${GROK_API_KEY}
      - GROQ_API_KEY=${GROQ_API_KEY}
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.trading.rule=Host(\`trading.localhost\`)"
    depends_on:
      - redis

  # 回測引擎  
  backtest_engine:
    build: ./backtest-engine
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./data:/app/data
      - ./results:/app/results

  # 數據收集器
  data_collector:
    build: ./data-collector
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./data:/app/data

  # API 閘道器
  api_gateway:
    build: ./api-gateway
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
      - GROK_API_KEY=${GROK_API_KEY}
      - GROQ_API_KEY=${GROQ_API_KEY}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(\`api.localhost\`)"
    depends_on:
      - redis

  # Dashboard
  dashboard:
    build: ./dashboard
    restart: unless-stopped
    environment:
      - NEXT_PUBLIC_API_URL=http://api.localhost
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(\`dashboard.localhost\`)"

  # Redis
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data

  # 監控
  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(\`monitoring.localhost\`)"

volumes:
  redis_data:
  prometheus_data:
  grafana_data:
EOF

    log_success "Docker 配置創建完成"
}

# 創建環境變數範本
create_env_template() {
    log_info "創建環境變數範本..."
    
    cat > .env.example << 'EOF'
# 資料庫配置
DATABASE_URL=postgresql://username:password@localhost:5432/ai_trading
REDIS_URL=redis://localhost:6379

# API Keys
GROK_API_KEY=your_grok_api_key_here
GROQ_API_KEY=your_groq_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# 交易所 API
BINANCE_API_KEY=your_binance_api_key
BINANCE_SECRET=your_binance_secret_key
COINBASE_API_KEY=your_coinbase_api_key
COINBASE_SECRET=your_coinbase_secret

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key

# 推播平台 API
YOUTUBE_API_KEY=your_youtube_api_key
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
APPLE_CONNECT_KEY=your_apple_connect_key

# 其他服務
SLACK_WEBHOOK_URL=your_slack_webhook
DISCORD_WEBHOOK_URL=your_discord_webhook
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# 應用設定
DEBUG=true
LOG_LEVEL=INFO
ENVIRONMENT=development
SECRET_KEY=your_secret_key_here

# Google Cloud
GOOGLE_CLOUD_PROJECT=your_project_id
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json

# VM 配置
VM_IP=your_vm_ip_address
VM_USER=your_vm_username
EOF

    # 複製為實際使用的 .env
    cp .env.example .env
    
    log_success "環境變數範本創建完成"
}

# 創建 VS Code 配置
create_vscode_config() {
    log_info "創建 VS Code 配置..."
    
    mkdir -p .vscode
    
    # 設定檔
    cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.formatting.provider": "none",
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    },
    "python.linting.enabled": true,
    "python.linting.ruffEnabled": true,
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.pytestArgs": [
        "tests"
    ],
    "files.associations": {
        "*.yml": "yaml",
        "*.yaml": "yaml",
        "Dockerfile*": "dockerfile"
    },
    "editor.rulers": [88],
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/.mypy_cache": true,
        "**/node_modules": true
    },
    "docker.defaultRegistryPath": "",
    "remote.SSH.configFile": "~/.ssh/config"
}
EOF

    # 工作區配置
    cat > ai-quant-trading.code-workspace << 'EOF'
{
    "folders": [
        {
            "name": "Root",
            "path": "."
        },
        {
            "name": "Trading Engine",
            "path": "./trading-engine"
        },
        {
            "name": "Dashboard",
            "path": "./dashboard"
        },
        {
            "name": "Data Collector",
            "path": "./data-collector"
        }
    ],
    "settings": {
        "python.defaultInterpreterPath": "./venv/bin/python"
    },
    "extensions": {
        "recommendations": [
            "ms-python.python",
            "ms-python.black-formatter",
            "charliermarsh.ruff",
            "ms-toolsai.jupyter",
            "ms-vscode.vscode-docker",
            "bradlc.vscode-tailwindcss",
            "ms-vscode-remote.remote-containers"
        ]
    }
}
EOF

    log_success "VS Code 配置創建完成"
}

# 創建初始化腳本
create_scripts() {
    log_info "創建初始化腳本..."
    
    # 開發環境啟動腳本
    cat > scripts/dev-start.sh << 'EOF'
#!/bin/bash
# 啟動開發環境

set -e

echo "🚀 啟動 AI 量化交易開發環境..."

# 檢查 .env 檔案
if [ ! -f .env ]; then
    echo "❌ 找不到 .env 檔案，請先複製 .env.example 並填入正確的配置"
    exit 1
fi

# 啟動開發服務
echo "🐳 啟動 Docker 服務..."
docker-compose -f docker-compose.dev.yml up -d

# 等待服務啟動
echo "⏳ 等待服務啟動..."
sleep 10

# 檢查服務狀態
echo "🔍 檢查服務狀態..."
docker-compose -f docker-compose.dev.yml ps

echo ""
echo "✅ 開發環境已啟動！"
echo "📊 PostgreSQL: localhost:5432"
echo "🔴 Redis: localhost:6379"  
echo "🌐 API Gateway: http://localhost:5000"
echo "📓 Jupyter Lab: http://localhost:8888 (token: dev-token)"
echo ""
echo "💡 使用 'cursor .' 開啟 Cursor IDE"
echo "💡 使用 'docker-compose -f docker-compose.dev.yml logs -f' 查看日誌"
EOF

    # 環境清理腳本
    cat > scripts/dev-stop.sh << 'EOF'
#!/bin/bash
# 停止開發環境

set -e

echo "🛑 停止 AI 量化交易開發環境..."

# 停止所有服務
docker-compose -f docker-compose.dev.yml down

echo "🧹 清理容器和網路..."
docker system prune -f

echo "✅ 開發環境已停止"
EOF

    # 部署到雲端腳本
    cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
# 部署到雲端腳本

set -e

# 檢查必要變數
if [ -z "$VM_IP" ] || [ -z "$VM_USER" ]; then
    echo "❌ 請設定 VM_IP 和 VM_USER 環境變數"
    exit 1
fi

echo "🚀 部署到 Google Cloud VM ($VM_IP)..."

# 同步代碼
echo "📡 同步代碼..."
rsync -avz --progress --delete \
    --exclude '.git' \
    --exclude 'node_modules' \
    --exclude '__pycache__' \
    --exclude '.pytest_cache' \
    --exclude 'venv' \
    --exclude '.env' \
    ./ $VM_USER@$VM_IP:~/ai-quant-trading/

# 遠端部署
echo "🐳 遠端部署..."
ssh $VM_USER@$VM_IP << 'REMOTE_EOF'
cd ~/ai-quant-trading

# 檢查 .env 檔案
if [ ! -f .env ]; then
    echo "請先在 VM 上設定 .env 檔案"
    exit 1
fi

# 停止舊服務
docker-compose down

# 構建並啟動新服務
docker-compose build
docker-compose up -d

# 清理舊映像
docker system prune -f

echo "✅ 雲端部署完成"
REMOTE_EOF

echo "🎉 部署成功！"
echo "🌐 訪問: http://$VM_IP"
EOF

    # 設定腳本執行權限
    chmod +x scripts/*.sh
    
    log_success "初始化腳本創建完成"
}

# 初始化 Python 虛擬環境
setup_python_env() {
    log_info "設定 Python 虛擬環境..."
    
    # 使用 uv 創建虛擬環境
    uv venv venv --python 3.11
    
    # 啟動虛擬環境並安裝依賴
    source venv/bin/activate
    uv pip install -r <(uv pip compile pyproject.toml)
    
    log_success "Python 虛擬環境設定完成"
}

# 創建 README
create_readme() {
    log_info "創建 README 文件..."
    
    cat > README.md << 'EOF'
# 🚀 AI 量化交易系統

一個基於 AI 的量化交易系統，整合多種 AI 模型和交易策略，支援自動化內容推播到多個平台。

## 🏗️ 系統架構

- **本地開發**: Ubuntu + Cursor + Docker + Dev Container + uv
- **雲端運行**: Google Cloud VM + Docker Stack + Traefik Proxy
- **資料庫**: Supabase (PostgreSQL + 即時訂閱)
- **推播平台**: Apple Podcasts + Spotify + YouTube

## 🚀 快速開始

### 本地開發環境

1. **安裝開發環境**
```bash
   curl -fsSL https://raw.githubusercontent.com/your-repo/setup/main/install.sh | bash