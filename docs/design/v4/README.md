# 園區背景（0.10.0 起）

可以走進去的 10 個地方（動物園、海洋館、恐龍樂園、交通車館、植物園、昆蟲館、商店、太空、夜市、極地）的背景，是用開源 AI 畫圖模型在開發電腦上畫的（只用 CPU）。APP 裡只放畫好的圖，不用連網。

## 流程
1. `python3 draw_scenes.py <資料夾> --seeds 1 2`：把 `docs/design/v3/src/creatures.py` 的向量背景當草稿，讓模型重畫成繪本風格（img2img，強度 0.55）。地面、馬路、鐵軌留在原來的位置，角色才不會走到天上。
   - 提示詞不用「動物園」「海洋館」這類字，免得多畫出動物或魚。
2. 挑最好的一張，寫進 `export.py` 的 `SCENES`。
3. `python3 export.py <資料夾> [地方...]` 寫進 APP：`app/assets/scenes/<地方>.jpg`（不寫地方就全部）。
   - 交通車館招牌上的圖會被畫成亂碼，`KEEP` 會把原本向量圖的招牌貼回去。

## 用到的模型
| 模型 | 用途 | 授權 |
|---|---|---|
| [DreamShaper 8](https://huggingface.co/Lykon/dreamshaper-8)（Stable Diffusion 1.5） | 畫背景 | CreativeML OpenRAIL-M：畫出來的圖可以自由使用（包括商用），但不能拿模型做授權條款禁止的事 |
| [LCM-LoRA SD1.5](https://huggingface.co/latent-consistency/lcm-lora-sdv1-5) | 8 步就畫好（CPU 一張約 1～2 分鐘） | OpenRAIL++ |

只有畫好的圖會放進 APP，模型本身不會。

## 角色著色圖（歷史）
0.10.0 的角色著色圖也是在這裡做的：先用同一個模型畫寫實的插圖，再用 Segment Anything 剪下來、用 TEED 描成線。結果線條雜亂、看起來不像兒童著色本，0.11.0 起改成在 `docs/design/v5` 照兒童著色本的樣子畫。舊的程式（`to_page.py`、`segment.py`、`draw_subjects.py`）在 0.10.0 的提交裡。

## 安裝（開發電腦）
```
pip install torch diffusers transformers accelerate peft opencv-python-headless
```
第一次執行會從 Hugging Face 下載模型（約 2.5 GB）；之後可以加 `HF_HUB_OFFLINE=1` 離線執行。
