# 給 Claude 的專案規則（畫畫小鎮）

這份是這個專案的「記憶」：使用者的習慣、做事的規則、工具和流程。每個在這個專案裡工作的 Claude 都要照著做。使用者之後也會開發別的 APP，那些是別的專案，這裡只記畫畫小鎮的事。

## 和使用者合作
- **一律用繁體中文回覆**，用白話說明，少用技術名詞；要用的話順便解釋。
- 使用者用手機上的 Claude App 看對話，**打不開 artifact 連結**。圖片、影片、聲音、QR code 都用傳檔案的方式（SendUserFile）給。
- 每次做完一版，給使用者：
  - 新功能的示範影片片段：從 `app/build/demo/demo.mp4` 照 `chapters.txt` 剪出來。
  - 手機截圖：`app/build/screenshots/phone/`，幾張併成一張。
  - 發布後的下載 QR code：直接下載這一版 arm64 APK 的一張，加上最新版頁面的 `docs/download-qr.png`。
- 有要使用者決定的事（例如選圖示、要不要發布），把選項做成圖或檔案給他看，再問。
- 不要開 pull request，除非使用者要求。
- 用了網路搜尋，回覆最後附「Sources:」和連結。
- 回答前先確認事實（看程式、看 GitHub），不要猜。

## 使用者和這個 APP
- 使用者在台灣，是家長；APP 給 2.5～5 歲的小朋友。測試用的是 Android 手機，沒有 Mac。
- 「畫畫小鎮」：拍照或選角色，變成著色圖，塗好寄到小鎮的地方，或住進動物園這些園區。
- 第二版（2.0 起）的小鎮是一群浮在天上的小島。
- 不連網、不定位、沒有廣告和追蹤（`docs/safety-privacy.md`）。
- 授權：保留一切權利（`LICENSE`）。專案曾經是公開的，使用者打算改回私有。
- 版本紀錄在 `CHANGELOG.md`，寫給家長看，白話中文。版本號怎麼加見下面「發新版本」。
- 不公開的文件（產品計畫、功能點子、收費、競品分析）放在使用者的 Google 雲端硬碟，資料夾「畫畫小鎮（不公開文件）」（id `1FLxrsyv4pPZLciXvD9MxVqG7iZdaKlBX`）。功能點子清單是 `feature-ideas.md`，更新方式是上傳新的一份、把舊的移到垃圾桶。**不要放進 git。**

## 啟動 GitHub Actions 之前，一定要先問使用者
專案是私人的時候，GitHub Actions 用的是帳號的免費額度：每月 2,000 分鐘（這個帳號所有私有專案共用，每月 1 日歸零；Mac 主機的 1 分鐘算 10 分鐘），建置檔案（Artifacts）全部加起來 500 MB。帳號沒有綁付款方式，用完就全部停下來，要等下個月。細節見 [docs/deployment.md](docs/deployment.md) 的「GitHub Actions 的免費額度」。

**任何會啟動 Actions 的動作，都要先問使用者，等使用者同意才做。** 專案是公開的時候也一樣要問（公開不扣額度，問的時候說明這點即可）。會啟動 Actions 的動作：
- 推到 `main`，而且改到下面任何一個（照 `.github/workflows/*.yml` 的 `on:`）：
  - `app/**` 或 `.github/workflows/app.yml`：跑 App，約 20 分鐘。
  - `app/pubspec.yaml`、`CHANGELOG.md` 或 `.github/workflows/release.yml`：跑 Release。發新版本約 20 分鐘；版本沒變約 1 分鐘。
- 手動執行（Run workflow）任何工作流程：iOS Simulator 約 320 分鐘（iPhone 和 iPad 各 16 分鐘 × 10），Clean up artifacts 約 1 分鐘，Release 約 20 分鐘。
- 重新執行（re-run）任何一次執行。
- 開 pull request（會跑 App）。

問的時候說清楚四件事：
1. 會跑哪些工作流程、為什麼要跑。
2. 這次大約用掉幾分鐘。
3. 這個月到目前大約用了多少：用 GitHub 工具列出這個月（UTC 每月 1 日起）這個專案的執行，把每個 job 的時間加起來（每個 job 進位到整分鐘，macOS 乘 10）。也請使用者到 GitHub 右上角頭像 → **Settings** → **Billing and licensing** → **Usage** 看正確數字，因為帳號其他私有專案也用同一個額度，這裡算不到。
4. 跑完大約還剩多少。

不用問、可以直接做的：
- 推到工作分支（例如 `claude/...`）：工作流程只在 `main` 上自動執行，推工作分支不會啟動任何 Actions。改好的東西先 commit、推工作分支。
- 推到 `main` 但沒有改到上面那些檔案（例如只改 `docs/`、`README.md`、`CLAUDE.md`）：不會啟動 Actions。
- 查看執行結果、記錄和建置檔案（只讀，不會啟動）。

使用者同意之後，照 [docs/versioning.md](docs/versioning.md) 的步驟推 `main`。

確認的字眼要明確：使用者說「推到 main」「發布吧」「好」（回答「可以推到 main 嗎」）才推。看不出是不是同意，就再問一次。

## 發新版本
- 版本號：
  - 主版：整個 APP 大改版時加 1（0.x 是第一版小鎮，2.x 是第二版浮空小島，1.x 跳過不用）。
  - 次版：加了新功能或新介面。
  - 修正：只修問題。
- 三個地方要一致（`app/test/version_test.dart` 會檢查）：`app/pubspec.yaml` 的 `version`、`app/lib/app/version.dart` 的預設值、`CHANGELOG.md` 最上面的一段。
- 先在本機跑完測試和完整流程，commit、推工作分支，再問使用者能不能推 `main`。同意後 `git push origin HEAD:main`，Release 自動打包三個 APK（arm64、armv7、x86_64）放上 Releases。
- 發布後確認 Release 成功，再給使用者 QR code（見上面）。

## 簽章（Android）
- APK 用一把固定的測試金鑰簽章，新版才能直接蓋過舊版安裝，小朋友的畫才會留著（2.1.0 起）。
- 金鑰放在 GitHub 專案的 Actions Secrets：`ANDROID_KEYSTORE_BASE64` 和 `ANDROID_KEYSTORE_PASSWORD`（2026-11-03 加好）。工作流程裡的 `TEST_KEY_SHA256` 是它的指紋，每個 APK 都會檢查。
- **金鑰檔和密碼絕對不能放進 git**（`.gitignore` 擋了 `*.p12`、`*.jks`、`*.keystore`），備份在使用者那裡。不見的話照 `docs/deployment.md` 的「簽章」重做一把；手機要再移除一次。
- Release 沒讀到 Secret 會停下來不發布。之前遇過名字放錯地方：要放在 Actions → **Secrets** 分頁的 **Repository secrets**，不是 Variables 或 Environment。

## 在雲端機器上開發
- Flutter 3.47.8 在 `/home/user/flutter/bin`（新的機器上可能要先裝）。這裡沒有 Android SDK，APK 只在 GitHub Actions 打包。
- **跑測試一律用 `tools/run_tests.sh LOG 測試檔...`**：它會暫時在 `app/pubspec.yaml` 加 `hooks: user_defines: sqlite3: source: system`，跑完一定拿掉。**這段絕對不能 commit**；commit 前確認 `grep -c 'source: system' app/pubspec.yaml` 是 0。
- 測試跑著的時候不要改 `app/lib`、`app/test`、`app/pubspec.yaml`。
- 測試有三種：
  - 單元和畫面測試：`app/test/*.dart`，不含 `flow_test.dart`。
  - 完整流程：`test/flow_test.dart`，手機和平板各走一次，截圖在 `app/build/screenshots/`，約 13 分鐘。
  - 示範影片：`test/demo/demo_video_test.dart --dart-define=DEMO=true`，輸出 `app/build/demo/demo.mp4` 和 `chapters.txt`（10 fps 的格數），約 7 分鐘。
  - 完整流程和示範影片可以一起跑（TIMEOUT=3000）。
- 分析：`flutter analyze` 要零問題。不要對整個檔案跑 `dart format`。
- 截圖和示範影片的時間是用 `clockProvider` 設的；白天晚上釘在真正的時間（`dayCycleProvider.overrideWithBuild(... DayCycle.real)`）。
- 這台機器連不到 tinyurl.com、is.gd、docs.github.com；pypi.org 可以（`pip install segno` 等）。沒有 gh 指令，GitHub 用 MCP 工具。
- QR code：`python3 tools/make_qr.py 網址 輸出.png 標題 說明 印出的網址`，做完用 OpenCV 解碼確認。

## 圖、聲音、圖示都是程式產生的
- 小鎮和地方的圖：
  - `docs/design/v3/src/`：第一版小鎮、角色、圖示。
  - `docs/design/v5/`：餵食的碗這些。
  - `docs/design/v6/islands.py`：浮空小島。`python3 islands.py export` 寫進 `app/assets/art/islands/` 和 `island_layout_data.dart`；`preview` 可以先看。
- 聲音：`docs/design/sounds/make_sounds.py` 合成全部聲音。新的聲音用自己的亂數產生器，舊的聲音才會一模一樣；重新產生後 `git status` 只該多出新檔。
- APP 圖示：`docs/design/v7/icon.py`（用的是 `island`：浮空小島＋彩虹＋紅蠟筆），`export island` 寫進 Android 和 iOS。
- SVG 轉 PNG 用 `docs/design/v6/render_alpha.js`（Node＋Playwright，機器上有 Chromium）。

## Git
- 在系統指定的 `claude/...` 工作分支上開發，commit 完就推這個分支；推 `main` 見上面的 Actions 規則。
- commit 訊息用英文寫清楚改了什麼和為什麼，結尾加系統要求的署名行。不要寫模型名稱；不要在訊息裡寫 `[ios]`。
- 不能 commit：金鑰、密碼、pubspec 的 sqlite 那段、不公開的文件。

## 目前的狀態（2026-11-04）
- 最新版 2.2.0：縮時的白天晚上（預設一天 10 分鐘）、APP 自己的圖示、可以選的背景音。前一版 2.1.0：畫筆一碰就畫、放大鏡、抓起角色換位置、晚上變亮、空地移到外圍。
- 使用者用 Releases 的 APK 在 Android 手機上測試，看完會再提想改的地方；每次照上面的流程改、測、問、發布。
- 專案目前是公開的，使用者打算改成私有；改了之後 Releases 和 QR code 要先在手機瀏覽器登入 GitHub 才打得開。
