import yfinance as yf
import pandas as pd
import numpy as np
import argparse
from pathlib import Path
from datetime import datetime, timedelta
import datetime as dt

def fetch_data(ticker, start, end=None):
    try:
        data = yf.download(ticker, start=start, end=end, auto_adjust=False)
        if data.empty:
            raise ValueError(f"Failed to fetch {ticker} data")
        # Flatten MultiIndex columns if present
        if isinstance(data.columns, pd.MultiIndex):
            data.columns = [col[0] for col in data.columns]
        return data
    except Exception as e:
        print(f"Error fetching {ticker}: {e}")
        return None

def compute_sma_signals(data, short_window=50, long_window=200):
    data['SMA50'] = data['Close'].rolling(window=short_window).mean()
    data['SMA200'] = data['Close'].rolling(window=long_window).mean()
    data['Signal'] = 0
    data['Prev_SMA50'] = data['SMA50'].shift(1)
    data['Prev_SMA200'] = data['SMA200'].shift(1)
    data['Signal'] = np.where(
        (data['SMA50'] > data['SMA200']) & (data['Prev_SMA50'] <= data['Prev_SMA200']),
        1,  # Golden Cross (Buy)
        data['Signal']
    )
    data['Signal'] = np.where(
        (data['SMA50'] < data['SMA200']) & (data['Prev_SMA50'] >= data['Prev_SMA200']),
        -1,  # Death Cross (Sell)
        data['Signal']
    )
    return data

def _to_scalar(x):
    if isinstance(x, pd.Series):
        return x.iloc[0]
    if isinstance(x, np.ndarray):
        return x.item() if x.size == 1 else x.ravel()[0]
    return x

def format_signal_row(ts, row):
    sig_raw = _to_scalar(row['Signal'])
    try:
        sig = int(sig_raw)
    except Exception:
        sig = int(float(sig_raw)) if pd.notna(sig_raw) else 0
    action = "BUY" if sig == 1 else ("SELL" if sig == -1 else "HOLD")
    close_val = float(_to_scalar(row['Close']))
    sma50_val = float(_to_scalar(row['SMA50']))
    sma200_val = float(_to_scalar(row['SMA200']))
    return f"{ts}: Close={close_val:.2f}, SMA50={sma50_val:.2f}, SMA200={sma200_val:.2f}, {action}"

def main():
    parser = argparse.ArgumentParser(description="Calculate SMA crossover signals")
    parser.add_argument("--ticker", default="QQQ", help="Stock ticker")
    parser.add_argument("--start", default=None, help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end", default=None, help="End date (YYYY-MM-DD)")
    parser.add_argument("--short", type=int, default=50, help="Short SMA window")
    parser.add_argument("--long", type=int, default=200, help="Long SMA window")
    parser.add_argument("--last", type=int, default=10, help="Number of signals to show")
    parser.add_argument("--csv", help="Output CSV file path")
    args = parser.parse_args()

    if not args.start:
        args.start = (datetime.now(dt.UTC) - timedelta(days=365 * 3 + 30)).strftime("%Y-%m-%d")
    args.end = args.end or datetime.now(dt.UTC).strftime("%Y-%m-%d")

    print(f"SMA crossover signals for {args.ticker} (short={args.short}, long={args.long}):")
    data = fetch_data(args.ticker, args.start, args.end)
    if data is None:
        return

    data = compute_sma_signals(data, args.short, args.long)
    signals = data[data['Signal'] != 0][['Close', 'SMA50', 'SMA200', 'Signal']]
    if signals.empty:
        print("No crossover signals found.")
        return

    signals['Type'] = signals['Signal'].map({1: "Golden Cross (Buy)", -1: "Death Cross (Sell)"})
    for ts, row in signals.tail(args.last).iterrows():
        print(format_signal_row(ts, row))

    if args.csv:
        Path(args.csv).parent.mkdir(parents=True, exist_ok=True)
        signals_reset = signals.reset_index()
        # Ensure single-level column index
        signals_reset.columns = [col[0] if isinstance(col, tuple) else col for col in signals_reset.columns]
        signals_reset.to_csv(args.csv, index=False, columns=['Date', 'Close', 'SMA50', 'SMA200', 'Signal', 'Type'])
        print(f"Saved signals to {args.csv}")

if __name__ == "__main__":
    main()