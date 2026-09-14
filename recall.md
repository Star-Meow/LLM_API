# recall.md — LLM_API 工作階段行動摘要

## 目前工作階段（依 read.md 建立新專案 LLM_API，本次僅建立本 recall.md）

### 本次運行範圍（僅允許建立本檔案）
- **本運行只允許建立 `H:\DockerDesktop\Project\LLM_API\recall.md`**。

### 追加許可（依用戶指示，已建立 compose）
- 用戶以**追加提醒（Harness 排除）**為前提，**允許建立本專案 compose**。
- **重要：需留下可重複使用的持久啟動檔**，**不可用 `--rm` 一次性容器方式**（容器需可留存 / 重啟 / 重複使用）。
- 已實際建立 `H:\DockerDesktop\Project\LLM_API\docker-compose.yml`（以原型核心 service「Local_LLM=llama-server 本體」為基準，排除 harness，最小變更，僅一個核心 service）。
- **當時已執行 `docker compose config` 驗證成功**：service/`container_name`=`LLM_API`、`image=localllm_prototype:latest`、`-m /models/Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf`、GPU reservations（nvidia/all）、bind `H:/DockerDesktop/models -> /models`、`8080->8080`、`-ngl 40`、`-c 32768`、tty/stdin_open 皆正確；compose project name 自動為 `llm_api`。

### 前置環境檢查結果
| 檢查項 | 結果 |
|---|---|
| `LLM_API` 目錄 | 存在，原本僅有 `read.md`，無 compose、無 recall.md |
| 目標模型 | ✅ `H:\DockerDesktop\models\Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf`（10,094,357,632 bytes ≈ 10.09 GB） |
| 原型 Image | ✅ `localllm_prototype:latest`（IMAGE 82d855469cfd，9.23GB）存在 |
| Docker engine | ✅ Docker 27.0.3 / Compose v2.28.1-desktop.1 正常回覆 |
| `Local_LLM` 容器 | 存在但 `Exited (0)`，**未在執行**；port 8080 目前無人占用，可沿用 |

### 原型 `Local_LLM/docker-compose.yml` 關鍵設定（將作為架構基準沿用）
- 核心 service：`Local_LLM`（`image: localllm_prototype`、`container_name: Local_LLM`）
- `working_dir: /app/llama.cpp`，`./build/bin/llama-server`
- volume：`H:/DockerDesktop/models:/models`
- ports：`8080:8080`
- environment：`NVIDIA_VISIBLE_DEVICES=all`、`NVIDIA_DRIVER_CAPABILITIES=compute,utility`
- deploy GPU：`nvidia` driver、`count: all`、`capabilities: [gpu]`
- command：`-m /models/Qwen3.8-9B-Q6_K.gguf --host 0.0.0.0 --port 8080 -ngl 40 -c 32768`
- `tty: true` / `stdin_open: true`

### LLM_API/docker-compose.yml 建構計畫（後續 act 階段執行，最小變更）
以原型為基準，**只改必要項目**，其餘全沿用，不重新設計。

| 項目 | 原型 `Local_LLM` | 新 `LLM_API` | 處理 |
|---|---|---|---|
| service 名稱 | `Local_LLM` | `LLM_API` | 修改 |
| `container_name` | `Local_LLM` | `LLM_API` | 修改 |
| `build.context` | `.` | 移除（LLM_API 無 Dockerfile） | 省略 |
| `image` | `localllm_prototype` | `localllm_prototype:latest`（沿用） | 保留 |
| `-m` 模型 | `/models/Qwen3.8-9B-Q6_K.gguf` | `/models/Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf` | 修改 |
| ports | `8080:8080` | `8080:8080`（Local_LLM 已停用，無衝突） | 沿用 |
| volume `H:/DockerDesktop/models:/models` | ✅ | ✅ | 沿用 |
| environment / deploy GPU / working_dir / tty | ✅ | ✅ | 全沿用 |
| `-ngl 40` / `-c 32768` | ✅ | ✅（第一階段僅求能啟動，不做優化） | 沿用 |

### 後續 act 階段驗證順序（依 read.md）
1. `docker compose config`（驗證語法 / volume / model path / GPU）
2. `docker compose up -d` → 確認 `LLM_API` 為 running
3. 檢視 log 確認 `Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf` 成功 load（首次 `-fit` 記憶體配置可能耗時數分鐘，屬正常）
4. 測試 `http://127.0.0.1:8080/health`、`/v1/models`、`/v1/chat/completions`

### Harness 排除注意（依 read.md）
- **原型 compose 可能含 harness（測試/評測）指令，一律不採用。** 本次僅以負責啟動 `llama-server` 的核心 service 設定作為基準。
- 已調查：`Local_LLM` 目錄僅有一份根 `docker-compose.yml`，內 **只含核心 service「`Local_LLM`（llama-server 本體）」，不含任何 harness service**，故可直接作為基準。
- `coding-marathon`（評測 harness）、額外 harness container、非 llama-server 本體的輔助服務，皆**不納入、不複製、不啟動**。本次 `LLM_API/docker-compose.yml` 僅有一個核心 service `LLM_API`，不新增其他 service。

### 禁止事項提醒（依 read.md）
不得修改 `Local_LLM` 或共用 Image、複製 GGUF 進 Image、建立重複 llama.cpp Image、任意增刪 service/GPU 設定、修改 Docker Desktop 設定、刪除既有 container/image/volume、執行破壞性 `docker prune` 或對非本專案跑 `docker compose down -v`、在未確認前猜測路徑或覆寫 ENTRYPOINT/CMD。