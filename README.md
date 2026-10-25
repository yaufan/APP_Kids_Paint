# Kids Paint（暫名）

給 **2.5–5 歲** 小朋友的著色 APP（Android 先行，iOS 隨後），台灣市場：
**拍下生活中的東西 → 變成專屬著色圖 → 塗上顏色 → 收進「我的城市地圖」，成為成長回憶。**

## 主要功能
- 拍照轉線稿：**真實風格**（保留原貌的黑線圖框）／**可愛風格**（圓滑外形＋可愛表情＋貼紙風）
- 幼兒友善畫布：油漆桶、不出界的魔法蠟筆、亮粉、印章，零文字操作
- 地圖日誌：可愛風格城市地圖，記錄在哪裡畫了什麼
- 作品集：分類泡泡、我的最愛
- 經家長確認後分享到 LINE、FB、IG，同時推廣 APP

## 文件
- [產品功能規劃](docs/product-plan.md)：已確認決策、幼兒操作原則、功能清單、開發階段、待決定事項
- [技術架構建議](docs/tech-architecture.md)：Flutter、線稿轉換、畫布引擎、資料模型、沒有 Mac 的上架方式
- [線稿轉換原型](prototypes/lineart/README.md)：第 0 階段驗證程式與測試結果
- [APP 程式](app/README.md)：Flutter APP 的架構與開發方式
- [視覺設計](docs/design.md)：3D 玩具風的設計原則、配色、元件與截圖
- [參考 APP 研究](docs/design-references.md)：Pok Pok、Toca Boca、Crayola 等上架 APP 的設計做法
- [介面方向提案](docs/design-directions.md)：畫畫小鎮、畫畫桌、蠟筆怪獸三個方向
- [視覺設計 v3：畫畫小鎮（完整版）](docs/design-v3.md)：選定方向 A 的所有畫面、流程、動畫與設計規範
- [地圖怎麼運作](docs/town-map.md)：小朋友自己的小鎮、12 種地點、小鎮會長大、不使用定位
- [安全與隱私設計](docs/safety-privacy.md)：資料只在手機、權限、家長關卡、安全分享、上架規定
- [部署與安裝](docs/deployment.md)：Android 側載與 Google Play 上架、沒有 Mac 怎麼用 TestFlight 和上架 App Store

## 目前狀態
- **第 0 階段（技術驗證）**：
  - 線稿轉換原型：真實、可愛 v1、Q 版 v2 都已試做
  - 還在等真實照片測試
- **第 1 階段（MVP）**：Flutter APP 骨架已建立，可以完整走一次：拍照 → 選風格 → 著色 → 作品集。轉換引擎目前是簡易版。
- **介面**：3D 玩具風 v2，參考 Pok Pok、Toca Boca、Crayola 等上架 APP 重新設計。
- 每次推送都會在 GitHub Actions 自動測試，並建置可安裝的 Android APK。
