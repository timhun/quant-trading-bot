import os
import yfinance as yf
import pandas as pd
import psycopg2
from psycopg2 import sql

# 使用 Railway 環境變數連線
DB_HOST = os.environ.get('PGHOST', 'YOUR_RAILWAY_DB_HOST')
DB_USER = os.environ.get('PGUSER', 'YOUR_RAILWAY_DB_USER')
DB_PASS = os.environ.get('PGPASSWORD', 'YOUR_RAILWAY_DB_PASSWORD')
DB_NAME = os.environ.get('PGDATABASE', 'YOUR_RAILWAY_DB_NAME')

# 定義要抓取的股票代號
TICKERS = ['AAPL', 'GOOGL', 'MSFT', 'AMZN']

def create_table_if_not_exists(conn):
    """建立股票數據表，並將其轉換為 TimescaleDB 的超表"""
    with conn.cursor() as cur:
        # 建立表格
        cur.execute("""
            CREATE TABLE IF NOT EXISTS stock_data (
                symbol VARCHAR(10) NOT NULL,
                timestamp TIMESTAMPTZ NOT NULL,
                open DOUBLE PRECISION,
                high DOUBLE PRECISION,
                low DOUBLE PRECISION,
                close DOUBLE PRECISION,
                volume BIGINT,
                PRIMARY KEY (symbol, timestamp)
            );
        """)
        # 建立超表 (Hypertable)
        cur.execute("""
            SELECT create_hypertable('stock_data', 'timestamp', if_not_exists => TRUE);
        """)
        conn.commit()

def fetch_and_save_data(conn, ticker):
    """抓取並儲存單一股票的數據"""
    try:
        data = yf.download(ticker, period="1d", interval="1m")
        if data.empty:
            print(f"找不到 {ticker} 的數據。")
            return

        # 將數據格式化以便寫入資料庫
        data = data.reset_index()
        data = data.rename(columns={
            'Datetime': 'timestamp',
            'Open': 'open',
            'High': 'high',
            'Low': 'low',
            'Close': 'close',
            'Volume': 'volume'
        })
        data['symbol'] = ticker

        with conn.cursor() as cur:
            print(f"正在寫入 {ticker} 的數據...")
            # 使用 UPSERT 語法，如果數據已存在則更新，否則插入
            insert_query = sql.SQL("""
                INSERT INTO stock_data (symbol, timestamp, open, high, low, close, volume)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (symbol, timestamp) DO UPDATE
                SET open = EXCLUDED.open,
                    high = EXCLUDED.high,
                    low = EXCLUDED.low,
                    close = EXCLUDED.close,
                    volume = EXCLUDED.volume;
            """)
            # 準備要插入的數據
            records = [tuple(row) for row in data[['symbol', 'timestamp', 'open', 'high', 'low', 'close', 'volume']].itertuples(index=False)]
            cur.executemany(insert_query, records)
            conn.commit()
            print(f"{ticker} 數據寫入完成。")

    except Exception as e:
        print(f"處理 {ticker} 時發生錯誤: {e}")

def main():
    try:
        # 連接資料庫
        conn = psycopg2.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, dbname=DB_NAME)
        print("成功連線到 PostgreSQL 資料庫。")

        create_table_if_not_exists(conn)

        for ticker in TICKERS:
            fetch_and_save_data(conn, ticker)

    except Exception as e:
        print(f"資料庫連線或操作失敗: {e}")
    finally:
        if 'conn' in locals() and conn is not None:
            conn.close()
            print("資料庫連線已關閉。")

if __name__ == "__main__":
    main()
