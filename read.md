# Docker LLM_API 專案構築任務（精練版）

## 目標

以既有、已驗證的 Compose 架構為基準，建立新專案 `H:\DockerDesktop\Project\LLM_API`，僅將模型換成
`Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf`，其餘設定一律沿用，不重新設計。

| 項目 | 內容 |
|---|---|
| 原型 Compose | `H:\DockerDesktop\Project\Local_LLM\docker-compose.yml` |
| 原型 Image | `localllm_prototype:latest`（沿用，不重建、不修改） |
| 新模型 | `H:\DockerDesktop\models\Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf`（Volume 掛載，不進 Image） |
| 新專案輸出 | `H:\DockerDesktop\Project\LLM_API\docker-compose.yml` |
| 新 service / container 名稱 | 統一命名為 `LLM_API`（取代原本的 `Local_LLM`） |

> 注意：原型專案目錄中若含有測試/評測用的 harness（如 `coding-marathon` 之類的評測腳本、
> 額外的 harness container 或非 llama-server 本體的輔助服務），**皆非本次參考範圍**。
> 本次僅以 Compose 中負責啟動 `llama-server` 的核心 service 設定作為基準，其餘 harness
> 相關內容一律不納入、不複製、不啟動。

## 核心原則：先觀察，再修改，最小變更

```
Local_LLM/docker-compose.yml  →  架構基準
        ↓ 只改必要項目
LLM_API/docker-compose.yml    →  換上新模型
```

不得：更換 base image / 架構 / llama.cpp 啟動方式；新增非必要 service、volume、環境變數；
更動 network 或 GPU 架構；修改 Host Docker 設定；修改 `Local_LLM` 或 `localllm_prototype:latest`
（除非先說明「Image 現況 / 為何 Compose 無法解決 / 為何必須改 Image / 是否影響 Local_LLM」並取得確認）。

## 執行步驟

**1. 環境檢查（動手前必做）**
- 讀取並理解 `Local_LLM/docker-compose.yml` 全部內容（ports/volumes/environment/command/
  networks/restart/healthcheck/container_name/GPU-CUDA 設定）
- 確認 `localllm_prototype:latest` 是否存在，其 ENTRYPOINT/CMD/WORKDIR/EXPOSE/內建 llama.cpp
  server 設定為何
- 確認 `LLM_API` 目錄是否已存在、目標 GGUF 是否存在、Docker 引擎是否正常
- 確認 `Local_LLM` 容器目前是否仍在使用該 Image（避免衝突）

**2. 建立 Compose**
- 只複製原型 Compose 中負責 `llama-server` 的核心 service，harness/評測相關 service 一律不納入
- 僅修改：
  - service 名稱、`container_name` 皆改為 `LLM_API`（原為 `Local_LLM`，可改名故直接更名，
    避免與原專案撞名，也不會誤操作到 `Local_LLM` 容器）
  - 模型檔名 / model volume 對應路徑（沿用原本掛載結構 `models:/models`，只換檔名；
    若原型用容器內固定路徑如 `/model/xxx.gguf`，需先確認實際路徑，不得用猜的）
  - 對外 API port（若與 Local_LLM 衝突才需改；若可共存則直接沿用 8080）
  - llama.cpp 啟動參數中因模型不同而必須調整的項目（優先檢查 `-m/--model`、`-ngl`、
    `-c/--ctx-size`、batch/ubatch size、threads、parallel/slots、flash attention、KV cache、
    GPU offload、CUDA 參數），但第一階段只求「能啟動」，不做效能優化
- GPU/CUDA 設定（environment、deploy.resources.reservations）完整沿用，不自行調整
- 保持 image 為 `localllm_prototype:latest`（`build.context` 可保留亦可省略，仍以既有 image 為準）

**3. 啟動與驗證（依序，出錯需分層定位：Compose / Image / Volume-Path / GPU / 模型格式 / 
   llama.cpp 參數 / API，不可混在一起判斷）**
1. `docker compose config` 驗證語法、volume、image、model path、GPU 設定
2. 啟動並確認容器狀態為 running
3. 檢視 log，確認模型 `Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf` 成功 load
4. 測試 API（如 `/v1/models`、`/v1/chat/completions`）是否正常回應

## 禁止事項
不得修改 `Local_LLM` 或共用 Image、複製 GGUF 進 Image、建立重複 llama.cpp Image、任意增刪
service/GPU 設定、修改 Docker Desktop 設定、刪除既有 container/image/volume、執行破壞性
`docker prune` 或對非本專案跑 `docker compose down -v`、在未確認前猜測路徑或覆寫 ENTRYPOINT/CMD。

## 完成回報格式
1. LLM_API 是否建立成功
2. Compose 實際採用了哪些設定（可附差異表：保持不變 / 必須修改 / 新增項目）
3. Image 是否確實使用 `localllm_prototype:latest`
4. 模型是否成功掛載並載入
5. 與 Local_LLM 的實際差異（僅列差異）
6. Container 狀態（name / status / port / model path）
7. API 測試結果
8. 若未完成，明確指出卡在哪一層（Compose/Image/Volume/Model/GPU/llama.cpp/API），
   不得以「應該可以」作為完成判定

## 一句話原則
> 任何修改前先問：「這個設定原本在 Local_LLM 是怎麼做的？」——能沿用就沿用，不重新設計。
ㄇ