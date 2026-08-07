# PsyGuard AI

[English](./README.md) | [繁體中文](./README.zh-TW.md)

## 專案簡介

PsyGuard AI 是一個以 Flutter 製作的心理健康陪伴應用程式 MVP，提供 AI 陪伴對話、每日覺察、睡眠紀錄、風險觀察與趨勢分析。現階段專案主體位於 `psyguard_ai_app`，採本地資料庫保存使用者資料，AI 對話則透過 OpenAI 相容 API 呼叫模型。

## 功能列表

- `AI 陪伴`：以心理輔導師風格進行對話，會帶入先前對話脈絡。
- `上下文記憶`：聊天會讀取歷史訊息，必要時把舊內容壓縮成摘要後再續聊。
- `高風險保護`：偵測高風險語句時優先導向安全流程與真人求助資源。
- `每日覺察`：記錄心情、壓力、能量與備註。
- `睡眠紀錄`：記錄睡眠時長、入睡時間與睡眠困難程度。
- `趨勢分析`：以圖表與 AI 報告呈現近期身心變化。
- `本地儲存`：聊天、紀錄與風險快照保存在本地 SQLite。
- `語言設定`：可在設定頁切換英文與繁體中文，預設為英文，並同步影響 AI 回覆語言。
- `語音設定`：可在設定頁調整 AI 回覆的語音播放速度。

## 技術架構

- `Frontend`：Flutter
- `狀態管理`：Riverpod
- `路由`：GoRouter
- `資料庫`：Drift + SQLite
- `網路層`：Dio
- `語音功能`：`speech_to_text`、`flutter_tts`
- `AI 介接`：OpenAI 相容 `chat/completions` API

## 專案結構

```text
.
├── README.md
├── README.zh-TW.md
├── LICENSE
└── psyguard_ai_app
    ├── README.md
    ├── lib
    ├── test
    ├── integration_test
    └── pubspec.yaml
```

## 本地測試教學

1. 進入 App 目錄：
   ```bash
   cd psyguard_ai_app
   ```
2. 安裝依賴：
   ```bash
   flutter pub get
   ```
3. 重新產生 Drift 與測試所需程式碼：
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. 執行靜態檢查：
   ```bash
   flutter analyze
   ```
5. 執行測試：
   ```bash
   flutter test
   ```
6. 若更新 App icon，重新產生各平台 icon：
   ```bash
   cd psyguard_ai_app
   dart run flutter_launcher_icons
   ```
7. 若要驗證 Web 建置：
   ```bash
   cd psyguard_ai_app
   flutter build web
   ```

## 環境變數

請在 `psyguard_ai_app/.env` 設定以下變數：

```env
API_BASE_URL=https://api.openai.com
API_KEY=your_api_key
AI_MODEL=gpt-4o-mini
APP_ENV=dev
```

說明：

- `API_BASE_URL`：OpenAI 相容 API 的 base URL
- `API_KEY`：模型服務 API 金鑰
- `AI_MODEL`：對話與分析共用的模型名稱
- `APP_ENV`：執行環境識別，例如 `dev`、`staging`、`prod`

## Coolify 部署教學

目前此儲存庫只有 Flutter 用戶端，沒有可直接部署到 Coolify 的後端服務或容器化設定，因此本專案尚無已驗證的 Coolify 部署流程。若後續拆出獨立 API 或 Web 服務，應補上：

- `Dockerfile` 或可部署映像設定
- Coolify 服務建立步驟
- 需要的環境變數
- 健康檢查與啟動指令

## 前端 / 後端詳細文件連結

- 前端 App 文件：[psyguard_ai_app/README.md](./psyguard_ai_app/README.md)
- 後端文件：目前沒有獨立後端資料夾
