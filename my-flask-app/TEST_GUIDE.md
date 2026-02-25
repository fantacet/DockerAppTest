# Docker Compose 測試操作說明指南

本文件旨在指導如何使用目前的 Docker 化測試架構，包括部署、測試功能與日常維護。

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
由於 WSL2 預設不執行 systemd（除非特別設定），您可能需要在 Ubuntu 每次啟動時手動啟動 Docker Daemon：
```bash
sudo service docker start
```
*(最簡單的作法是：**開啟 WSL (Ubuntu) 終端機，直接在 Ubuntu 內進入專案目錄 `/mnt/c/DockerAppTest/my-flask-app/` 執行 `sudo docker compose up -d`**，您不需要在 Windows 安裝任何 Docker EXE 檔。)*

---

## 2. 環境條件檢查腳本

為確保您的 Windows 主機符合部署條件，我們提供了一個自動化確認腳本 `check_env.bat`。
*   **如何執行**：在 `my-flask-app` 目錄下點擊執行 `check_env.bat`，或是於 CMD 執行。
*   **檢查項目**：WSL2 狀態、Docker/Compose 是否能正確載入、`.env` 檔與系統記憶體。

---

## 3. 快速開始

### 部署並啟動服務
```powershell
docker-compose up -d
```
*   這會自動讀取 `.env` 檔案，建立網路、Volume，並依照健康檢查順序啟動資料庫與應用。

### 停止並移除服務
```powershell
docker-compose down
```

### 停止並完整清除資料 (磁碟卷宗)
```powershell
docker-compose down -v
```

---

## 4. 功能測試說明

### A. 環境變數分離 (.env)
*   **檔名**：`.env`
*   **操作**：您可以修改 `.env` 中的 `APP_VERSION` 或 `NGINX_PORT` 後，執行 `docker-compose up -d` 即可套用新設定。

### B. 健康檢查 (Healthcheck)
*   **原理**：`app` 服務現在會等待 `db` 的狀態變更為 `healthy` 後才開始啟動。
*   **查看狀態**：
  ```powershell
  docker-compose ps
  ```
  於 `STATUS` 欄位應可看到 `(healthy)` 字樣。

### C. 多語系測試
應用程式支援透過 URL 參數切換語系：
*   **繁體中文** (預設)：[http://localhost:8080/](http://localhost:8080/)
*   **英文**：[http://localhost:8080/?lang=en](http://localhost:8080/?lang=en)

### D. 資源限制
*   **設定**：已在 `docker-compose.yml` 中限制了各容器的記憶體上限 (Memory Limit)。
*   **查看資源使用狀況**：
  ```powershell
  docker stats
  ```

---

## 5. 軟體更新與版本控制測試

當您有新的程式碼更新時，請遵循以下步驟：

1.  **修改程式碼**：(例如在 `app/main.py` 修改功能)。
2.  **更新版本號**：在 `.env` 中修改 `APP_VERSION=1.0.1`。
3.  **重新構建與啟動**：
    ```powershell
    docker-compose up -d --build
    ```
4.  **驗證**：存取網頁確認底部顯示的應用程式版本號已更新。

---

## 6. 故障排除
*   **查看即時日誌**：`docker-compose logs -f`
*   **進入容器內部**：`docker-compose exec app sh`
