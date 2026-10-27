# 角色著色圖和園區背景（0.10.0 起）

小朋友說 0.9.0 的角色和背景「不像真的、太粗」。0.10.0 起，每一種角色都先畫成寫實的插圖，再描成著色圖；園區背景用原本的向量背景當草稿重畫。全部在開發電腦上做（只用 CPU），APP 裡只放畫好的圖，不用連網。

## 流程
1. **畫插圖**（`draw_subjects.py`，提示詞在 `subjects.py`）：每一種用 2～3 個種子各畫一張 512×512，淡藍色背景、沒有影子。
2. **挑一張**：看哪張最像、姿勢最好（要面向右邊，不是就在 `export.py` 設定翻轉），寫進 `export.py` 的 `PAGES`；`python3 export.py --subjects <資料夾>` 會把選好的存成 `subjects/<角色>.jpg`，剪下來的輪廓存成 `subjects/<角色>_mask.png`（之後重描不用再跑 SAM）。
3. **描成著色圖**（`to_page.py`，由 `export.py` 呼叫）：
   - 用 Segment Anything（`segment.py`）把主角剪下來，影子和地板不算（背景是漸層也可以）。
   - 用 TEED（APP 拍照描線用的同一個模型）找出線條強度。
   - 沿著清楚的線把主角分成區塊，光影這種模糊的交界會合併，太小、太細的區塊也會併到旁邊，小朋友比較好塗。
   - 再加上幾條沒有圍成區塊、但很清楚的線（眼睛、皺褶）。
   - 外框 5.5 像素、裡面的線 3.2 像素，放在 600×800 的頁面上。
4. **畫園區背景**（`draw_scenes.py`）：把 `docs/design/v3/src/creatures.py` 的向量背景當草稿，讓模型重畫（img2img，強度 0.55；提示詞不用「動物園」這類字，免得多畫出動物），地面、馬路、鐵軌留在原來的位置，角色才不會走到天上。挑一張寫進 `export.py` 的 `SCENES`，`--scenes <資料夾>` 會寫進 APP。
5. `python3 export.py` 寫進 APP：`app/assets/pages/<角色>.png`、`app/assets/scenes/<地方>.jpg`；`colors/<角色>.jpg` 是主角原本的顏色、放在跟著色圖一樣的位置（示範影片用它幫角色上色）。

畫不好的時候：換種子多畫幾張，或把提示詞寫得更具體（例如「不要水」「整台車在畫面中間、四周留白」）。Stable Diffusion 1.5 不太會畫三角龍的頸盾和捕蠅草，所以三角龍用最接近的一張，植物園的捕蠅草換成草莓。交通車館招牌上的字會被畫成亂碼，`export.py` 的 `KEEP` 會把原本向量圖的招牌貼回去。

每個角色的設定（`export.py` 的 `PAGES`）：
- `strength`：區塊交界要多清楚才保留（越大區塊越少）。
- `min_area`：區塊最小面積（頁面像素）。
- `detail`：0 只有區塊交界；越大，額外的線越多。毛和鱗片多的動物用 0，光滑的皮膚和車子可以多一點。
- `min_width`：區塊最細可以多細（斑馬的條紋要細一點才留得住）。

## 用到的模型
| 模型 | 用途 | 授權 |
|---|---|---|
| [DreamShaper 8](https://huggingface.co/Lykon/dreamshaper-8)（Stable Diffusion 1.5） | 畫插圖和背景 | CreativeML OpenRAIL-M：畫出來的圖可以自由使用（包括商用），但不能拿模型做授權條款禁止的事 |
| [LCM-LoRA SD1.5](https://huggingface.co/latent-consistency/lcm-lora-sdv1-5) | 6～8 步就畫好（CPU 一張約 1 分鐘） | OpenRAIL++ |
| [Segment Anything（ViT-B）](https://huggingface.co/facebook/sam-vit-base) | 剪下主角 | Apache 2.0 |
| [TEED](https://github.com/xavysp/TEED) | 找線條（APP 裡也有） | MIT |

只有畫好的圖會放進 APP，模型本身不會。

## 安裝（開發電腦）
```
pip install torch diffusers transformers accelerate peft opencv-python-headless scikit-image
```
第一次執行會從 Hugging Face 下載模型（約 2.5 GB）；之後可以加 `HF_HUB_OFFLINE=1` 離線執行。
