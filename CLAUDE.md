# 給 Claude 的專案規則

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
