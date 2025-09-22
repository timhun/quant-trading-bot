import yfinance as yf
try:
    data = yf.download('QQQ', start='2023-01-01')
    if data.empty:
        raise ValueError("Failed to fetch QQQ data")
    print(data.tail())
except Exception as e:
    print(f"Error: {e}")
