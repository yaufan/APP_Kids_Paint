# 畫畫小鎮 APP（Flutter）

給 2.5–5 歲小朋友的著色 APP，Android 與 iOS 共用同一套程式碼。設計依據：
- [產品功能規劃](../docs/product-plan.md)
- [技術架構](../docs/tech-architecture.md)

## 目前可以做的事（0.6.1）

畫面設計見 [design-v3.md](../docs/design-v3.md)，地圖規則見 [town-map.md](../docs/town-map.md)。

1. **小鎮地圖（首頁）**：小朋友自己的小鎮，可以拖動。第一天只有家，其他是空地；作品是圖釘，今天寄的會發光。點圖釘會看到這個地方的明信片。
   - 跟著手機時間變成白天、黃昏、晚上（窗戶亮燈、咕咕睡覺）。
   - 節日有裝飾，咕咕會送來節日著色圖。
   - 右下角的白紙可以直接畫畫。
   - 動物園和海洋館可以走進去：選一隻 APP 提供的動物來畫，畫好牠就住進去，自己走路、游泳。
2. **拍照**：用相機拍或從相簿選一張照片。
3. **魔法變身**：等待轉換時，小朋友的動物揮魔法棒，星星代替進度條。
4. **選風格**：「真實」和「可愛」兩張明信片，點一張就開始畫。
5. **著色**：明信片上有原照片做的郵票和郵戳；油漆桶（預設）、不會塗出線外的魔法蠟筆、12 色顏料、復原；每一筆都自動儲存。
6. **寄出**：選要寄到哪裡（4 個大圖示＋更多地方），蓋上「寄出」郵戳；第一次寄到的地方，建築會從空地長出來。
7. **明信片冊**：依地點分組，可以篩選最愛或某個地方；還沒寄出的畫也在這裡。
8. **家長確認**：國字數字題＋大數字鍵盤，答錯 3 次等 1 分鐘。
9. **家長模式**：小朋友、每天可以玩多久、替地方取名字、隱私與安全（刪除所有資料）、開放原始碼授權、版本號。

目前是**簡易版**（模糊＋邊緣偵測），讓整個流程先能動。下一步會換成 `prototypes/lineart` 驗證過的 DexiNed 版本。

## 程式架構

```text
lib/
  main.dart                 啟動：開資料庫、作品資料夾，交給 Riverpod
  app/                      APP 外殼
    app.dart                MaterialApp（繁體中文）
    router.dart             頁面路由（go_router）
    theme.dart              畫畫小鎮的配色、陰影、按鈕尺寸
    widgets.dart            胖按鈕、對話泡泡、明信片框、郵票、郵戳、紙背景
    art.dart                向量圖案清單與顯示（圖示、地點、動物、工具）
    celebration.dart        彩帶
    version.dart            版本號（打包時由 CI 帶入）
    strings.dart            家長看的文字；小朋友畫面的文字只給讀螢幕軟體用
  core/                     共用的資料層
    db/database.dart        資料表：小朋友、地點、作品、設定（drift / SQLite）
    storage/artwork_store.dart  每件作品一個資料夾：照片、線稿、區塊圖、筆畫、成品、縮圖
    repositories.dart       資料存取
    artwork_service.dart    建立、載入、自動儲存作品
    providers.dart          依賴注入（Riverpod）；時鐘也在這裡，測試可以換成晚上或節日
    town_time.dart          白天、黃昏、晚上（台北的日出日落表）
    festivals.dart          台灣節日和日期（農曆節日內建 2026～2037 年）
    creatures.dart          動物園、海洋館和裡面的 12 隻動物
  features/                 各功能
    town/                   小鎮地圖（首頁）、圖釘、地點卡；town_layout_data.dart 由設計程式產生
    capture/                拍照、選相簿
    lineart/                轉換引擎介面、簡易引擎、塗色區塊圖、魔法變身與選風格
    canvas/                 明信片著色畫面、油漆桶、魔法蠟筆、復原
    send/                   寄到哪裡、寄出慶祝
    album/                  明信片冊
    scene/                  動物園、海洋館：背景、動物的動作（motion.dart）
    parent/                 家長確認、家長模式、隱私與安全
test/                       自動測試（含手機／平板完整模擬操作與截圖）
integration_test/           在模擬器或真機上跑的同一套模擬操作
assets/fonts/               jf open 粉圓（OFL 授權）
assets/art/                 自己畫的向量圖（由 docs/design/v3/src/export_art.py 產生；小鎮每一層有白天、黃昏、晚上三版）
assets/pages/               節日和動物的著色圖（黑線白底 PNG，同一支程式產生）
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
