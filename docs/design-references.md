# 參考上架 APP 的設計研究

> 2026-10 整理。目的：v1「繪本貼紙風」被評為「太過簡陋」，所以先看市面上做得好的兒童 APP，找出值得借用的做法，再做 v2「3D 玩具風」。

## 看了哪些 APP

| APP | 對象 | 值得學的地方 | 我們怎麼用 |
|---|---|---|---|
| **Pok Pok**（Apple Design Award 2021 Delight & Fun） | 2–7 歲 | 幾乎沒有文字；整個畫面像一個可以摸、可以戳的實體玩具；配色和符號統一，看起來平靜、不吵 | 所有按鈕都是「玩具方塊」：按下會被壓扁再彈回來；全 APP 共用一套柔和配色 |
| **Toca Boca**（Toca Builders 等） | 學齡前 | 用**角色**取代選單：小朋友記得「哪個角色會做什麼」，不用找按鈕；一個畫面只放少數幾個選擇 | 小朋友選的 3D 動物就是嚮導：站在首頁山丘上，用對話框「指」相機；首頁只有 3 個大按鈕 |
| **Crayola Create and Play** | 學齡前 | 工具看起來像真的美術用品；用白色方塊裡的常見符號（油漆桶、地圖）當入口 | 工具是白色方塊加 3D 圖示（油漆桶、蠟筆）；調色盤是一盒立體蠟筆，選中的那支會跳出來 |
| **Bimi Boo 畫畫**（2–5 歲） | 2–5 歲 | 依主題分類的大量著色頁；鉛筆、刷子、噴漆、蠟筆、彩色筆、粉筆等多種工具；「魔法上色」；離線可用 | 多種畫筆、主題範本列入路線圖；離線優先已經做到 |
| **Yateland 著色遊戲**（2–6 歲） | 2–6 歲 | 完成任務會解鎖新筆刷、貼紙並放**煙火**；作品存在個人作品集 | 離開畫布時放彩帶＋拉炮慶祝；作品集像貼在牆上的照片 |
| **Sago Mini World** | 2–6 歲 | 柔和的聲音與較慢的動畫，比較安靜 | 動畫都用慢一點、彈性的曲線，沒有閃爍 |

## 共同規律（v2 的設計原則）
1. **沒有要讀的字**：小朋友看到的只有圖。文字只給讀螢幕軟體與家長。
2. **每樣東西都摸得到**：立體、有厚度、有陰影；按下去有回饋（壓扁、彈回）。
3. **角色帶路**：用小朋友自己的動物當嚮導，而不是箭頭或文字提示。
4. **一個畫面 3–5 個選擇**：首頁 3 個、拍照頁 2 個、風格 2 個。
5. **完成要慶祝**：做完一張畫要有明顯的獎勵感（彩帶、星星）。
6. **立體插圖統一風格**：v1 的程式手繪圖示看起來像暫代品，所以改用一整套風格一致的 3D 插圖（Microsoft Fluent Emoji 3D，MIT 授權，可商用）。

## 還沒做、但值得跟進
- 按鈕音效、完成音效（Pok Pok 用真實積木錄音）。
- 國語語音嚮導（角色開口說話）。
- 主題範本庫（Bimi Boo 有 11 個主題、176 張）。
- 解鎖新筆刷／貼紙當作獎勵（Yateland）。
- 正式上架前請插畫家畫專屬角色與 APP 圖示，取代 Fluent Emoji。

## 資料來源
- Pok Pok：[Apple Design Award 介紹](https://apple.co/3f5feSk)、[TapSmart 評測](https://www.tapsmart.com/games/kids-family/pok-pok-playroom-review/)、[Pok Pok 新聞資料](https://www.playpokpok.com/press/press-kit/)、[Sketch 個案研究](https://sketch.com/blog/pok-pok)
- Toca Boca：[MacStories：Characters As An Interface](https://www.macstories.net/linked/characters-as-an-interface/)、[Joan Ganz Cooney Center：Toca Builders](https://joanganzcooneycenter.org/?p=10255)
- Crayola：[Common Sense Media 評測](https://www.commonsensemedia.org/app-reviews/crayola-create-and-play)、[Jenny's Crayon Collection 評測](https://www.jennyscrayoncollection.com/2018/12/crayola-create-and-play-app-review.html?m=0)
- Bimi Boo：[App Store](https://apps.apple.com/app/id1001555097)
- Yateland：[App Store](https://apps.apple.com/app/id6751708435)
- Sago Mini World：[App Store](https://apps.apple.com/ca/app/sago-mini-world-kids-games/id874425722)
- 3D 插圖：[microsoft/fluentui-emoji](https://github.com/microsoft/fluentui-emoji)（[MIT 授權](https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/LICENSE)）
