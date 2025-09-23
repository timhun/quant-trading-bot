# AI-Agent 交易系統進度報告
*日期：2025 年 9 月 23 日*

## 專案概述
目標是建構一個 AI 輔助的交易系統，聚焦於 QQQ 和 0050 的交易策略 POC，包含數據獲取、SMA 交叉信號生成、進階指標（如 MACD）整合，以及雲端部署（Google VM）。

## 環境狀態
- **作業系統**：Ubuntu 24.04（`bbm@bbm-RZ-Series`），NVIDIA 顯示卡。
- **虛擬環境**：`(ai-trading-system)`，包含：
  - `yfinance` 0.2.66
  - `pandas` 2.3.2
  - `numpy` 2.3.3
- **Docker**：`docker.io` 27.5.1，測試成功。
- **Cursor IDE**：DEB 版正常，尚未配置 Grok API。
- **Git 倉庫**：`https://github.com/timhun/ai-trading-system.git`（最新提交 `e1e7292`）。

## 已完成進展
1. **環境設置**：
   - 安裝 Git、Docker、uv、Cursor IDE（DEB 版）。
   - 配置虛擬環境，安裝 `yfinance`、`pandas`、`numpy`。
2. **數據獲取**：
   - `data_test.py`：成功拉取 QQQ 數據（2023-01-01 至今），輸出 OHLCV。
3. **策略生成**：
   - `sma_signals.py`：實現 QQQ 的 50/200 日 SMA 交叉信號（黃金/死亡交叉），支援 CLI 參數（`--ticker`、`--start`、`--end`、`--csv`）。
   - 由 Cursor AI 優化，新增 `_to_scalar` 函數，解決 `Series` 錯誤。
   - 成功運行，輸出信號：
   2022-03-01: Close=341.49, SMA50=367.56, SMA200=367.69, SELL
2023-03-13: Close=290.69, SMA50=290.18, SMA200=290.11, BUY
2025-04-14: Close=457.48, SMA50=491.92, SMA200=492.94, SELL
2025-06-24: Close=539.78, SMA50=501.48, SMA200=500.23, BUY

- CSV 輸出失敗，報錯 `TypeError: cannot specify cols with a MultiIndex on the columns`。
- 已提交至 GitHub（`e1e7292`）。
4. **檔案結構**：
- `scripts/`：包含 `sma_signals.py`、`data_collector.py`。
- `data_test.py` 和 `files/AI_Agent_Investment_Manager.md` 存在。
- 未追蹤檔案：`.devcontainer/`、`.vscode/`、`README.md`、`fetch_market_data.py`、`setup-ai-trading-env.sh` 等。

## 當前問題
- **CSV 格式**：`sma_signals.py` 報錯 `TypeError: cannot specify cols with a MultiIndex on the columns`，需處理 MultiIndex。
- **Grok API**：Cursor IDE 尚未配置 Grok API，無法生成進階策略（如 SMA+MACD）。
- **未追蹤檔案**：需處理 `.devcontainer/`、`.vscode/`、`README.md` 等。

## 下一步計畫
1. **修復 CSV 格式**：
- 修改 `sma_signals.py` 的 `to_csv` 邏輯，處理 MultiIndex，生成乾淨 CSV。
- 測試並提交更改。
2. **配置 Grok API**：
- 在 Cursor IDE 配置 xAI Grok API（https://x.ai/api）。
- 使用 Grok 優化 `sma_signals.py`，加入 MACD 指標（需安裝 `TA-Lib`）。
3. **處理未追蹤檔案**：
- 檢查 `data_collector.py`、`fetch_market_data.py` 等功能，決定保留或移除。
- 設置 `.gitignore` 排除 `.devcontainer/`、`.vscode/` 等。
4. **後續部署**：
- 設置 GitHub Actions（自動同步到 Google VM）。
- 部署 Windmill 工作流（Google VM）。

## 待辦事項
- 確認是否繼續使用 `timhun` 帳號，或切換至 `bbm2330pub@gmail.com`。
- 檢查 `data_collector.py` 和 `fetch_market_data.py` 內容，明確其功能。
- 完成 Grok API 配置並生成進階策略。