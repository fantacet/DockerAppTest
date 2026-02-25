# Docker Compose 測試操作說明指南

> **注意：** 本專案已從 Flask + Python 架構改造為 **Vue3 + TypeScript (Vite) 前端 + ASP.NET (.NET 9) Web API + Postgres + Nginx** 架構。

## 目錄結構

```
my-flask-app/
├── api/                  # ASP.NET Web API (.NET 9)
│   ├── Dockerfile
│   ├── Program.cs
│   ├── Api.csproj
│   ├── Data/
│   │   └── AppDbContext.cs
│   ├── Models/
│   │   └── Visit.cs
│   ├── Migrations/
│   └── appsettings.json
├── frontend/             # Vue3 + TypeScript (Vite)
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── index.html
│   └── src/
│       ├── main.ts
│       └── App.vue
├── nginx/
│   └── nginx.conf        # 靜態檔案 + /api/ 反代
├── .env
└── docker-compose.yml
```

## 1. 部署環境建置 (Windows WSL2 安裝 Docker Engine)

若您的 Host 為 Windows 系統，為求輕量化且不依賴 Docker Desktop，請依照以下步驟在 WSL2 內安裝原生 Docker Engine：

### 步驟一：啟用並安裝 WSL2 (Ubuntu)
1. 以「系統管理員」身分開啟 PowerShell。
2. 執行以下指令安裝預設的 Ubuntu 發行版：
   ```powershell
   wsl --install
   ```
3. 安裝完成後，請重新開機主機。
4. 重新開機後，開啟「Ubuntu」應用程式，設定您的 UNIX 帳號與密碼。

### 步驟二：在 Ubuntu 中安裝 Docker Engine
在 Ubuntu 的終端機內依序執行以下指令：
```bash
# 1. 更新套件庫並安裝依賴
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

# 2. 加入 Docker 官方 GPG Key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. 設定 repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. 安裝 Docker Engine 與 Compose
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. 將目前使用者加入 docker 群組，避免每次都要加 sudo
sudo usermod -aG docker $USER
```
*(設定完群組後，請關閉該 Ubuntu 終端機並重新開啟)*

### 步驟三：啟動 Docker 服務
```bash
sudo service docker start
```

---

## 2. 環境變數設定 (.env)

`.env` 檔案位於 `my-flask-app/`，包含以下設定：

```dotenv
# Database Configuration
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=testdb
DB_HOST=db

# App Configuration
APP_VERSION=1.0.0

# Nginx Configuration
NGINX_PORT=8080
```

---

## 3. 快速開始

### 部署並啟動服務
```bash
cd my-flask-app
docker compose up --build -d
```

- 自動讀取 `.env` 設定
- 建立並啟動：`db`（Postgres）、`api`（.NET 9）、`frontend`（build-only）、`nginx`
- `frontend` service 完成 build 後將 `dist/` 複製到共享 volume，再由 `nginx` 提供靜態檔案

### 停止並移除服務
```bash
docker compose down
```

### 停止並完整清除資料（含資料庫 Volume）
```bash
docker compose down -v
```

---

## 4. 功能測試說明

### A. 瀏覽頁面
開啟瀏覽器，進入 `http://localhost:8080`，可看到 Vue3 前端頁面：
- 顯示歡迎訊息、資料庫存取次數、應用程式版本
- 點選「記錄訪問」按鈕，呼叫 `POST /api/visits`，次數累計
- 點選語系切換按鈕，在繁體中文與英文之間切換

### B. API 健康檢查
```bash
curl http://localhost:8080/api/health
# 回應：{"status":"healthy","version":"1.0.0"}
```

### C. 新增訪問紀錄（繁體中文）
```bash
curl -X POST http://localhost:8080/api/visits
# 回應：{"message":"Hello! 這是來自 Docker 的 .NET 應用。","db_stats":"資料庫已累計存取 1 次。","count":1,"version":"1.0.0","lang":"zh-TW"}
```

### D. 新增訪問紀錄（英文）
```bash
curl -X POST "http://localhost:8080/api/visits?lang=en"
# 回應：{"message":"Hello! This is a .NET app from Docker.","db_stats":"Database access count: 2.","count":2,"version":"1.0.0","lang":"en"}
```

### E. 查詢訪問次數
```bash
curl http://localhost:8080/api/visits/count
# 回應：{"count":2}
```

### F. 多語系支援
`lang` query parameter 支援 `zh-TW`（預設）與 `en`，其他值自動回落 `zh-TW`。

### G. 資源使用狀況
```bash
docker stats
```

---

## 5. 架構說明

| Service    | Image / Build         | 說明                                      |
|------------|----------------------|------------------------------------------|
| `db`       | `postgres:15`         | Postgres 資料庫，使用 Volume 持久化資料     |
| `api`      | `./api` (build)       | ASP.NET Web API (.NET 9)，EF Core Migrations，監聽 8080（僅 container 內） |
| `frontend` | `./frontend` (build)  | Vue3+TS build container，dist 複製到共享 Volume |
| `nginx`    | `nginx:alpine`        | 靜態檔案 + `/api/` 反代到 `api:8080`，對外 Port: `NGINX_PORT` |

---

## 6. 軟體更新與版本控制

1. 修改程式碼（`api/` 或 `frontend/src/`）。
2. 更新 `.env` 中的 `APP_VERSION`。
3. 重新構建與啟動：
   ```bash
   docker compose up --build -d
   ```
4. 驗證：存取 `http://localhost:8080/api/health` 確認版本已更新。

---

## 7. 故障排除

- **查看即時日誌**：`docker compose logs -f`
- **只看 API 日誌**：`docker compose logs -f api`
- **進入 API 容器**：`docker compose exec api sh`
- **進入 DB 容器**：`docker compose exec db psql -U user -d testdb`

