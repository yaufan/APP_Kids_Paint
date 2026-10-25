# 部署與安裝：Android 和 iOS

> 目前程式裡的介面還是 v2（3D 玩具風）。v3「畫畫小鎮」還只是設計稿，做進 APP 後才會在手機上看到。

## 一頁看懂
| | 現在就能測試 | 上架商店 |
|---|---|---|
| **Android** | 下載 GitHub 自動打包的 APK，直接裝到手機 | Google Play 開發者帳號（一次 US$25）→ 封閉測試 12 人、14 天 → 申請正式上架 |
| **iOS** | 只有雲端模擬器（截圖在 GitHub Actions） | Apple Developer Program（每年 US$99）→ 用雲端 Mac 打包 → TestFlight 裝到 iPhone → 送審上架 |

**沒有 Mac 也可以做 iOS**：打包在雲端的 Mac 上跑（GitHub Actions 或 Codemagic），你只需要一支 iPhone 來安裝測試。

---

## Android

### A. 現在就裝到手機（側載 APK）
最簡單：GitHub 專案 → **Releases** → 選最新版本 → 下載 `kids-paint-版本.apk`（不用解壓縮，也不會過期）。版本怎麼發行見 [versioning.md](versioning.md)。

想裝最新一次推送的測試版：
1. 打開 GitHub 專案 → **Actions** → 左邊選 **App** → 點最新一次綠色勾勾的執行。
2. 頁面最下方 **Artifacts** → 下載 `kids-paint-android-apk`（會是一個 zip）。
   - 用手機瀏覽器登入 GitHub 下載，或在電腦下載後用 LINE、Google 雲端硬碟傳到手機。
3. 解壓縮，點裡面的 `kids-paint-版本-建置號碼.apk`。
4. 手機會問要不要允許「安裝未知應用程式」：允許給你用來開檔的 APP（例如 Chrome 或「檔案」）。
5. 安裝完成，桌面會出現「Kids Paint」。

注意：
- 這個 APK 用測試用的金鑰簽章，以後換成 Google Play 版之前要先移除。
- Actions 的 Artifacts 保存 30 天；Releases 頁面的 APK 不會過期。
- 沒有 Android 手機：電腦（Windows 也可以）安裝 Android Studio，用裡面的模擬器開 APK。

### B. 上架 Google Play
1. **註冊開發者帳號**：[Google Play Console](https://play.google.com/console)，一次性 US$25，要驗證身分。
   - 個人帳號：用身分證件驗證。
   - 公司帳號：需要鄧白氏編碼（D-U-N-S），申請可能要一個月；好處是**不用做 12 人封閉測試**。
2. **正式簽章**（我可以幫你做 CI 的部分）：
   - 產生一把「上傳金鑰」（keystore），放進 GitHub Secrets，**不能放進程式碼**，自己也要另外備份。
   - CI 改成產生 `.aab`（`flutter build appbundle`）並用上傳金鑰簽章。
   - 在 Play Console 開啟「Play 應用程式簽署」：正式金鑰由 Google 保管，上傳金鑰遺失可以申請重設。
3. **建立 APP**：名稱、預設語言（繁體中文）、免費。
4. **必填的表單**：
   - 隱私權政策網址
   - 目標對象：5 歲以下（會適用家庭政策，見 [safety-privacy.md](safety-privacy.md)）
   - 內容分級問卷
   - 資料安全：不收集、不分享
   - 廣告：沒有
5. **測試**：
   - 內部測試：最多 100 人，上傳後很快就能從 Play 商店安裝，適合自己和家人先試。
   - 封閉測試：2023 年 11 月 13 日以後建立的個人帳號，要找**至少 12 位測試者、連續 14 天**，才能申請正式上架。人數中途少於 12 人，14 天會重新計算。
6. **申請正式版**：填測試心得 → 審核（兒童 APP 可能比較久）→ 選擇發行國家（台灣）→ 上架。

---

## iOS（沒有 Mac 的做法）

### 為什麼一定要付費帳號
免費的 Apple ID 只能用 Mac 上的 Xcode 裝到自己的手機，而且每 7 天就要重裝。沒有 Mac 的話，只能走付費帳號＋TestFlight。

### 步驟
1. **加入 Apple Developer Program**：每年 US$99（會用新台幣計價）。
   - 在 iPhone 下載「Apple Developer」App 就可以註冊，不需要 Mac。
   - Apple ID 要先開啟雙重認證。個人帳號通常一天內通過。
2. **在 App Store Connect 建立 APP**：
   - Bundle ID：`com.yaufan.kidsPaint`（程式裡已經設定好）
   - APP 名稱：例如「畫畫小鎮」，不能和別人重複
3. **建立 App Store Connect API 金鑰**（使用者與存取 → 整合 → App Store Connect API）：
   - 會拿到 `.p8` 檔、Key ID、Issuer ID
   - 放進 GitHub Secrets，雲端 Mac 就能自動簽章、上傳，你不用碰任何憑證
4. **雲端打包**（我來設定，兩種選一種）：
   - **GitHub Actions**：專案已經有 iOS 模擬器流程，再加一個「打包 → 上傳 TestFlight」。私人專案的 Mac 時間是 10 倍計算，免費額度大約只夠每月十次左右的打包。
   - **Codemagic**：專門給 Flutter 的雲端打包服務，每月有 500 分鐘免費的 Mac 時間，簽章可以用網頁設定。
5. **TestFlight 安裝**：
   - iPhone 安裝「TestFlight」App。
   - 內部測試（你的團隊成員）：上傳後處理完就能裝，不用審核。
   - 外部測試（最多 1 萬人，例如親友）：第一次要經過 Beta 審核，用邀請連結就能裝。
6. **上架 App Store**：
   - 截圖：iPhone（6.9 吋）和 iPad（13 吋）兩種，可以用我們的模擬器流程自動產生
   - 說明文字、關鍵字、隱私權政策網址
   - 隱私標示：不收集資料
   - 類別：兒童，年齡「5 歲以下」（審核比較嚴：家長關卡、不能有第三方廣告或分析）
   - 送審，通常一到幾天

---

## 兩邊都要準備的
- **隱私權政策網頁**：專案是私人的，GitHub Pages 要付費方案才能用；可以改用 Google 協作平台、Notion 公開頁面等免費方式。
- **APP 圖示**（1024 × 1024）、商店截圖、介紹文字。
- **版本號**：`app/pubspec.yaml` 的 `version: 1.0.0+1`，每次上傳商店，`+` 後面的數字都要加 1。
- **金鑰與帳號備份**：Android 上傳金鑰、Apple API 金鑰都要存在安全的地方（例如密碼管理器），不要放進 git。

## 費用
| 項目 | 費用 |
|---|---|
| Google Play 開發者帳號 | US$25，一次 |
| Apple Developer Program | US$99，每年 |
| GitHub Actions 雲端 Mac | 免費額度內 0 元；私人專案 Mac 時間 10 倍計算 |
| Codemagic（選用） | 每月 500 分鐘免費 |

## 參考資料
- [Google Play Console](https://play.google.com/console)
- [Google Play 封閉測試規定整理（第三方）](https://extendsclass.com/blog/google-plays-closed-testing-requirement-what-developers-need-to-know-in-2026)
- [Apple Developer Program 費用與註冊整理（第三方）](https://studio.adalo.com/blog/apple-developer-program-guide)
- [Codemagic 文件](https://docs.codemagic.io/getting-started/about-codemagic/)
- [用 GitHub Actions 與 fastlane 自動發布 Flutter](https://www.freecodecamp.org/news/how-to-automate-flutter-releases-with-fastlane-and-github-actions/)
- [在 CI 用 API 金鑰自動簽章 Flutter iOS（Zenn）](https://zenn.dev/yorifuji/articles/build-automatically-manage-singin-on-ci)
