# Docker Compose 測試操作說明指南

本文件旨在指導如何使用目前的 Docker 化測試架構，包括部署、測試功能與日常維護。

## 1. 快速開始

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

## 2. 功能測試說明

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

## 3. 軟體更新與版本控制測試

當您有新的程式碼更新時，請遵循以下步驟：

1.  **修改程式碼**：(例如在 `app/main.py` 修改功能)。
2.  **更新版本號**：在 `.env` 中修改 `APP_VERSION=1.0.1`。
3.  **重新構建與啟動**：
    ```powershell
    docker-compose up -d --build
    ```
4.  **驗證**：存取網頁確認底部顯示的應用程式版本號已更新。

---

## 4. 故障排除
*   **查看即時日誌**：`docker-compose logs -f`
*   **進入容器內部**：`docker-compose exec app sh`
