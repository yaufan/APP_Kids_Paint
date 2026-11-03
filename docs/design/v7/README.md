# APP 圖示（2.2.0）

手機桌面上的圖示：浮在天上的小島和家（地圖上「家」那座島）、後面一道彩虹，還有畫出它的紅蠟筆。

- `icon.py`：三個構想都畫在 1024 × 1024 的整塊正方形上，手機會自己裁成圓形或圓角方形；重要的東西都在中間三分之二。
  - `island`（採用）：浮空小島＋彩虹＋紅蠟筆，藍天背景。
  - `house`：珊瑚紅的紙上用白色蠟筆畫的房子、彩虹和星星（APP 裡原本小 logo 的放大版）。
  - `bear`：小熊（預設的動物好朋友）趴在畫了彩虹的明信片上，黃色背景。
- `icon_island.png`：採用的那一張，給文件和商店頁用。

## 指令
```
python3 icon.py preview 輸出資料夾    # 三個構想的 PNG
python3 icon.py export island        # 寫進 Android（各種密度、圓形、Android 8 以上的分層圖示）和 iOS 的 AppIcon
```
需要 Node.js 和 Playwright（和 v6 一樣，用 `v6/render_alpha.js` 轉 PNG）。

## 寫到哪裡
- Android：`app/android/app/src/main/res/mipmap-*/ic_launcher.png`、`ic_launcher_round.png`、`ic_launcher_foreground.png`、`ic_launcher_background.png`，以及 `mipmap-anydpi-v26/ic_launcher.xml`（分層圖示：背景一整片，畫放在中間 72dp）。`AndroidManifest.xml` 有 `android:roundIcon`。
- iOS：`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`（沒有透明，App Store 規定）。
