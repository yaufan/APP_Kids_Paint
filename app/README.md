# Kids Paint APP（Flutter）

給 2.5–5 歲小朋友的著色 APP，Android 與 iOS 共用同一套程式碼。設計依據：
- [產品功能規劃](../docs/product-plan.md)
- [技術架構](../docs/tech-architecture.md)

## 目前可以做的事（第 1 階段骨架）

1. **首頁**：三個大圖示按鈕（拍照、我的作品、地圖），沒有文字；右上角小鎖頭是家長模式。
2. **拍照**：用相機拍或從相簿選一張照片。
3. **選風格**：並排顯示「真實」和「可愛」兩張著色圖，點一張就開始畫。
4. **著色**：
   - 油漆桶（預設）、不會塗出線外的魔法蠟筆
   - 12 個大色塊、復原
   - 每一筆都自動儲存
5. **我的作品**：作品格子牆，可以用愛心標成最愛。
6. **家長模式**（要先回答家長題目）：
   - 新增小朋友（動物頭像）
   - 設定每日使用時間
   - 隱私說明、刪除所有資料
7. **地圖日誌**：先放佔位畫面；資料庫已經準備好記錄地點。

> 轉換引擎目前是**簡易版**（模糊＋邊緣偵測），讓整個流程先能動。下一步會換成 `prototypes/lineart` 驗證過的 DexiNed 版本。

## 程式架構

```text
lib/
  main.dart                 啟動：開資料庫、作品資料夾，交給 Riverpod
  app/                      APP 外殼
    app.dart                MaterialApp（繁體中文）
    router.dart             頁面路由（go_router）
    theme.dart              幼兒用的顏色、超大按鈕尺寸
    widgets.dart            貼紙按鈕、貼紙卡片、頭像、等待動畫、家長鎖頭
    scene.dart              首頁繪本場景、點點紙背景
    mascot.dart             吉祥物「蠟筆寶寶」
    strings.dart            家長看的文字；小朋友畫面的文字只給讀螢幕軟體用
  core/                     共用的資料層
    db/database.dart        資料表：小朋友、地點、作品、設定（drift / SQLite）
    storage/artwork_store.dart  每件作品一個資料夾：照片、線稿、區塊圖、筆畫、成品、縮圖
    repositories.dart       資料存取
    artwork_service.dart    建立、載入、自動儲存作品
    providers.dart          依賴注入（Riverpod）
  features/                 各功能
    home/                   首頁、切換小朋友
    capture/                拍照、選相簿
    lineart/                轉換引擎介面、簡易引擎、塗色區塊圖、風格選擇
    canvas/                 著色畫布、油漆桶、魔法蠟筆、復原
    gallery/                作品集、我的最愛
    map_journal/            地圖日誌（佔位）
    parent/                 家長關卡、家長模式
test/                       自動測試（含手機／平板完整模擬操作與截圖）
integration_test/           在模擬器或真機上跑的同一套模擬操作
assets/fonts/               jf open 粉圓（OFL 授權）
```

**重要設計**
- **轉換引擎可以替換**：APP 只認 `LineArtEngine` 介面；換成 DexiNed 版或雲端 Q 版時，只要改 `core/providers.dart` 一行。
- **不漏色**：`RegionMap` 會在線條缺口處設一條看不見的邊界，原理和原型相同。
- **畫作就是一串動作**：每次塗色都記成一個動作（`ops.json`）。復原、自動儲存、之後的縮時重播都靠它。
- **隱私**：沒有帳號、沒有網路功能；照片和作品只存在 APP 自己的資料夾裡。

## 開發

```bash
flutter pub get
dart run build_runner build   # 改了 lib/core/db/database.dart 之後要重新產生
flutter analyze
flutter test
flutter run                   # 接上 Android 手機或模擬器
```

每次推送到 GitHub，**Actions** 會自動：
- 檢查程式、執行測試
- 跑一次完整的模擬操作，產生手機和平板截圖（Artifacts：`app-screenshots`）
- 建置 Android APK（Artifacts：`kids-paint-android-apk`）

**iPhone／iPad 模擬器測試**（`.github/workflows/ios.yml`）：
- 會在 iPhone 和 iPad 模擬器上跑同一套模擬操作並截圖（Artifacts：`ios-simulator-screenshots`）
- 雲端 Mac 主機消耗的免費時間是一般的 10 倍，所以只在三種情況執行：合併到 `main`、手動觸發，或 commit 訊息含 `[ios]`
- 本機執行：`flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart -d 裝置ID`

這個 APK 用除錯金鑰簽署，可以直接裝到 Android 手機測試，但不能上架 Google Play。
