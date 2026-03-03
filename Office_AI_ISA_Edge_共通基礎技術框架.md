

# Office AI / ISA Edge 共通基礎技術框架

基於團隊現有技術背景（WebForm + jQuery + Helper/DAO）和「精簡但現代」的目標，以下是建議：

---

## 一、整體解決方案結構

```
/ais-platform                          ← Git Monorepo (GitLab)
│
├── /src
│   ├── /Common                        ← 共用程式庫（以 ProjectReference 引用，不另發 NuGet）
│   │   ├── AIS.Common.Auth            ← 帳號/RBAC/JWT/LDAP
│   │   ├── AIS.Common.Data            ← EF Core DbContext 基底、Repository 基底
│   │   ├── AIS.Common.Audit           ← 審計日誌
│   │   ├── AIS.Common.Health          ← 健康檢查、裝置資訊
│   │   ├── AIS.Common.Licensing       ← 授權驗證
│   │   ├── AIS.Common.Notification    ← 通知（Email/LINE/Teams）
│   │   ├── AIS.Common.Update          ← 更新包驗證與部署
│   │   └── AIS.Common.Contracts       ← 共用 DTO / API 契約介面
│   │
│   ├── /Modules                       ← 業務模組程式庫（不直接部署，被 App 引用）
│   │   ├── AIS.Module.Identity        ← 帳號管理（Controller + Service + Repository）
│   │   ├── AIS.Module.Admin           ← 系統管理（網路/備份/診斷/授權）
│   │   ├── AIS.Module.PackageRecog    ← [Office AI 專屬] 包裹辨識
│   │   ├── AIS.Module.ExpenseRecog    ← [Office AI 專屬] 單據報銷
│   │   └── AIS.Module.AIGateway       ← [ISA Edge 專屬] AI 路由閘道
│   │
│   ├── /Apps                          ← 各產品的後端宿主應用（每個建置為一個 Docker Image）
│   │   ├── AIS.App.OfficeAI           ← 引用 Identity + Admin + PackageRecog + ExpenseRecog
│   │   ├── AIS.App.ISAEdge            ← 引用 Identity + Admin + AIGateway
│   │   └── AIS.App.UpdateAgent        ← 升級代理（常駐容器，協調容器更新流程）
│   │
│   └── /Frontend                      ← 前端 SPA（各產品透過建置參數各自打包）
│       └── ais-web                    ← Vue 3 + TypeScript + Vite
│
├── /deploy
│   ├── /office-ai                     ← Office AI 完整獨立部署
│   │   ├── docker-compose.yml         ← 開發/測試用
│   │   └── docker-compose.prod.yml    ← 正式環境用
│   ├── /isa-edge                      ← ISA Edge 完整獨立部署
│   │   ├── docker-compose.yml
│   │   └── docker-compose.prod.yml
│   ├── /dockerfiles
│   │   ├── Dockerfile.app             ← 後端宿主應用通用 Dockerfile
│   │   ├── Dockerfile.frontend        ← 前端 Nginx Dockerfile
│   │   └── Dockerfile.update-agent    ← 升級代理專用 Dockerfile
│   ├── init-db-office.sql             ← Office AI 資料庫初始化 SQL
│   └── init-db-edge.sql               ← ISA Edge 資料庫初始化 SQL
│
├── /ci
│   ├── Jenkinsfile                    ← Jenkins Pipeline 定義
│   └── .gitlab-ci.yml                 ← GitLab CI 定義（觸發 Jenkins 或獨立跑）
│
└── /docs
```

---

## 二、後端框架規範

### 技術選型

| 項目 | 選擇 | 理由 |
|------|------|------|
| **框架** | ASP.NET Core 10 (LTS) Web API | 團隊熟悉 C#，直接升級 |
| **API 風格** | Controller-based Web API | 與 WebForm code-behind 思維接近，學習成本最低 |
| **ORM** | EF Core 10 + Npgsql | 對應原來的 DAO 層，但更標準化 |
| **認證** | JWT Bearer Token + ASP.NET Core Identity | 內建框架，不用額外引入 |
| **API 文件** | OpenAPI (Swagger) 內建 | 前後端橋樑，也方便未來 AI 讀取 |
| **日誌** | Serilog → PostgreSQL / File | .NET 生態最成熟的結構化日誌 |
| **健康檢查** | ASP.NET Core HealthChecks（內建） | 直接支援 Docker 健康探測 |

### 架構模式：簡化分層（對應團隊既有經驗）

```
┌─────────────────────────────────────────┐
│  Controller（= 原 WebForm Code-Behind） │  ← 接收 HTTP Request，回傳 JSON
├─────────────────────────────────────────┤
│  Service   （= 原 Helper）              │  ← 業務邏輯
├─────────────────────────────────────────┤
│  Repository（= 原 DAO）                 │  ← 資料存取（EF Core DbContext）
├─────────────────────────────────────────┤
│  Entity    （= 原 PO/VO）               │  ← 資料模型
└─────────────────────────────────────────┘
```

團隊只需理解：**Code-Behind → Controller、Helper → Service、DAO → Repository、PO → Entity**。核心概念不變，只是換了名字和更標準的實作方式。

### 單一模組的專案結構

```
AIS.Module.Admin/
├── Controllers/
│   ├── BackupController.cs
│   ├── NetworkController.cs
│   └── DiagnosticsController.cs
├── Services/
│   ├── BackupService.cs
│   ├── NetworkService.cs
│   └── DiagnosticsService.cs
├── Repositories/
│   ├── BackupRepository.cs
│   └── NetworkConfigRepository.cs
├── Entities/
│   ├── BackupRecord.cs
│   └── NetworkConfig.cs
└── DTOs/
    ├── BackupRequest.cs
    └── NetworkConfigDto.cs
```

### 共用程式庫使用方式

Monorepo 內開發階段使用 `ProjectReference` 直接引用 Common 元件；CI 建置時由各 App 專案統一編譯，不另外發佈為獨立 NuGet 套件：

```xml
<!-- AIS.Module.Admin.csproj -->
<ItemGroup>
  <ProjectReference Include="..\..\Common\AIS.Common.Auth\AIS.Common.Auth.csproj" />
  <ProjectReference Include="..\..\Common\AIS.Common.Data\AIS.Common.Data.csproj" />
  <ProjectReference Include="..\..\Common\AIS.Common.Audit\AIS.Common.Audit.csproj" />
</ItemGroup>
```

各 App 的 `Program.cs` 只需幾行就能啟用共用功能：

```csharp
var builder = WebApplication.CreateBuilder(args);

// ---- 引用共用模組（一行啟用一個功能）----
builder.AddAisAuthentication();      // 共用：JWT + RBAC
builder.AddAisPostgres<AdminDbContext>(); // 共用：EF Core + PostgreSQL
builder.AddAisAuditLog();            // 共用：審計日誌
builder.AddAisHealthChecks();        // 共用：健康檢查端點
builder.AddAisLicensing();           // 共用：授權驗證中介層

builder.Services.AddControllers();

var app = builder.Build();

app.UseAisAuth();
app.UseAisAudit();
app.MapControllers();
app.MapAisHealthChecks();            // 暴露 /healthz 端點

app.Run();
```

---

## 三、前端框架規範

### 技術選型

| 項目 | 選擇 | 理由 |
|------|------|------|
| **框架** | Vue 3 Composition API | 漸進式框架，從 jQuery 思維過渡最自然 |
| **語言** | TypeScript (strict mode) | 型別安全，AI 輔助開發效果倍增 |
| **建置** | Vite 6 | 快，設定簡單 |
| **UI 元件庫** | PrimeVue 4 | 企業元件齊全（表格、表單、對話框），免自造輪子 |
| **HTTP Client** | Axios（或 ofetch） | 團隊若熟 jQuery.ajax，Axios 概念最接近 |
| **路由** | Vue Router 4 | 標準配備 |
| **狀態管理** | Pinia | 僅在跨元件共享狀態時使用，不強制所有頁面都用 |

### 前端專案結構

```
ais-web/
├── src/
│   ├── api/                      ← API 呼叫層（≈ 原 jQuery $.ajax 集中管理）
│   │   ├── client.ts             ← Axios 實例（base URL、token 攔截器）
│   │   ├── authApi.ts
│   │   ├── backupApi.ts
│   │   └── networkApi.ts
│   │
│   ├── components/               ← 共用元件
│   │   ├── AppLayout.vue         ← 主版面（側欄 + 頂列）
│   │   ├── DataTable.vue         ← 封裝 PrimeVue DataTable 的共用設定
│   │   └── ConfirmDialog.vue
│   │
│   ├── composables/              ← 可重用邏輯 hook（≈ 原 Helper 的前端版）
│   │   ├── useAuth.ts
│   │   ├── useNotification.ts
│   │   └── usePagination.ts
│   │
│   ├── views/                    ← 頁面（≈ 原 .aspx 頁面）
│   │   ├── auth/
│   │   │   ├── LoginView.vue
│   │   │   └── UserManageView.vue
│   │   ├── admin/
│   │   │   ├── BackupView.vue
│   │   │   ├── NetworkView.vue
│   │   │   └── LicenseView.vue
│   │   └── monitor/
│   │       ├── HealthView.vue
│   │       └── AuditLogView.vue
│   │
│   ├── stores/                   ← Pinia（僅全域狀態：登入態、權限、通知）
│   │   ├── authStore.ts
│   │   └── notificationStore.ts
│   │
│   ├── router/
│   │   └── index.ts              ← 路由定義 + 權限守衛
│   ├── App.vue
│   └── main.ts
│
├── index.html
├── vite.config.ts
├── tsconfig.json
└── package.json
```

### 前端與團隊經驗的對應

| jQuery 時代 | Vue 3 時代 | 說明 |
|-------------|-----------|------|
| `.aspx` 頁面 | `*View.vue` | 一個頁面一個 Vue 檔 |
| `$.ajax()` | `api/*.ts` | API 呼叫集中管理 |
| DOM 操作 `$('#xxx').val()` | `ref()` / `v-model` | 響應式綁定取代手動 DOM |
| jQuery Plugin | PrimeVue 元件 | 如 DataTable、Calendar |
| 全域變數 | Pinia Store | 登入狀態、權限等 |
| `<script>` 內的 function | `composables/use*.ts` | 可重用邏輯抽取 |

---

## 四、Docker 部署結構

兩個產品**完全獨立部署**，各自擁有獨立的 PostgreSQL 實例，資料互不相通。每個產品以**產品為單位整包更新**，後端所有功能合併為單一容器，每個產品共 **4 個容器**。

```
每個產品的容器組成
├── [容器 1] postgres       ← 資料庫（獨立 Volume 持久化）
├── [容器 2] backend        ← 後端 API（所有模組合為一個程式）
├── [容器 3] web            ← 前端 Nginx（靜態檔案 + API 反向代理）
└── [容器 4] update-agent   ← 升級代理（常駐，協調其他容器的更新流程）
```

### App 宿主的概念

`/Apps` 下的兩個專案是真正的部署入口，`Program.cs` 將各自產品的模組全部註冊進單一 ASP.NET Core 程序：

```csharp
// AIS.App.OfficeAI / Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.AddAisAuthentication();
builder.AddAisPostgres<OfficeAIDbContext>();
builder.AddAisAuditLog();
builder.AddAisHealthChecks();
builder.AddAisLicensing();

// 註冊所有產品內的模組 Controller
builder.Services.AddControllers()
    .AddApplicationPart(typeof(IdentityController).Assembly)    // AIS.Module.Identity
    .AddApplicationPart(typeof(AdminController).Assembly)       // AIS.Module.Admin
    .AddApplicationPart(typeof(PackageRecogController).Assembly) // AIS.Module.PackageRecog
    .AddApplicationPart(typeof(ExpenseRecogController).Assembly);// AIS.Module.ExpenseRecog

var app = builder.Build();
app.UseAisAuth();
app.UseAisAudit();
app.MapControllers();
app.MapAisHealthChecks();
app.Run();
```

程式碼仍按模組分資料夾、分專案，維持清晰結構；只是執行時合為一個程序，不需要多個容器互相呼叫。

### Office AI（`deploy/office-ai/docker-compose.yml`）

```yaml
# deploy/office-ai/docker-compose.yml
services:
  # ---- 容器 1：Office AI 專屬資料庫 ----
  postgres:
    image: postgres:17
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ../../deploy/init-db-office.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  # ---- 容器 2：後端（所有模組合一）----
  backend:
    build:
      context: ../..
      dockerfile: deploy/dockerfiles/Dockerfile.app
      args: { APP: AIS.App.OfficeAI }
    depends_on: [postgres]
    environment:
      ConnectionStrings__Default: "Host=postgres;Database=ais_office;..."
    volumes:
      - update-staging:/staging                     # 與 update-agent 共享的暫存目錄

  # ---- 容器 3：前端 Nginx ----
  web:
    build:
      context: ../..
      dockerfile: deploy/dockerfiles/Dockerfile.frontend
      args: { PRODUCT: office-ai }
    ports:
      - "443:443"
    # Nginx 反向代理：
    #   /api/*           → backend:5000
    #   /update-status   → update-agent:5001
    #   /*               → 靜態 Vue SPA

  # ---- 容器 4：升級代理（常駐）----
  update-agent:
    build:
      context: ../..
      dockerfile: deploy/dockerfiles/Dockerfile.update-agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # 操作其他容器
      - update-staging:/staging                     # 和 backend 共享的暫存目錄
      - ./docker-compose.yml:/compose/docker-compose.yml:ro
    restart: always

volumes:
  pgdata:
  update-staging:
```

### ISA Edge（`deploy/isa-edge/docker-compose.yml`）

```yaml
# deploy/isa-edge/docker-compose.yml
services:
  # ---- 容器 1：ISA Edge 專屬資料庫 ----
  postgres:
    image: postgres:17
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ../../deploy/init-db-edge.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  # ---- 容器 2：後端（所有模組合一）----
  backend:
    build:
      context: ../..
      dockerfile: deploy/dockerfiles/Dockerfile.app
      args: { APP: AIS.App.ISAEdge }
    depends_on: [postgres]
    environment:
      ConnectionStrings__Default: "Host=postgres;Database=ais_edge;..."
    volumes:
      - update-staging:/staging                     # 與 update-agent 共享的暫存目錄

  # ---- 容器 3：前端 Nginx ----
  web:
    build:
      context: ../..
      dockerfile: deploy/dockerfiles/Dockerfile.frontend
      args: { PRODUCT: isa-edge }
    ports:
      - "443:443"
    # Nginx 反向代理：
    #   /api/*           → backend:5000
    #   /update-status   → update-agent:5001
    #   /*               → 靜態 Vue SPA

  # ---- 容器 4：升級代理（常駐）----
  update-agent:
    build:
      context: ../..
      dockerfile: deploy/dockerfiles/Dockerfile.update-agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # 操作其他容器
      - update-staging:/staging                     # 和 backend 共享的暫存目錄
      - ./docker-compose.yml:/compose/docker-compose.yml:ro
    restart: always

volumes:
  pgdata:
  update-staging:
```

**關鍵設計：**
- 每個產品各 4 個容器，管理簡單，現場人員只需掌握 `docker compose up/down/logs`。
- 後端為單一程式，所有模組 Controller 共存，對外只有一個 `backend:5000`。Nginx 反向代理將 `/api/*` 轉發至 `backend:5000`，將 `/update-status` 轉發至 `update-agent:5001`（供升級進度查詢）。
- `update-agent` 常駐運行，透過掛載 Docker Socket 操作其他容器，是整個升級流程的協調者，詳見【八、升級機制】。
- 兩個產品的 `docker-compose.yml` 結構完全對稱，降低學習與維護成本。
- 部署任一產品時只需在目標主機執行對應目錄下的 `docker compose up`，完全不依賴另一個產品。

---

## 五、CI/CD 整合（GitLab + Jenkins）

```
GitLab Push → GitLab Webhook → Jenkins Pipeline
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              Build Stage      Test Stage      Deploy Stage
              ‧dotnet build    ‧dotnet test    ‧docker build
              ‧npm run build   ‧npm run test   ‧docker push
                                               ‧docker-compose up
```

```groovy
// Jenkinsfile（精簡版）
pipeline {
    agent any
    stages {
        stage('Build Backend') {
            steps { sh 'dotnet build src/AIS.sln' }
        }
        stage('Build Frontend') {
            steps { dir('src/Frontend/ais-web') { sh 'npm ci && npm run build' } }
        }
        stage('Test') {
            parallel {
                stage('Backend Tests')  { steps { sh 'dotnet test' } }
                stage('Frontend Tests') { steps { dir('src/Frontend/ais-web') { sh 'npm run test' } } }
            }
        }
        stage('Docker Build & Push') {
            parallel {
                stage('Office AI') {
                    steps { sh 'docker compose -f deploy/office-ai/docker-compose.prod.yml build && docker compose -f deploy/office-ai/docker-compose.prod.yml push' }
                }
                stage('ISA Edge') {
                    steps { sh 'docker compose -f deploy/isa-edge/docker-compose.prod.yml build && docker compose -f deploy/isa-edge/docker-compose.prod.yml push' }
                }
            }
        }
    }
}
```

---

## 六、共通基礎功能與技術的對應

| 規範章節 | 功能 | 實作方式 |
|----------|------|----------|
| §2 帳號管理 | 本地帳號 + LDAP + MFA | `AIS.Common.Auth`：ASP.NET Core Identity + TOTP 套件 |
| §3 RBAC | 角色權限 | ASP.NET Core 內建 `[Authorize(Roles="...")]` + Policy |
| §4 健康監控 | Heartbeat + 裝置資訊 | `AIS.Common.Health`：ASP.NET Core HealthChecks + 自訂硬體探測 |
| §5 網路設定 | IP/Proxy/TLS 憑證配置 | `AIS.Module.Admin`：寫入 PostgreSQL，套用時呼叫 OS 指令；TLS 憑證由使用者透過管理介面上傳，未設定時預設使用自簽憑證 |
| §6 更新機制 | 升級包上傳、驗簽、DB migration、容器更新、回滾 | `AIS.Common.Update`：RSA 驗簽；`AIS.App.UpdateAgent`：常駐式 Docker 操作代理 |
| §7 審計日誌 | 操作記錄 + 防篡改 | `AIS.Common.Audit`：Serilog → PG + HMAC 簽章 |
| §8 備份還原 | Config/State 備份 | `AIS.Module.Admin`：`pg_dump` + 檔案打包 |
| §9 授權管理 | License 離線驗證 | `AIS.Common.Licensing`：HWID 綁定 + RSA 簽章 .lic |
| §10 診斷通報 | 打包 + 多通路通知 | `AIS.Common.Notification`：Email (SMTP) / Webhook (LINE/Teams) |

---

## 七、Office AI 與 ISA Edge 整合規範

### 設計理念

Office AI 原先由後端直接對接 OpenAI API 或 Ollama，加入 ISA Edge 後應**無痛轉移**。所有 AI 請求皆由 **Office AI 後端（ASP.NET Core）發出**，前端不直接與 ISA Edge 或任何 LLM 供應商通訊。採用 **OpenAI API 兼容格式**作為後端對後端的通訊協定，並擴展 ISA Edge 所需的路由、優先級、審計等管理欄位，確保：

1. **安全性**：API Key、JWT Token 等敏感資訊僅存在後端，不暴露於瀏覽器端
2. **架構一致性**：前端只對自家 Office AI 後端發請求（`/api/*`），跨系統通訊皆為後端對後端
3. **業務邏輯封裝**：後端可在發送前做資料前處理（如圖片壓縮、Prompt 組裝），收到回應後做後處理（如結果存檔、觸發後續流程）
4. **相容性**：Office AI 後端可透過切換端點 URL 在「直連 LLM」與「透過 ISA Edge」間無縫切換
5. **擴展性**：ISA Edge 可根據擴展欄位進行智慧路由、成本優化、審計追蹤
6. **標準化**：遵循業界主流 API 格式，未來可對接其他 AI Gateway 或雲端服務

### 整體資料流

```
┌────────────────┐     HTTPS/JSON     ┌────────────────────┐    HTTPS/JSON     ┌────────────────┐
│                │   /api/expense/*    │                    │  OpenAI 兼容格式   │                │
│  Vue 3 前端    │ ──────────────────→ │  Office AI 後端    │ ────────────────→  │  ISA Edge 後端 │
│  (瀏覽器)      │ ←────────────────── │  (ASP.NET Core)    │ ←────────────────  │  (ASP.NET Core)│
│                │   業務層 JSON 回應   │                    │  OpenAI 兼容回應   │                │
└────────────────┘                     └────────────────────┘   + ISA 擴展欄位   └───────┬────────┘
                                                                                        │
                                                                                        │ 路由決策
                                                                                        ▼
                                                                           ┌──────────────────────┐
                                                                           │  OpenAI / Ollama /   │
                                                                           │  Azure OpenAI        │
                                                                           └──────────────────────┘
```

前端只需呼叫 Office AI 自己的業務 API（如 `POST /api/expense/recognize`），不需知道背後使用哪個 LLM；Office AI 後端負責組裝 Prompt、呼叫 ISA Edge（或直連 LLM）、解析回應後回傳業務結果。

### 通訊協定（Office AI 後端 → ISA Edge）

| 項目 | 規範 |
|------|------|
| **通訊方向** | Office AI 後端 → ISA Edge 後端（後端對後端） |
| **協定** | HTTPS (TLS 1.2+) |
| **格式** | JSON (RESTful API) |
| **認證** | JWT Bearer Token（由 Office AI 後端代為附加） |
| **API 端點** | `POST /api/ai/chat/completions`<br>`POST /api/ai/embeddings`（未來擴展） |
| **兼容標準** | OpenAI API v1 Compatible |
| **字元編碼** | UTF-8 |

### 請求格式（Office AI 後端 → ISA Edge）

```http
POST https://isa-edge.local/api/ai/chat/completions
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
X-Request-ID: 550e8400-e29b-41d4-a716-446655440000
```

```json
{
  // ========== OpenAI 兼容欄位（核心） ==========
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "你是一個專業的文件辨識助手"
    },
    {
      "role": "user",
      "content": "請辨識這張發票的金額、日期、供應商"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2000,
  "top_p": 1.0,
  "frequency_penalty": 0.0,
  "presence_penalty": 0.0,
  "stream": false,
  
  // ========== ISA Edge 擴展欄位（管理用） ==========
  "isa_extensions": {
    // --- 來源識別 ---
    "request_source": "office-ai",              // 請求來源產品識別
    "request_type": "expense_recognition",      // 業務類型標記（用於統計與審計）
    
    // --- 路由策略 ---
    "routing_strategy": "auto",                 // auto / fast / accurate / cost_optimized
    "priority": "normal",                       // high / normal / low（影響佇列優先順序）
    
    // --- 容錯與重試 ---
    "timeout_seconds": 30,                      // 請求超時時間
    "retry_policy": {
      "max_retries": 2,                         // 失敗時最大重試次數
      "fallback_models": [                      // 主模型失敗時的備援清單
        "gpt-4o-mini",
        "llama3.1"
      ]
    },
    
    // --- 審計與追蹤 ---
    "metadata": {
      "user_id": "user_abc123",                 // 終端使用者 ID（由後端從 JWT 解析注入）
      "session_id": "session_xyz789",           // 使用者會話 ID
      "feature": "invoice_ocr",                 // 功能模組標記
      "correlation_id": "req_20260226_001"      // 關聯 ID（供跨系統追蹤）
    }
  }
}
```

**欄位說明：**

| 欄位 | 必填 | 說明 |
|------|------|------|
| `model` | ✓ | 模型名稱（OpenAI 格式：`gpt-4o`、`gpt-4o-mini`；Ollama 格式：`llama3.1`） |
| `messages` | ✓ | 對話訊息陣列（`role` 可為 `system`/`user`/`assistant`） |
| `temperature` | - | 0.0-2.0，預設 0.7，控制輸出隨機性 |
| `max_tokens` | - | 回應最大 token 數，預設 2000 |
| `stream` | - | 是否串流回傳（Server-Sent Events），預設 `false` |
| `isa_extensions` | - | ISA Edge 專屬擴展欄位（直連 OpenAI 時可省略） |
| `routing_strategy` | - | 路由策略：`auto`（自動選擇）、`fast`（優先速度）、`accurate`（優先準確率）、`cost_optimized`（優先成本） |
| `priority` | - | 請求優先級，影響 ISA Edge 內部佇列排程 |
| `retry_policy` | - | 重試設定，指定 fallback 模型清單 |
| `metadata` | - | 自訂元數據，供審計日誌、成本分攤、使用統計使用 |

### 回應格式（ISA Edge → Office AI 後端）

**成功回應（200 OK）：**

```json
{
  // ========== OpenAI 兼容回應 ==========
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1708934400,
  "model": "gpt-4o",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "根據發票辨識結果：\n- 金額：NT$ 1,234\n- 日期：2026-02-15\n- 供應商：ABC 公司"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 56,
    "completion_tokens": 48,
    "total_tokens": 104
  },
  
  // ========== ISA Edge 擴展欄位 ==========
  "isa_metadata": {
    "request_id": "req_550e8400",               // ISA Edge 內部請求 ID
    "actual_provider": "openai",                // 實際使用的供應商（openai / ollama / azure）
    "actual_model": "gpt-4o-2024-05-13",       // 實際使用的模型版本
    "routed_at": "2026-02-26T10:30:00Z",       // 路由決策時間
    "completed_at": "2026-02-26T10:30:01.234Z",// 完成時間
    "latency_ms": 1234,                         // ISA Edge 處理總延遲（含排隊）
    "provider_latency_ms": 1180,                // 實際 LLM 供應商回應時間
    "cache_hit": false,                         // 是否命中快取（未來功能）
    "retry_count": 0,                           // 實際重試次數
    "cost_estimate": {                          // 成本估算（供內部統計）
      "input_cost_usd": 0.00056,
      "output_cost_usd": 0.00144,
      "total_cost_usd": 0.00200
    }
  }
}
```

**錯誤回應：**

```json
{
  "error": {
    "message": "Model 'gpt-5' is not available",
    "type": "invalid_request_error",
    "code": "model_not_found",
    "param": "model"
  },
  "isa_metadata": {
    "request_id": "req_550e8400",
    "failed_at": "2026-02-26T10:30:00Z"
  }
}
```

### Office AI 後端實作範例

#### AI Client 服務（後端呼叫 ISA Edge 的統一入口）

```csharp
// AIS.Common.Contracts/AI/IAIClient.cs — 共用介面

public interface IAIClient
{
    Task<ChatCompletionResponse> ChatCompletionAsync(
        ChatCompletionRequest request,
        CancellationToken cancellationToken = default);
}

// AIS.Common.Contracts/AI/ChatCompletionRequest.cs — OpenAI 兼容 DTO

public class ChatCompletionRequest
{
    [JsonPropertyName("model")]
    public string Model { get; set; } = "gpt-4o";

    [JsonPropertyName("messages")]
    public List<ChatMessage> Messages { get; set; } = [];

    [JsonPropertyName("temperature")]
    public double? Temperature { get; set; }

    [JsonPropertyName("max_tokens")]
    public int? MaxTokens { get; set; }

    [JsonPropertyName("stream")]
    public bool Stream { get; set; } = false;

    [JsonPropertyName("isa_extensions")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public ISAExtensions? IsaExtensions { get; set; }
}

public class ChatMessage
{
    [JsonPropertyName("role")]
    public string Role { get; set; } = "user";

    [JsonPropertyName("content")]
    public string Content { get; set; } = "";
}

public class ISAExtensions
{
    [JsonPropertyName("request_source")]
    public string RequestSource { get; set; } = "office-ai";

    [JsonPropertyName("request_type")]
    public string? RequestType { get; set; }

    [JsonPropertyName("routing_strategy")]
    public string RoutingStrategy { get; set; } = "auto";

    [JsonPropertyName("priority")]
    public string Priority { get; set; } = "normal";

    [JsonPropertyName("timeout_seconds")]
    public int TimeoutSeconds { get; set; } = 30;

    [JsonPropertyName("retry_policy")]
    public RetryPolicy? RetryPolicy { get; set; }

    [JsonPropertyName("metadata")]
    public Dictionary<string, string>? Metadata { get; set; }
}

public class RetryPolicy
{
    [JsonPropertyName("max_retries")]
    public int MaxRetries { get; set; } = 2;

    [JsonPropertyName("fallback_models")]
    public List<string> FallbackModels { get; set; } = [];
}
```

```csharp
// AIS.Common.Contracts/AI/AIClient.cs — 統一實作

public class AIClient : IAIClient
{
    private readonly HttpClient _httpClient;
    private readonly AIGatewayOptions _options;
    private readonly ILogger<AIClient> _logger;

    public AIClient(HttpClient httpClient, IOptions<AIGatewayOptions> options, ILogger<AIClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ChatCompletionResponse> ChatCompletionAsync(
        ChatCompletionRequest request, CancellationToken cancellationToken = default)
    {
        // 若端點為 ISA Edge，自動注入擴展欄位
        if (_options.UseISAEdge && request.IsaExtensions is null)
        {
            request.IsaExtensions = new ISAExtensions
            {
                RequestSource = "office-ai",
                RoutingStrategy = "auto",
                Priority = "normal"
            };
        }

        // 若直連 OpenAI/Ollama，移除 ISA 擴展欄位以保持相容
        if (!_options.UseISAEdge)
        {
            request.IsaExtensions = null;
        }

        var requestId = Guid.NewGuid().ToString();
        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "chat/completions");
        httpRequest.Headers.Add("X-Request-ID", requestId);
        httpRequest.Content = JsonContent.Create(request);

        _logger.LogInformation("Sending AI request {RequestId} to {Endpoint}, model={Model}",
            requestId, _options.Endpoint, request.Model);

        var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<ChatCompletionResponse>(cancellationToken)
            ?? throw new InvalidOperationException("Empty AI response");
    }
}
```

#### DI 註冊與組態

```csharp
// AIS.Common.Contracts/AI/AIGatewayOptions.cs

public class AIGatewayOptions
{
    public const string SectionName = "AIGateway";

    /// <summary>AI Gateway 端點 URL</summary>
    public string Endpoint { get; set; } = "https://isa-edge.local/api/ai";

    /// <summary>是否使用 ISA Edge（false 時直連 OpenAI/Ollama）</summary>
    public bool UseISAEdge { get; set; } = true;

    /// <summary>直連模式使用的 API Key（透過 ISA Edge 時不需要）</summary>
    public string? ApiKey { get; set; }

    /// <summary>預設超時秒數</summary>
    public int DefaultTimeoutSeconds { get; set; } = 30;
}
```

```csharp
// AIS.Common.Contracts/AI/ServiceCollectionExtensions.cs

public static class AIClientExtensions
{
    public static IServiceCollection AddAisAIClient(
        this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<AIGatewayOptions>(
            configuration.GetSection(AIGatewayOptions.SectionName));

        services.AddHttpClient<IAIClient, AIClient>((sp, client) =>
        {
            var options = sp.GetRequiredService<IOptions<AIGatewayOptions>>().Value;
            client.BaseAddress = new Uri(options.Endpoint.TrimEnd('/') + "/");
            client.Timeout = TimeSpan.FromSeconds(options.DefaultTimeoutSeconds);

            // 直連 OpenAI 時使用 API Key；透過 ISA Edge 時由中介層注入 JWT
            if (!options.UseISAEdge && !string.IsNullOrEmpty(options.ApiKey))
            {
                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", options.ApiKey);
            }
        });

        return services;
    }
}
```

```csharp
// AIS.App.OfficeAI / Program.cs（加入一行即可啟用）

var builder = WebApplication.CreateBuilder(args);

builder.AddAisAuthentication();
builder.AddAisPostgres<OfficeAIDbContext>();
builder.AddAisAuditLog();
builder.AddAisHealthChecks();
builder.AddAisLicensing();
builder.Services.AddAisAIClient(builder.Configuration);  // ← 新增：註冊 AI Client

builder.Services.AddControllers()
    .AddApplicationPart(typeof(IdentityController).Assembly)
    .AddApplicationPart(typeof(AdminController).Assembly)
    .AddApplicationPart(typeof(PackageRecogController).Assembly)
    .AddApplicationPart(typeof(ExpenseRecogController).Assembly);

var app = builder.Build();
// ...
```

#### 業務模組使用範例

```csharp
// AIS.Module.ExpenseRecog/Services/ExpenseRecognitionService.cs

public class ExpenseRecognitionService
{
    private readonly IAIClient _aiClient;
    private readonly ILogger<ExpenseRecognitionService> _logger;

    public ExpenseRecognitionService(IAIClient aiClient, ILogger<ExpenseRecognitionService> logger)
    {
        _aiClient = aiClient;
        _logger = logger;
    }

    public async Task<InvoiceResult> RecognizeInvoiceAsync(
        string imageBase64, string userId, CancellationToken cancellationToken = default)
    {
        var request = new ChatCompletionRequest
        {
            Model = "gpt-4o",
            Messages =
            [
                new() { Role = "system", Content = "你是專業的發票辨識助手，請以 JSON 格式回傳發票資訊，包含 amount、date、vendor 欄位。" },
                new() { Role = "user", Content = $"請辨識這張發票：\n\n![invoice](data:image/jpeg;base64,{imageBase64})" }
            ],
            Temperature = 0.3,
            MaxTokens = 1000,
            IsaExtensions = new ISAExtensions
            {
                RequestSource = "office-ai",
                RequestType = "expense_recognition",
                Priority = "high",                       // 發票辨識為高優先級
                RoutingStrategy = "accurate",            // 優先準確率
                RetryPolicy = new RetryPolicy
                {
                    MaxRetries = 2,
                    FallbackModels = ["gpt-4o-mini"]
                },
                Metadata = new Dictionary<string, string>
                {
                    ["user_id"] = userId,
                    ["feature"] = "invoice_ocr"
                }
            }
        };

        var response = await _aiClient.ChatCompletionAsync(request, cancellationToken);
        var content = response.Choices.First().Message.Content;

        _logger.LogInformation("Invoice recognized via {Provider}, latency={Latency}ms",
            response.IsaMetadata?.ActualProvider, response.IsaMetadata?.LatencyMs);

        return JsonSerializer.Deserialize<InvoiceResult>(content)
            ?? throw new InvalidOperationException("Failed to parse invoice result");
    }
}
```

```csharp
// AIS.Module.ExpenseRecog/Controllers/ExpenseController.cs

[ApiController]
[Route("api/expense")]
[Authorize]
public class ExpenseController : ControllerBase
{
    private readonly ExpenseRecognitionService _recognitionService;

    public ExpenseController(ExpenseRecognitionService recognitionService)
        => _recognitionService = recognitionService;

    /// <summary>上傳發票圖片進行 AI 辨識</summary>
    [HttpPost("recognize")]
    public async Task<IActionResult> RecognizeInvoice(
        [FromBody] InvoiceRecognizeRequest request, CancellationToken cancellationToken)
    {
        var userId = User.FindFirst("sub")?.Value ?? "anonymous";
        var result = await _recognitionService.RecognizeInvoiceAsync(
            request.ImageBase64, userId, cancellationToken);
        return Ok(result);
    }
}
```

#### 前端呼叫方式

前端不需要知道 ISA Edge 的存在，只需呼叫 Office AI 自己的業務 API：

```typescript
// src/Frontend/ais-web/src/api/expenseApi.ts

import { client } from './client';

/** 上傳發票圖片進行 AI 辨識 */
export function recognizeInvoice(imageBase64: string) {
  return client.post<InvoiceResult>('/api/expense/recognize', { imageBase64 });
}
```

```vue
<!-- src/Frontend/ais-web/src/views/expense/InvoiceUploadView.vue -->
<script setup lang="ts">
import { ref } from 'vue';
import { recognizeInvoice } from '@/api/expenseApi';

const result = ref<InvoiceResult | null>(null);
const loading = ref(false);

async function onFileUpload(file: File) {
  loading.value = true;
  const base64 = await fileToBase64(file);
  result.value = await recognizeInvoice(base64);
  loading.value = false;
}
</script>
```

前端只負責上傳檔案、顯示結果；Prompt 組裝、LLM 選擇、ISA Edge 通訊全部由後端封裝處理。

### ISA Edge AIGateway 模組職責

ISA Edge 的 `AIS.Module.AIGateway` 負責：

1. **請求接收與驗證**
   - 驗證 JWT Token（確認請求來自合法的 Office AI 後端）
   - 驗證請求格式（OpenAI schema 驗證）
   - 檢查授權配額（License 限制）

2. **智慧路由決策**
   - 根據 `routing_strategy` 選擇最佳供應商/模型：
     - `auto`：綜合考量成本、速度、可用性
     - `fast`：選擇延遲最低的端點（本地 Ollama 優先）
     - `accurate`：選擇準確率最高的模型（GPT-4o 優先）
     - `cost_optimized`：選擇成本最低方案
   - 檢查模型可用性（health check）
   - 負載均衡（多個 API Key 輪替）

3. **請求轉發與重試**
   - 轉換為目標供應商格式（OpenAI / Ollama）
   - 執行請求並監控 timeout
   - 失敗時根據 `retry_policy` 自動切換 fallback 模型

4. **回應處理與記錄**
   - 統一回應格式（加入 `isa_metadata`）
   - 記錄審計日誌：
     - 請求來源、使用者、業務類型
     - 使用的模型與 Token 消耗
     - 延遲、成本、是否成功
   - 更新使用統計（供管理介面展示）

5. **成本與配額管理**
   - 追蹤各產品/使用者的 Token 用量
   - 超過配額時拒絕請求或降級至免費模型
   - 生成月度成本報表

### 後端模組結構

```
AIS.Module.AIGateway/                      ← [ISA Edge 專屬] AI 路由閘道
├── Controllers/
│   └── AIGatewayController.cs             // POST /api/ai/chat/completions
├── Services/
│   ├── RouterService.cs                   // 路由決策邏輯
│   ├── Providers/                         // 多供應商抽象層
│   │   ├── IProviderAdapter.cs            // 供應商介面
│   │   ├── OpenAIProvider.cs
│   │   ├── OllamaProvider.cs
│   │   └── AzureOpenAIProvider.cs
│   ├── RetryService.cs                    // 重試與 fallback
│   └── UsageTrackingService.cs            // 用量追蹤與成本計算
├── Repositories/
│   ├── AIRequestLogRepository.cs          // 審計日誌
│   └── UsageQuotaRepository.cs            // 配額管理
└── DTOs/
    ├── ChatCompletionRequest.cs           // OpenAI 兼容 DTO（引用 AIS.Common.Contracts）
    ├── ISAExtensions.cs                   // ISA 擴展欄位（引用 AIS.Common.Contracts）
    └── ChatCompletionResponse.cs
```

### 環境變數切換（無痛轉移）

Office AI 後端透過 `appsettings.json` 組態決定 AI 請求的目標端點，程式碼**完全不需修改**：

**正式環境（透過 ISA Edge）：**
```json
// AIS.App.OfficeAI / appsettings.Production.json
{
  "AIGateway": {
    "Endpoint": "https://isa-edge.local/api/ai",
    "UseISAEdge": true
    // 不需要 ApiKey，JWT Token 由共用認證模組自動注入
  }
}
```

**開發階段（直連 OpenAI，不經過 ISA Edge）：**
```json
// AIS.App.OfficeAI / appsettings.Development.json
{
  "AIGateway": {
    "Endpoint": "https://api.openai.com/v1",
    "UseISAEdge": false,
    "ApiKey": "sk-proj-xxx"
  }
}
```

**開發階段（直連本地 Ollama）：**
```json
// AIS.App.OfficeAI / appsettings.Development.json
{
  "AIGateway": {
    "Endpoint": "http://localhost:11434/v1",
    "UseISAEdge": false
  }
}
```

切換方式僅需變更組態檔或環境變數，`AIClient` 會自動根據 `UseISAEdge` 決定是否附加 ISA 擴展欄位，確保對目標端點的相容性。

---

## 八、升級機制

### 設計前提

升級流程的核心難題在於：**`backend` 容器本身也是被更新的對象**，它無法在執行中替換自己。因此引入一個獨立的 `update-agent` 常駐容器，專負協調整個升級流程。

```
容器的分工
├── backend        ← 接收升級檔上傳、驗證簽章、解壓縮、通知 update-agent
└── update-agent   ← 接手後執行 DB migration、重建容器、健康檢查、失敗則回滾
```

### 升級包結構

單一 `.sp` 檔案（ZIP 格式）：

```
office-ai-1.2.0.sp
├── manifest.json          ← 版本號、升級順序、相依性宣告
├── signature.sig          ← RSA 私鑰簽章（防竄改、驗真偽）
├── images/
│   ├── backend.tar        ← docker save 後端 image
│   └── web.tar            ← docker save 前端 image
└── migrations/
    ├── V1.2.0__upgrade.sql    ← 正向 migration
    └── V1.2.0__rollback.sql   ← 回滾用 SQL
```

`manifest.json` 範例：

```json
{
  "product": "office-ai",
  "version": "1.2.0",
  "min_current_version": "1.1.0",
  "steps": [
    { "type": "db_backup" },
    { "type": "db_migrate",   "file": "migrations/V1.2.0__upgrade.sql" },
    { "type": "image_load",  "file": "images/backend.tar", "service": "backend" },
    { "type": "image_load",  "file": "images/web.tar",     "service": "web" },
    { "type": "restart",     "service": "backend" },
    { "type": "health_check","service": "backend", "timeout_sec": 60 },
    { "type": "restart",     "service": "web" },
    { "type": "health_check","service": "web",     "timeout_sec": 30 }
  ],
  "rollback_steps": [
    { "type": "db_migrate",       "file": "migrations/V1.2.0__rollback.sql" },
    { "type": "restart_previous", "service": "backend" },
    { "type": "restart_previous", "service": "web" }
  ]
}
```

### 升級整體流程

```
使用者透過 Web UI 上傳 .sp
         │
         ▼
[backend 容器]
  1. 驗證 RSA 簽章（AIS.Common.Update）
  2. 驗證授權版本相依（AIS.Common.Licensing）
  3. 解壓縮到主機共享目錄（/staging Volume）
  4. 寫入升級任務至共享任務佇列（/staging/pending-task.json）
  5. 回傳「升級進行中」給前端
         │
         ▼
[update-agent 容器]（接手，從此步驟 backend/web 不參與）
  6.  讀取 manifest.json，確認版本相依性
  7.  docker exec postgres → pg_dump（備份資料庫）
  8.  docker exec postgres → 執行 upgrade.sql
  9.  docker load < backend.tar（載入新 image）
  10. docker load < web.tar
  11. docker compose up -d backend（用新 image 重建容器）
  12. 輪詢 GET /healthz 直到回應 200（最多等 60 秒）
  13. docker compose up -d web
  14. 輪詢 web 健康檢查
  15. 寫入升級成功記錄，清理暫存檔
         │
    （任一步驟失敗自動回滾）
         ▼
  回滾流程：
    → 執行 rollback.sql（先回滾 DB schema，避免舊版程式面對新版 DB）
    → 啟動舊版 image 的容器（docker compose up 使用舊 tag）
    → 寫入失敗記錄 + 發送告警（AIS.Common.Notification）
```

### 前端升級進度顯示

`backend` 容器升級期間會短暫停止回應，前端需有容錯機制：

```
Web UI 上傳完成
  → 每 3 秒輪詢 update-agent 進度端點
     GET /update-status（Nginx 反向代理至 update-agent，不經過 backend）
  → 顯示進度條：備份中 → DB升級中 → 載入新版本中 → 重啟中 → 完成
  → backend 重啟期間顯示「服務重啟中，請稍候」
  → 健康檢查通過後自動重新整理頁面
```

### 元件與專案對應

| 元件 | 升級流程中的角色 |
|---|---|
| `AIS.Common.Update` | RSA 簽章驗證、解壓縮、通知 agent |
| `AIS.Common.Licensing` | 驗證升級包是否符合授權版本 |
| `AIS.Common.Notification` | 升級失敗時發送告警（Email/LINE/Teams） |
| `AIS.Common.Health` | `/healthz` 端點供 agent 健康檢查 |
| `AIS.App.UpdateAgent` | 常駐式容器，執行 Docker 操作、DB migration、回滾 |
| `AIS.Module.Admin` | Web UI 的「系統升級」頁面，展示升級歷史表 |

---

## 總結：精簡框架全貌

兩個產品共用同一套程式碼庫（Monorepo），但部署時**完全獨立**，各自運作在不同主機或環境中，資料庫實例互不共用。

```
╔═══════════════════════════════════════╗   ╔═══════════════════════════════════════╗
║        【 Office AI 主機 】           ║   ║        【 ISA Edge 主機 】            ║
╠═══════════════════════════════════════╣   ╠═══════════════════════════════════════╣
║  [容器 3] web                         ║   ║  [容器 3] web                         ║
║  Vue 3 + Vite + PrimeVue              ║   ║  Vue 3 + Vite + PrimeVue              ║
║  Nginx（靜態檔案 + 反向代理）          ║   ║  Nginx（靜態檔案 + 反向代理）          ║
╠══════════ /api/* → backend ═══════════╣   ╠══════════ /api/* → backend ═══════════╣
║  [容器 2] backend                     ║   ║  [容器 2] backend                     ║
║  AIS.App.OfficeAI                     ║   ║  AIS.App.ISAEdge                      ║
║  ASP.NET Core 10，單一程序包含：       ║   ║  ASP.NET Core 10，單一程序包含：       ║
║  ├── Identity 模組                    ║   ║  ├── Identity 模組                    ║
║  ├── Admin 模組                       ║   ║  ├── Admin 模組                       ║
║  ├── PackageRecog 模組                ║   ║  └── AIGateway 模組                   ║
║  └── ExpenseRecog 模組                ║   ║                                       ║
║  （引用 AIS.Common.* 共用元件）     ║   ║  （引用 AIS.Common.* 共用元件）     ║
╠══════════ Npgsql ══════════════════════╣   ╠══════════ Npgsql ══════════════════════╣
║  [容器 1] postgres                    ║   ║  [容器 1] postgres                    ║
║  PostgreSQL 17 + pgdata Volume        ║   ║  PostgreSQL 17 + pgdata Volume        ║
║  Database: ais_office                 ║   ║  Database: ais_edge                   ║
╠═══════════════════════════════════════╣   ╠═══════════════════════════════════════╣
║  [容器 4] update-agent（常駐）        ║   ║  [容器 4] update-agent（常駐）        ║
║  協調升級流程：DB migration、         ║   ║  協調升級流程：DB migration、         ║
║  重建容器、健康檢查、失敗回滾         ║   ║  重建容器、健康檢查、失敗回滾         ║
╚═══════════════════════════════════════╝   ╚═══════════════════════════════════════╝

      ↑ 完全獨立，不共用任何容器或資料庫 ↑

共用（僅限 Build 時期，以 ProjectReference 形式引用）
└── AIS.Common.Auth / Data / Audit / Health / Licensing / Notification / Update / Contracts
```

**需要新學的東西（僅 4 項）：**
1. **Vue 3 + TypeScript**（取代 jQuery + aspx）
2. **EF Core**（取代手寫 DAO，概念相同但寫法更簡潔）
3. **ASP.NET Core Web API Controller**（取代 WebForm code-behind，改回傳 JSON 而非 HTML）
4. **Docker 基礎操作**（`docker compose up/down`、看 log）

其餘（C#、PostgreSQL、分層架構思維、CI/CD 流程）都是團隊已有的經驗延伸。