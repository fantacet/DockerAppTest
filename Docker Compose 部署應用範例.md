這是一個完整的範例，展示了 **Vue3 + TypeScript (Vite) 前端 + ASP.NET (.NET 9) Web API + Postgres + Nginx** 的 Docker Compose 架構。此設定可直接在任何安裝了 Docker 的 Linux、Windows 或 macOS 上運行。


## ---

**1\. 專案目錄結構**

```
my-app/
├── api/                  # ASP.NET Web API (.NET 9) + EF Core
│   ├── Dockerfile
│   ├── Program.cs
│   ├── Api.csproj
│   ├── Data/AppDbContext.cs
│   ├── Models/Visit.cs
│   └── Migrations/
├── frontend/             # Vue 3 + TypeScript (Vite) + PrimeVue
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
│       ├── api/          # API 呼叫層 (Axios)
│       ├── components/   # 共用元件 (如 AppLayout.vue)
│       ├── router/       # Vue Router 路由設定
│       ├── stores/       # Pinia 狀態管理
│       ├── views/        # 頁面元件 (如 DashboardView.vue, HealthView.vue)
│       ├── App.vue
│       └── main.ts
├── nginx/
│   └── nginx.conf        # 靜態前端 + /api/ 反代
├── .env
└── docker-compose.yml
```

## ---

**2\. 各組件說明**

### 🔹 後端：ASP.NET Web API (api/)

使用 .NET 9 + EF Core + Npgsql 連接 Postgres。

**API Endpoints：**

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/health` | 健康檢查，回傳 `{ status, version }` |
| POST | `/api/visits?lang=zh-TW\|en` | 新增訪問、回傳 `{ message, db_stats, count, version, lang }` |
| GET | `/api/visits/count` | 查詢總訪問次數 `{ count }` |

**api/Dockerfile：** 使用 `mcr.microsoft.com/dotnet/sdk:9.0` 建置，`mcr.microsoft.com/dotnet/aspnet:9.0` 執行。

### ---

### 🔹 前端：Vue3 + TypeScript (frontend/)

使用 Vite 建置，並以 PrimeVue 4 做為企業級 UI 元件庫，結合 Vue Router 4 管理路由，以及 Pinia 進行狀態管理（如使用者登入態），最終輸出靜態檔案到 `dist/`，由 Docker volume 傳遞給 nginx。

**frontend/Dockerfile：** 使用 `node:lts-alpine` 執行 `npm ci && npm run build`（依賴包含 `vue-router`, `pinia`, `primevue`, `axios` 等），再將 dist 複製到共享 Volume。

### ---

### 🔹 代理伺服器：Nginx (nginx/)

- `/api/` → 反代到 `api:8080`
- `/` → 靜態檔案（支援 Vue Router history mode）

**nginx/nginx.conf**

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location /api/ {
        proxy_pass http://api:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### ---

### 🔹 總指揮：Docker Compose

**docker-compose.yml**

```yaml
services:
  db:       # postgres:15
  api:      # .NET 9 Web API (build ./api)
  frontend: # Vue3 build container (dist → volume)
  nginx:    # nginx:alpine (靜態 + /api/ 反代)

volumes:
  postgres_data:
  frontend_dist:
```

## ---

**3\. 如何執行佈署？**

1. 進入 `my-app` 資料夾：
   ```bash
   cd my-app
   ```
2. 執行：
   ```bash
   docker compose up --build -d
   ```
3. 打開瀏覽器，輸入 `http://localhost:8080`。

### 測試 API：
```bash
# 健康檢查
curl http://localhost:8080/api/health

# 新增訪問（繁體中文）
curl -X POST http://localhost:8080/api/visits

# 新增訪問（英文）
curl -X POST "http://localhost:8080/api/visits?lang=en"

# 查詢總次數
curl http://localhost:8080/api/visits/count
```

## ---

**4\. 環境變數 (.env)**

```dotenv
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=testdb
DB_HOST=db
APP_VERSION=1.0.0
NGINX_PORT=8080
```

## ---

**5\. Host 地端佈署必要條件**

1. **硬體資源**：至少 1GB 以上的可用記憶體（建議 2GB 以上）。
2. **軟體環境**：
   - **Linux 主機**：推薦直接安裝原生 Docker Engine 與 Docker Compose 插件。
   - **Windows 主機**：建議啟用 **WSL2** 並在其中安裝 Linux 版的 Docker Engine。
3. **專案配置**：必須準備好 `.env` 環境變數檔。

> 詳細操作步驟請參閱 `my-app/TEST_GUIDE.md`。