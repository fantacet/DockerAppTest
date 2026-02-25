這是一個完整且簡單的範例。我們將建立三個目錄與檔案，這套設定可以直接在任何安裝了 Docker 的 Linux、Windows 或 macOS 上運行。

## ---

**1\. 專案目錄結構**

請先建立一個資料夾（例如 my-flask-app），並依照以下結構配置檔案：

Plaintext

my-flask-app/  
├── app/  
│   ├── Dockerfile  
│   ├── main.py  
│   └── requirements.txt  
├── nginx/  
│   └── nginx.conf  
└── docker-compose.yml

## ---

**2\. 各組件程式碼實作**

### **🔹 後端：Python Flask (app/)**

這是應用的核心，負責處理邏輯並連線到資料庫。

**app/main.py** (簡單的測試存取次數程式)

Python

from flask import Flask  
import psycopg2  
import os

app \= Flask(\_\_name\_\_)

\# 從環境變數讀取資料庫資訊  
DB\_HOST \= os.getenv('DB\_HOST', 'db')  
DB\_NAME \= os.getenv('POSTGRES\_DB', 'testdb')  
DB\_USER \= os.getenv('POSTGRES\_USER', 'user')  
DB\_PASS \= os.getenv('POSTGRES\_PASSWORD', 'password')

def get\_db\_connection():  
    conn \= psycopg2.connect(host=DB\_HOST, database=DB\_NAME, user=DB\_USER, password=DB\_PASS)  
    return conn

@app.route('/')  
def hello():  
    conn \= get\_db\_connection()  
    cur \= conn.cursor()  
    \# 建立一個簡單的表來測試  
    cur.execute('CREATE TABLE IF NOT EXISTS visits (id serial PRIMARY KEY, ts timestamp DEFAULT CURRENT\_TIMESTAMP);')  
    cur.execute('INSERT INTO visits DEFAULT VALUES;')  
    cur.execute('SELECT COUNT(\*) FROM visits;')  
    count \= cur.fetchone()\[0\]  
    cur.close()  
    conn.commit()  
    conn.close()  
    return f"Hello\! 這是來自 Docker 的 Flask 應用。資料庫已累計存取 {count} 次。"

if \_\_name\_\_ \== "\_\_main\_\_":  
    app.run(host='0.0.0.0', port=5000)

**app/requirements.txt**

Plaintext

flask  
psycopg2-binary

**app/Dockerfile** (定義如何封裝 Python 環境)

Dockerfile

FROM python:3.9\-slim  
WORKDIR /app  
COPY requirements.txt .  
RUN pip install \--no-cache-dir \-r requirements.txt  
COPY . .  
CMD \["python", "main.py"\]

### ---

**🔹 代理伺服器：Nginx (nginx/)**

負責接收外部請求並轉發給 Flask。

**nginx/nginx.conf**

Nginx

server {  
    listen 80;

    location / {  
        proxy\_pass http://app:5000;  \# 'app' 是 docker-compose 中的服務名稱  
        proxy\_set\_header Host $host;  
        proxy\_set\_header X-Real-IP $remote\_addr;  
    }  
}

### ---

**🔹 總指揮：Docker Compose**

這是「簡單佈署」的關鍵，它定義了三個 Container 如何運作。

**docker-compose.yml**

YAML

version: '3.8'

services:  
  \# 1\. 資料庫  
  db:  
    image: postgres:15  
    environment:  
      POSTGRES\_USER: user  
      POSTGRES\_PASSWORD: password  
      POSTGRES\_DB: testdb  
    volumes:  
      \- postgres\_data:/var/lib/postgresql/data  
    restart: always

  \# 2\. Flask 應用  
  app:  
    build: ./app  
    environment:  
      DB\_HOST: db  
      POSTGRES\_USER: user  
      POSTGRES\_PASSWORD: password  
      POSTGRES\_DB: testdb  
    depends\_on:  
      \- db

  \# 3\. Nginx 反向代理  
  nginx:  
    image: nginx:alpine  
    volumes:  
      \- ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro  
    ports:  
      \- "8080:80"  
    depends\_on:  
      \- app

volumes:  
  postgres\_data:

## ---

**3\. 如何執行佈署？**

1. 開啟終端機（Terminal 或 CMD），進入 my-flask-app 資料夾。  
2. 執行以下指令：  
   Bash  
   docker-compose up \-d

3. 打開瀏覽器，輸入 http://localhost:8080。

### **為什麼這能證明你的構想？**

* **跨 OS：** 你可以把這個資料夾整包壓縮，丟到 Ubuntu、CentOS 或 Windows Server 上，只要有 Docker，執行同一行指令結果完全一樣。  
* **簡單佈署：** 使用者不需要手動安裝 Python、PostgreSQL 或 Nginx，所有環境依賴都封裝在 Image 裡了。  
* **解耦：** 如果你想升級資料庫，只需改 docker-compose.yml 裡的版本號，不會影響到 Flask 或 Nginx。

## ---

**4. Host 地端佈署必要條件**

若要在地端主機佈署此應用，需滿足以下條件：
1. **硬體資源**：至少 1GB 以上的可用記憶體（建議 2GB 以上），以及足夠的硬碟空間（用來儲存環境映像檔，至少2GB）。
2. **軟體環境**：
   - **Linux 主機**：推薦直接安裝原生 Docker Engine 與 Docker Compose 插件。
   - **Windows 主機**：為節省系統資源與避開授權限制，**建議不使用 Docker Desktop**。請啟用 **WSL2** 並在其中手動安裝 Linux 版的 Docker Engine 及 Compose。
3. **專案配置**：必須準備好 `.env` 環境變數檔。
4. **網路與權限**：具有執行 Docker 指令的權限，並確認 Web 伺服器對外 Port（如 8080）未被佔用。

> 詳細的 WSL2 安裝 Docker 操作步驟與整合的環境檢查工具，請參閱 `my-flask-app/TEST_GUIDE.md` 與執行 `my-flask-app/check_env.bat`。