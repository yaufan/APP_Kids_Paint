# 部署與安裝：Android 和 iOS

> 目前版本 2.0.0：第二版，小鎮變成浮在天上的小島（見 [CHANGELOG](../CHANGELOG.md)）。

## 一頁看懂
| | 現在就能測試 | 上架商店 |
|---|---|---|
| **Android** | 下載 GitHub 自動打包的 APK，直接裝到手機 | Google Play 開發者帳號（一次 US$25）→ 封閉測試 12 人、14 天 → 申請正式上架 |
| **iOS** | 只有雲端模擬器（手動執行，截圖在 GitHub Actions） | Apple Developer Program（每年 US$99）→ 用雲端 Mac 打包 → TestFlight 裝到 iPhone → 送審上架 |

**沒有 Mac 也可以做 iOS**：打包在雲端的 Mac 上跑（GitHub Actions 或 Codemagic），你只需要一支 iPhone 來安裝測試。

---

## Android

### A. 現在就裝到手機（側載 APK）
最簡單：GitHub 專案 → **Releases** → 選最新版本 → 下載 `kids-paint-版本-arm64.apk`（不用解壓縮，也不會過期）。版本怎麼發行見 [versioning.md](versioning.md)。

最新版的網址固定是 <https://github.com/yaufan/APP_Kids_Paint/releases/latest>，出新版也不用換。用手機相機掃這個 QR code 就會打開：

<img src="download-qr.png" alt="最新版下載頁的 QR code" width="200">

專案是私人的時候，Releases 頁面和這個 QR code 都要先在手機瀏覽器**登入 GitHub** 才打得開。要給家人裝，就把 APK 用 LINE 或雲端硬碟傳過去。

從 0.19.0 起，每種手機晶片各有一個 APK（每個大約 35 MB，以前三種放在一起要 80 MB）：
| 檔名結尾 | 給哪種手機 |
|---|---|
| `-arm64.apk` | 一般手機（大多數 2017 年以後的手機）。先試這個。 |
| `-armv7.apk` | 很舊的手機：`arm64` 那個顯示「應用程式未安裝」時用這個。 |
| `-x86_64.apk` | 電腦上的 Android 模擬器、Intel 的 Chromebook。 |

想裝最新一次推送的測試版：
1. 打開 GitHub 專案 → **Actions** → 左邊選 **App** → 點最新一次綠色勾勾的執行。
2. 頁面最下方 **Artifacts** → 下載 `kids-paint-android-apk`（會是一個 zip）。
   - 用手機瀏覽器登入 GitHub 下載，或在電腦下載後用 LINE、Google 雲端硬碟傳到手機。
3. 解壓縮，點裡面的 `kids-paint-版本-建置號碼-arm64.apk`。測試版只有這一種；很舊的手機請用 Releases 的 `-armv7.apk`。
4. 手機會問要不要允許「安裝未知應用程式」：允許給你用來開檔的 APP（例如 Chrome 或「檔案」）。
5. 安裝完成，桌面會出現「畫畫小鎮」。

注意：
- 這個 APK 用測試金鑰簽章（見下面「簽章」）；以後換成 Google Play 版之前要先移除。
- Actions 的 Artifacts 保存 3 天；Releases 頁面的 APK 不會過期。
- 沒有 Android 手機：電腦（Windows 也可以）安裝 Android Studio，用裡面的模擬器開 `-x86_64.apk`。

### 簽章：同一把測試金鑰，新版才能直接蓋過舊版
Android 只讓「同一把金鑰簽的」新版 APK 直接更新舊版；金鑰不同，手機會說「應用程式未安裝」，只能先移除再裝，**移除時小朋友的畫也會一起刪掉**。

- **2.0.0 和以前的版本**：每次雲端打包都用一把臨時金鑰，所以每次換版本都要先移除。
- **之後的版本**：雲端打包用一把固定的測試金鑰，放在 GitHub 專案的 Secrets（設定 → Secrets and variables → Actions）：
  | Secret 名稱 | 內容 |
  |---|---|
  | `ANDROID_KEYSTORE_BASE64` | 金鑰檔 `kids-paint-test.p12` 轉成 base64 的文字 |
  | `ANDROID_KEYSTORE_PASSWORD` | 金鑰的密碼 |
- 從舊的臨時金鑰換到固定金鑰時要**最後移除一次**（先在家長模式把想留的畫存到相簿）；之後每一版都能直接更新，畫會留著。
- 每個 APK 打包完都會檢查是不是這把金鑰簽的（工作流程裡的 `TEST_KEY_SHA256`）。發行版本時沒有這兩個 Secret 或金鑰不對，**Release 會停下來不發行**；平常的 App 檢查只會出現黃色警告，改用臨時金鑰。
- 在自己的電腦打包（沒有設定 `KIDS_PAINT_KEYSTORE`）時用 Flutter 的 debug 金鑰，跟雲端版不能互相更新。
- 金鑰檔和密碼**不能放進程式碼**（看得到程式碼的人拿到，就能做出冒充的更新）。自己要另外備份，例如存在密碼管理器。
- 金鑰不見了：照下面做一把新的，換掉兩個 Secret 和兩個工作流程（`.github/workflows/app.yml`、`release.yml`）裡的 `TEST_KEY_SHA256`；手機要再移除一次。
  ```sh
  keytool -genkeypair -keystore kids-paint-test.p12 -storetype pkcs12 -alias kidspaint \
    -keyalg EC -groupname secp256r1 -validity 36500 -dname "CN=Hua Hua Town test key"
  base64 -w0 kids-paint-test.p12          # 貼到 ANDROID_KEYSTORE_BASE64
  keytool -list -v -keystore kids-paint-test.p12 -storetype pkcs12 | grep SHA256
  # 去掉冒號、改成小寫，就是 TEST_KEY_SHA256
  ```
- 這把是**測試金鑰**，不是 Google Play 的上傳金鑰；Play 商店版的簽章由 Google 保管，跟這把不同，所以換成商店版時要先移除。

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

## GitHub Actions 的免費額度
專案是私人的時候，雲端檢查用 GitHub 免費方案的額度；公開的專案不限時間，也不算額度。
- **每個月 2,000 分鐘**，每月 1 日歸零。Mac 主機的 1 分鐘算 10 分鐘。
- **沒有綁付款方式**，所以用完不會扣錢，而是全部停下來：每個檢查幾秒就失敗，訊息是「recent account payments have failed or your spending limit needs to be increased」。等下個月 1 日，或到設定裡綁付款方式、調高花費上限。
- 看用了多少：GitHub 右上角頭像 → **Settings** → **Billing and licensing** → **Usage**。

| 什麼時候 | 跑什麼 | 大約用掉 |
|---|---|---|
| 每次推送改到 `app/` | App 檢查（測試、截圖、打包 APK）。`main` 和工作分支是同一個提交，只跑一次 | 20 分鐘 |
| 發新版本 | 再加 Release（測試、打包、發布） | 20 分鐘 |
| 手動：Actions → **iOS Simulator** → Run workflow | iPhone 和 iPad 模擬器各走一次 | 32 分鐘 × 10 = 320 分鐘 |
| 只改文件 | 不跑 | 0 |

一個月大約可以推送 80～90 次，或推送 60 次再跑兩次 iPhone 模擬器。

**建置檔案（Artifacts）全部加起來只能放 500 MB**：
- 每次只留手機用的 arm64 APK，保存 3 天；截圖只在檢查失敗時上傳。
- 放滿時上傳會失敗，但檢查不會因此變紅。
- 要一次清空：Actions → **Clean up artifacts** → Run workflow（填 0 是全部刪掉；Releases 的 APK 不是建置檔案，不受影響）。

## 兩邊都要準備的
- **隱私權政策網頁**：專案是私人的，GitHub Pages 要付費方案才能用；可以改用 Google 協作平台、Notion 公開頁面等免費方式。
- **APP 圖示**（1024 × 1024）、商店截圖、介紹文字。
- **版本號**：`app/pubspec.yaml` 的 `version`；`+` 後面的建置號碼由雲端打包自動產生，每次都會變大，符合商店要求（見 [versioning.md](versioning.md)）。
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
