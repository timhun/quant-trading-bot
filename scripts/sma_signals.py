#!/usr/bin/env python3

import argparse
from datetime import datetime, timedelta

import pandas as pd
import yfinance as yf


def fetch_price_history(
    ticker: str,
    start: str | None = None,
    end: str | None = None,
    interval: str = "1d",
) -> pd.DataFrame:
    if start is None:
        # Default to 3 years back to capture enough 200-day SMA history
        start = (datetime.utcnow() - timedelta(days=365 * 3 + 30)).strftime("%Y-%m-%d")
    if end is None:
        end = datetime.utcnow().strftime("%Y-%m-%d")

    data = yf.download(ticker, start=start, end=end, interval=interval, auto_adjust=False, progress=False)
    if data.empty:
        raise RuntimeError(f"No data returned for {ticker}.")
    return data


def compute_sma_signals(df: pd.DataFrame, short_window: int = 50, long_window: int = 200) -> pd.DataFrame:
    prices = df.copy()
    # Use Adj Close when available; fallback to Close
    close_col = "Adj Close" if "Adj Close" in prices.columns else "Close"
    prices["SMA_short"] = prices[close_col].rolling(window=short_window, min_periods=short_window).mean()
    prices["SMA_long"] = prices[close_col].rolling(window=long_window, min_periods=long_window).mean()

    # Signal when short SMA crosses long SMA
    signal = pd.Series(0, index=prices.index)
    crossover = (prices["SMA_short"] > prices["SMA_long"]).astype(int)
    prev = crossover.shift(1)
    signal[crossover.eq(1) & prev.eq(0)] = 1   # Golden cross => Buy
    signal[crossover.eq(0) & prev.eq(1)] = -1  # Death cross  => Sell

    prices["Signal"] = signal
    return prices


def format_signal_row(timestamp: pd.Timestamp, row: pd.Series) -> str:
    action = "BUY" if row["Signal"] == 1 else ("SELL" if row["Signal"] == -1 else "HOLD")
    return (
        f"{timestamp.date()} | {action} | Close={row.get('Adj Close', row.get('Close', float('nan'))):.2f} "
        f"SMA50={row['SMA_short']:.2f} SMA200={row['SMA_long']:.2f}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Compute 50/200-day SMA signals for QQQ (golden/death cross).")
    parser.add_argument("--ticker", default="QQQ", help="Ticker symbol (default: QQQ)")
    parser.add_argument("--start", default=None, help="Start date YYYY-MM-DD (default: ~3y ago)")
    parser.add_argument("--end", default=None, help="End date YYYY-MM-DD (default: today)")
    parser.add_argument("--interval", default="1d", choices=["1d"], help="Price interval (default: 1d)")
    parser.add_argument("--short", type=int, default=50, help="Short SMA window (default: 50)")
    parser.add_argument("--long", type=int, default=200, help="Long SMA window (default: 200)")
    parser.add_argument("--last", type=int, default=10, help="Show last N signals (default: 10)")
    parser.add_argument("--csv", default=None, help="Optional path to save enriched CSV output")
    args = parser.parse_args()

    if args.short >= args.long:
        raise SystemExit("Error: --short must be smaller than --long (e.g., 50 < 200)")

    df = fetch_price_history(args.ticker, start=args.start, end=args.end, interval=args.interval)
    result = compute_sma_signals(df, short_window=args.short, long_window=args.long)

    # Extract signal rows
    signal_rows = result[result["Signal"].isin([1, -1])]

    print(f"\nSMA crossover signals for {args.ticker} (short={args.short}, long={args.long}):")
    if signal_rows.empty:
        print("No crossover signals in the selected period.")
    else:
        # Show the last N signals
        last_signals = signal_rows.tail(args.last)
        for ts, row in last_signals.iterrows():
            print(format_signal_row(ts, row))

        # Also print the most recent market stance (HOLD/BUY/SELL) based on cross state
        latest = result.dropna(subset=["SMA_short", "SMA_long"]).iloc[-1]
        stance = "BULLISH (50>200)" if latest["SMA_short"] > latest["SMA_long"] else "BEARISH (50<=200)"
        print(f"\nLatest stance: {stance}")

    if args.csv:
        out = result.copy()
        out.to_csv(args.csv)
        print(f"\nSaved enriched data with SMAs and signals to: {args.csv}")


if __name__ == "__main__":
    main()


