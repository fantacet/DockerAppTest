from flask import Flask, request, jsonify
import psycopg2  
import os

app = Flask(__name__)

# 從環境變數讀取資料庫資訊與版本
DB_HOST = os.getenv('DB_HOST', 'db')  
DB_NAME = os.getenv('POSTGRES_DB', 'testdb')  
DB_USER = os.getenv('POSTGRES_USER', 'user')  
DB_PASS = os.getenv('POSTGRES_PASSWORD', 'password')
APP_VERSION = os.getenv('APP_VERSION', 'unknown')

def get_db_connection():  
    conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS)  
    return conn

# 簡單的語系字典
MESSAGES = {
    'zh-TW': {
        'welcome': 'Hello! 這是來自 Docker 的 Flask 應用。',
        'db_stats': '資料庫已累計存取 {} 次。',
        'version': '應用程式版本：{}'
    },
    'en': {
        'welcome': 'Hello! This is a Flask app from Docker.',
        'db_stats': 'Database access count: {}.',
        'version': 'App Version: {}'
    }
}

@app.route('/')  
def hello():
    # 透過 Query Parameter ?lang=en 切換語系，預設 zh-TW
    lang = request.args.get('lang', 'zh-TW')
    if lang not in MESSAGES:
        lang = 'zh-TW'
        
    conn = get_db_connection()  
    cur = conn.cursor()  
    # 建立一個簡單的表來測試  
    cur.execute('CREATE TABLE IF NOT EXISTS visits (id serial PRIMARY KEY, ts timestamp DEFAULT CURRENT_TIMESTAMP);')  
    cur.execute('INSERT INTO visits DEFAULT VALUES;')  
    cur.execute('SELECT COUNT(*) FROM visits;')  
    count = cur.fetchone()[0]  
    cur.close()  
    conn.commit()  
    conn.close()  
    
    msg = MESSAGES[lang]
    return f"<h1>{msg['welcome']}</h1><p>{msg['db_stats'].format(count)}</p><p>{msg['version'].format(APP_VERSION)}</p>"

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "version": APP_VERSION})

if __name__ == "__main__":  
    app.run(host='0.0.0.0', port=5000)
