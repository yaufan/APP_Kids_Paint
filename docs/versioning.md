# 版本管理

## 版本號
- **寫在哪裡**：`app/pubspec.yaml` 的 `version: 0.4.0+1`。`+` 前面是版本號，後面的建置號碼在打包時會自動換掉。
- **格式**：`主版.次版.修正`，規則見 [CHANGELOG.md](../CHANGELOG.md)。
- **建置號碼**：雲端打包時用 git 的提交次數，只會越來越大，符合 Google Play 和 App Store 的要求。
- **APP 裡看得到**：家長模式最下面「版本 0.4.0 (123)」。

## 每個版本在哪裡
| 東西 | 位置 |
|---|---|
| 版本說明 | 專案根目錄的 `CHANGELOG.md` |
| 程式的版本快照 | git 標籤 `v0.4.0`，在 GitHub 的 **Tags** |
| 可以安裝的 APK | GitHub 的 **Releases** 頁面，每個版本一個，不會過期 |
| 每次推送的測試版 APK | GitHub Actions → App → 該次執行的 Artifacts（保存 30 天） |

## 發新版本的步驟
1. 改 `app/pubspec.yaml` 的版本號，例如 `0.4.0` → `0.5.0`。
2. 在 `CHANGELOG.md` 最上面加一段 `## 0.5.0 — 日期`，寫這版改了什麼。
3. 推送。雲端會檢查：APP 裡的版本號、pubspec、CHANGELOG 三個要一致（`app/test/version_test.dart`）。
4. 到 GitHub → **Actions** → **Release** → **Run workflow**，選要發行的分支，按綠色按鈕。
   - 會自動打包 APK、建立標籤 `v0.5.0`，在 **Releases** 放上 APK 和這版的說明。
   - 不是從 `main` 發行的版本會標成「預先發行版」（Pre-release）。
   - 這個版本號已經發行過的話會停下來，提醒你先改版本號。

## 回到舊版本
- 看舊版程式：GitHub → Tags → 選版本。
- 裝舊版 APK：GitHub → Releases → 選版本 → 下載 APK。手機上要先移除新版（Android 不能直接降版）。
