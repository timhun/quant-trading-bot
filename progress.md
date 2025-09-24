# AI-Agent 交易系統進度報告
*日期：2025 年 9 月 24 日*

## 專案概述
目標是建構一個 AI 輔助的交易系統，聚焦於 QQQ 和 0050 的交易策略 POC，包含數據獲取、SMA 交叉信號生成、進階指標（如 MACD）整合，以及雲端部署（Google VM）。

## 環境狀態
- **作業系統**：Ubuntu 24.04（`bbm@bbm-RZ-Series`），NVIDIA 顯示卡。
- **虛擬環境**：`(ai-trading-system)`，路徑 `/home/bbm/ai-trading-system/.venv`，包含：
  - `yfinance` 0.2.66
  - `pandas` 2.3.2
  - `numpy` 2.3.3
  - `python-dotenv` 1.1.1
- **Docker**：`docker.io` 27.5.1，測試成功。
- **Cursor IDE**：DEB 版正常，Grok API 已通過 `curl` 測試連線（模型 `grok-4-0709`），尚未在 IDE 內配置。
- **Git 倉庫**：`https://github.com/timhun/ai-trading-system.git`（最新提交 `e1e7292`）。

## 已完成進展
1. **環境設置**：
   - 安裝 Git、Docker、uv、Cursor IDE（DEB 版）。
   - 配置虛擬環境，安裝 `yfinance`、`pandas`、`numpy`、`python-dotenv`。
   - 修復 `pip` 問題（原指向 `/usr/bin/pip`），成功安裝 `python-dotenv`（1.1.1）。
   - Grok API 連線測試成功（`curl` 回應，模型 `grok-4-0709`，2025-09-24）。
2. **數據獲取**：
   - `data_test.py`：成功拉取 QQQ 數據（2023-01-01 至今），輸出 OHLCV。
3. **策略生成**：
   - `sma_signals.py`：實現 QQQ 的 50/200 日 SMA 交叉信號（黃金/死亡交叉），支援 CLI 參數（`--ticker`、`--start`、`--end`、`--csv`）。
   - 由 Cursor AI 優化，新增 `_to_scalar` 函數，解決 `Series` 錯誤。
   - 修復 MultiIndex 問題，生成乾淨 CSV（`market_data/QQQ_sma.csv`，384 字節，9/23）：

   Date,Close,SMA50,SMA200,Signal,Type
2022-03-01,341.489990234375,367.5573986816406,367.6897006225586,-1,Death Cross (Sell)
2023-03-13,290.69000244140625,290.1785986328125,290.1069496154785,1,Golden Cross (Buy)
2025-04-14,457.4800109863281,491.92100036621093,492.94304901123047,-1,Death Cross (Sell)
2025-06-24,539.780029296875,501.4837994384766,500.22924911499024,1,Golden Cross (Buy)

- 加入 MACD 指標（EMA12/EMA26，信號線 9），支援 CLI 參數（`--macd-fast`、`--macd-slow`、`--macd-signal`、`--print-macd`）。
- 生成 `market_data/QQQ_sma_macd.csv`（642 字節，9/24），包含 MACD 數據：

Date,Close,SMA50,SMA200,Signal,Type,MACD,MACD_Signal,MACD_Hist
2022-03-01,341.489990234375,367.5573986816406,367.6897006225586,-1,Death Cross (Sell),-7.066974165186309,-7.360806208870533,0.29383204368422344
2023-03-13,290.69000244140625,290.1785986328125,290.1069496154785,1,Golden Cross (Buy),-0.37342110858139677,0.907157273743908,-1.2805783823253047
2025-04-14,457.4800109863281,491.92100036621093,492.94304901123047,-1,Death Cross (Sell),-12.647991227251453,-13.35237621395012,0.7043849866986669
2025-06-24,539.780029296875,501.4837994384766,500.22924911499024,1,Golden Cross (Buy),7.868751843202517,8.971243468478114,-1.1024916252755972

- 最新 MACD（2025-09-23）：MACD=7.91, Signal=6.31, Hist=1.61。
4. **Grok API 測試**：
- 通過 `curl` 測試 Grok API 連線（2025-09-24）。
- Grok 提供 `sma_signals.py` 功能解釋和 MACD 實現建議（使用 `pandas.ewm()`）。
5. **檔案結構**：
- `scripts/`：包含 `sma_signals.py`、`data_collector.py`。
- `data_test.py` 和 `files/AI_Agent_Investment_Manager.md` 存在。
- 未追蹤檔案：`.devcontainer/`、`.vscode/`、`README.md`、`fetch_market_data.py`、`setup-ai-trading-env.sh` 等。

## 當前問題
- **Grok API**：尚未在 Cursor IDE 內配置，需完成設置並測試程式碼優化功能。
- **未追蹤檔案**：需處理 `.devcontainer/`、`.vscode/`、`README.md` 等。
- **MACD 進階功能**：尚未實現 MACD 交叉買賣訊號（例如 MACD 穿越訊號線）。

## 下一步計畫
1. **完成 Grok API 配置**：
- 在 Cursor IDE 內配置 Grok API，測試程式碼生成（如 MACD 交叉訊號）。
2. **新增 MACD 交叉訊號**：
- 修改 `sma_signals.py`，加入 MACD 穿越訊號線的買賣訊號。
3. **處理未追蹤檔案**：
- 檢查 `data_collector.py`、`fetch_market_data.py` 等功能，決定保留或移除。
- 設置 `.gitignore` 排除 `.devcontainer/`、`.vscode/` 等。
4. **後續部署**：
- 設置 GitHub Actions（自動同步到 Google VM）。
- 部署 Windmill 工作流（Google VM）。

## 待辦事項
- 確認是否繼續使用 `timhun` 帳號，或切換至 `bbm2330pub@gmail.com`。
- 檢查 `data_collector.py` 和 `fetch_market_data.py` 內容，明確其功能。
- 完成 Grok API 在 Cursor IDE 的配置並測試進階策略。