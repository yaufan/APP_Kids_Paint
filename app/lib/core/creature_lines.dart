import 'dart:math' as math;

import 'creatures.dart';
import 'festivals.dart';
import 'town_time.dart';
import 'weather.dart';

/// What is going on around a creature when it talks: the lines follow it.
class Moment {
  const Moment({
    required this.time,
    this.festival,
    this.justArrived = false,
    this.neighbors = const [],
    this.taps = 0,
    this.weather = Weather.sunny,
  });

  final DateTime time;

  /// Today's festival, if any.
  final Festival? festival;

  /// It was just colored and moved in.
  final bool justArrived;

  /// The others living in the same place (not counting itself).
  final List<Creature> neighbors;

  /// How many times in a row a child has just tapped it.
  final int taps;

  /// The weather where it is (sunny where the weather does not reach).
  final Weather weather;
}

// Every line is friendly and light: no scolding, no "I'm lonely", nothing
// that makes a child feel they must keep playing.

/// Little things any animal says.
const _anyone = [
  '你好呀！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '一起玩吧！',
  '我們是好朋友！',
  '耶～好好玩！',
  '我最喜歡你了！',
  '你今天開心嗎？',
  '我要去散步囉～',
  '你看我，帥不帥？',
  '我們來唱歌吧！啦啦啦～',
];

/// What any vehicle may say.
const _riders = [
  '叭叭！你好呀！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '出發囉！',
  '一起去兜風吧！',
  '坐好喔，要開車囉！',
  '我們是好朋友！',
  '耶～好好玩！',
  '你今天開心嗎？',
  '綠燈了，可以走囉！',
  '過馬路要牽好大人的手喔！',
];

/// What any plant may say.
const _growing = [
  '你好呀！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '太陽暖暖的，好舒服～',
  '幫我澆澆水好不好？',
  '風吹過來，我搖呀搖～',
  '我們是好朋友！',
  '我會慢慢長大喔！',
  '你今天開心嗎？',
  '蝴蝶來找我玩了！',
  '下雨的時候，我會喝好多水！',
];

/// What any of the candy house's sweets may say.
const _sweet = [
  '你好呀！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '我甜甜的喔！',
  '這裡聞起來好香喔～',
  '我們是甜甜的好朋友！',
  '吃完甜的要記得刷牙喔！',
  '耶～好好玩！',
  '你今天開心嗎？',
  '一起來跳舞吧！',
  '甜點一次吃一點點就好喔！',
];

/// What anyone on grandma and grandpa's farm may say (0.18).
const _onFarm = [
  '你好呀！歡迎來農場玩！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '阿公阿嬤對我們好好喔！',
  '農場的草好香喔～',
  '我們一起在草地上跑跑！',
  '你今天開心嗎？',
  '菜園裡的紅蘿蔔長大了！',
  '我們來玩捉迷藏，躲在稻草堆後面！',
  '你要不要摸摸我？輕輕的喔！',
];

/// What any of the shop's goods may say.
const _forSale = [
  '歡迎光臨！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '我在架子上等客人喔！',
  '要不要買我呀？',
  '今天特價喔！',
  '大家排好隊，一個一個來～',
  '我們是好朋友！',
  '你今天開心嗎？',
  '我是全店最好吃的！',
  '叮咚！有客人來了嗎？',
];

/// What anything floating in space may say.
const _inSpace = [
  '你好呀！我在太空跟你揮手！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '在太空裡，我輕飄飄的～',
  '你看，地球藍藍的、圓圓的！',
  '星星一閃一閃，好漂亮！',
  '我們是好朋友！',
  '咻～我轉了一圈！',
  '你今天開心嗎？',
  '太空好安靜喔～',
  '我們去月亮上散步吧！',
];

/// What the night market's snacks and goldfish may say.
const _atMarket = [
  '歡迎來夜市！',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '燈籠亮亮的，好漂亮！',
  '香香的味道飄過來了～',
  '要不要來套圈圈？',
  '我們是好朋友！',
  '夜市好熱鬧喔！',
  '你今天開心嗎？',
  '慢慢吃，小心燙喔！',
  '老闆說今天大放送！',
];

/// What anyone at the polar sea may say.
const _inSnow = [
  '你好呀！這裡好冷喔～',
  '我好喜歡我的新顏色！',
  '謝謝你把我畫得這麼漂亮！',
  '下雪了，白白的好漂亮！',
  '你看，天上有綠色的極光！',
  '我們來堆雪人吧！',
  '我們是好朋友！',
  '冰冰的，滑溜溜的！',
  '你今天開心嗎？',
  '要穿暖暖的衣服喔！',
  '我們來打雪仗！',
];

/// What each creature likes to say about itself.
const _own = <Creature, List<String>>{
  Creature.elephant: ['我的鼻子長長的～', '噗噗～我會噴水喔！', '我的耳朵像大扇子！', '我走路咚咚咚～'],
  Creature.giraffe: ['我的脖子好長，看得好遠！', '高高的樹葉最好吃了！', '我身上有好多咖啡色的格子！'],
  Creature.lion: ['吼～我是溫柔的獅子！', '你看我的鬃毛，蓬蓬的！', '我是動物園的國王喔！'],
  Creature.panda: ['我最愛吃竹子了！', '抱抱～', '我的黑眼圈很可愛吧！', '我會翻跟斗喔！'],
  Creature.zebra: ['我身上有黑白條紋喔！', '噠噠噠，我跑得好快！', '你數得出我有幾條條紋嗎？'],
  Creature.monkey: ['香蕉好好吃！', '看我跳得好高！', '我會用尾巴盪鞦韆！', '吱吱吱～'],
  Creature.clownfish: ['我住在珊瑚裡面！', '咕嚕咕嚕～', '我身上有白色的條紋！'],
  Creature.octopus: ['我有八隻腳喔！', '我可以一次抱好多人！', '我會噴墨水，咻～'],
  Creature.turtle: ['我慢慢游，不用急～', '我的殼是我的家！', '我累了就把頭縮進去！'],
  Creature.whale: ['噗～我在噴水！', '我是海裡最大的！', '我唱歌好遠好遠都聽得到！'],
  Creature.jellyfish: ['我飄呀飄～', '我軟軟的、亮亮的！', '我沒有骨頭喔！'],
  Creature.crab: ['我橫著走路喔！', '夾夾～我在跟你揮手！', '我會吐泡泡！'],
  Creature.trex: ['吼～我是暴龍，可是我不兇喔！', '我的手短短的，好可愛！', '我的腳步好大聲，咚！咚！'],
  Creature.triceratops: ['我頭上有三支角！', '我最喜歡吃草了！', '我的頭盔大大的！'],
  Creature.brachiosaurus: ['我的脖子可以碰到雲！', '你好小喔，我看到你了！', '我一口可以吃好多葉子！'],
  Creature.stegosaurus: ['我背上有一片一片的骨板！', '我的尾巴會搖來搖去～', '我走路慢慢的、穩穩的！'],
  Creature.pterosaur: ['我會飛，飛得好高！', '咻～一起去天空玩！', '我的翅膀張開好大！'],
  Creature.babyDino: ['我剛從蛋裡出來！', '哥哥姊姊好～', '我會長得跟腕龍一樣高嗎？'],
  Creature.fireTruck: ['嗚伊嗚伊～消防車出動！', '我的雲梯好長好長！', '我會噴水滅火喔！'],
  Creature.policeCar: ['我會保護大家喔！', '嗶嗶～大家要排隊喔！', '迷路了可以來找我！'],
  Creature.ambulance: ['我會載生病的人去看醫生！', '喔咿喔咿～請讓一讓！', '我車上有好多藥箱！'],
  Creature.bus: ['下一站，畫畫小鎮！', '上車要刷卡喔！', '我可以載好多好多人！'],
  Creature.scooter: ['噗噗噗～出門要戴安全帽喔！', '我小小的，可以鑽來鑽去！', '我載你去買早餐！'],
  Creature.train: ['嘟嘟～火車要開囉！', '轟隆轟隆，我在鐵軌上跑！', '我有好多節車廂！'],
  Creature.airplane: ['咻～我要飛到很遠的地方！', '從天上看，房子好小喔！', '我要穿過白白的雲！'],
  Creature.helicopter: ['我的螺旋槳轉呀轉！', '我可以停在空中喔！', '噠噠噠噠～我起飛了！'],
  Creature.sunflower: ['我最喜歡看太陽了！', '我的種子就是葵瓜子喔！', '我長得比你還高喔！'],
  Creature.tulip: ['我長得像一個小杯子！', '我有好多種顏色喔！', '我是春天的花！'],
  Creature.cactus: ['我不怕熱，也不太需要喝水！', '我身上有刺，要輕輕看喔！', '我頭上開了一朵小花！'],
  Creature.lotus: ['我住在池塘裡！', '我的葉子好大，青蛙會坐在上面！', '我早上開花喔！'],
  Creature.strawberry: ['我紅紅的、甜甜的！', '我身上有好多小小的種子喔！', '我戴著一頂綠色的帽子！'],
  Creature.rose: ['我好香喔，你聞聞看！', '我的莖上有刺，要小心喔！', '我可以送給你最愛的人！'],
  Creature.butterfly: ['我以前是毛毛蟲喔！', '我最喜歡在花上跳舞！', '我的翅膀兩邊一模一樣！'],
  Creature.ladybug: ['我身上有黑色的點點！', '我小小的、圓圓的！', '你數數看我有幾個點點？'],
  Creature.bee: ['嗡嗡嗡～我在採花蜜！', '我會做好吃的蜂蜜喔！', '我跳舞告訴朋友哪裡有花！'],
  Creature.beetle: ['我頭上有一支大大的角！', '我是很有力氣的獨角仙！', '我晚上才出來玩喔！'],
  Creature.dragonfly: ['我的翅膀亮晶晶的！', '我飛得好快，還可以停在空中！', '我的眼睛大大的！'],
  Creature.mantis: ['我的手像兩把小鐮刀！', '我會靜靜地站著，一動也不動！', '我會轉頭看你喔！'],
  Creature.milk: ['喝牛奶，長高高！', '我是新鮮的牛奶！', '冰冰涼涼的喔～', '早餐配我最棒了！'],
  Creature.carrot: ['我是脆脆的胡蘿蔔！', '兔子最喜歡我了！', '吃我眼睛會亮亮的！'],
  Creature.apple: ['我紅紅的、圓圓的！', '一天一顆蘋果！', '咬一口，喀滋喀滋！'],
  Creature.banana: ['我是彎彎的香蕉！', '剝開我的皮就可以吃囉！', '猴子最喜歡我了！'],
  Creature.bread: ['我是剛烤好的麵包！', '我香香的、軟軟的！', '塗上果醬更好吃喔！'],
  Creature.iceCream: ['我是冰淇淋，涼涼的！', '要快點吃，我會融化喔！', '上面還有一顆櫻桃！'],
  Creature.bubbleTea: ['我是珍珠奶茶！', '我的珍珠QQ的！', '吸管插進來，咻咻咻～'],
  Creature.pudding: ['我是軟綿綿的布丁！', '你看我會抖抖抖～', '我頭上有焦糖喔！'],
  Creature.rocket: ['3、2、1，發射！', '我要飛到月亮上！', '點我一下，我就起飛喔！'],
  Creature.astronaut: ['我是太空人，我會飄喔！', '我的頭盔圓圓的！', '從這裡看地球好漂亮！'],
  Creature.alien: ['嗶嗶嗶～地球的朋友你好！', '我有三隻眼睛喔！', '我從很遠很遠的星星來！'],
  Creature.ufo: ['我是飛碟，咻咻咻！', '我的燈會一閃一閃！', '要不要坐上來兜一圈？'],
  Creature.moon: ['我是月亮，晚上才出來！', '我有時候圓圓的，有時候彎彎的！', '我身上有好多坑洞！'],
  Creature.star: ['我是一閃一閃的小星星！', '晚上抬頭就看得到我！', '許個願吧！'],
  Creature.saturn: ['我有一個漂亮的大圈圈！', '我是土星，好大好大！', '我的圈圈是冰和石頭做的！'],
  Creature.spaceCat: ['喵～我是太空貓！', '我在太空抓星星！', '我的頭盔裡有我的鬍鬚！'],
  Creature.friedChicken: ['我是大大的雞排！', '我脆脆的、香香的！', '我比你的臉還大喔！'],
  Creature.sausage: ['我是烤香腸，油亮亮的！', '配一顆大蒜更好吃！', '烤得香香的喔！'],
  Creature.tanghulu: ['我是糖葫蘆，甜甜的！', '我身上有一層亮亮的糖！', '一顆、兩顆、三顆、四顆！'],
  Creature.cottonCandy: ['我是棉花糖，軟綿綿！', '我像一朵粉紅色的雲！', '舔一口就化掉了！'],
  Creature.sweetPotatoBalls: ['我是地瓜球，QQ的！', '我圓圓的、膨膨的！', '一口一個，剛剛好！'],
  Creature.shavedIce: ['我是刨冰，冰冰涼涼！', '上面有芒果和草莓醬！', '夏天吃我最舒服了！'],
  Creature.takoyaki: ['我是章魚燒，三顆好朋友！', '我裡面有章魚喔！', '小心燙，吹一吹再吃！'],
  Creature.goldfish: ['我是小金魚，游來游去！', '我的尾巴像一把扇子！', '吐泡泡給你看，啵啵啵！'],
  Creature.penguin: ['我會用肚子滑冰喔！', '我走路搖搖擺擺的！', '我是不會飛的鳥！'],
  Creature.polarBear: ['我是北極熊，毛白白的！', '我很會游泳喔！', '我的圍巾暖暖的！'],
  Creature.seal: ['我是海豹，喜歡躺在冰上！', '我的鬍鬚長長的！', '拍拍手，啪啪啪！'],
  Creature.snowman: ['我是雪人，鼻子是胡蘿蔔！', '天氣冷冷的我最開心！', '我的帽子好看嗎？'],
  Creature.arcticFox: ['我是雪狐，躲在雪裡看不到我！', '我的尾巴蓬蓬的，好暖和！', '我的耳朵會聽雪的聲音！'],
  Creature.orca: ['我是虎鯨，黑白黑白的！', '我游得好快！', '噗～我在噴水！'],
  Creature.sled: ['坐上來，我們滑下山！', '咻～好快好快！', '我載了一份禮物喔！'],
  Creature.igloo: ['我是用雪做的房子！', '裡面暖暖的喔！', '請進請進～'],
  Creature.tiger: ['我是老虎，吼～可是我很溫柔喔！', '我身上有黑色的條紋！', '我的尾巴長長的！'],
  Creature.hippo: ['我是河馬，嘴巴好大！', '我最喜歡泡在水裡了！', '我胖胖的，好可愛吧！'],
  Creature.koala: ['我是無尾熊，最愛抱抱！', '我最喜歡吃尤加利葉！', '我好想睡覺喔，呼～'],
  Creature.kangaroo: ['我是袋鼠，跳跳跳！', '我的口袋裡有寶寶喔！', '我跳得好高！'],
  Creature.blackBear: ['我是臺灣黑熊！', '我胸前有白色的Ｖ字！', '我住在高高的山上！'],
  Creature.flamingo: ['我是紅鶴，粉紅色的！', '我可以用一隻腳站好久！', '我的脖子彎彎的！'],
  Creature.dolphin: ['我是海豚，最愛跳出水面！', '我們一起玩水吧！', '我會吹泡泡喔！'],
  Creature.shark: ['我是鯊魚，不用怕，我很友善！', '我的牙齒白白的，每天都有刷！', '我游得好快！'],
  Creature.starfish: ['我是海星，五個角！', '我喜歡躺在沙子上！', '我像天上的星星嗎？'],
  Creature.seahorse: ['我是海馬，站著游泳！', '我的尾巴捲捲的！', '我的頭上有小皇冠！'],
  Creature.pufferfish: ['我是河豚，會變圓圓的！', '噗～我鼓起來了！', '我身上有小刺刺！'],
  Creature.seaOtter: ['我是海獺，手牽手睡覺！', '我有一個漂亮的貝殼！', '我喜歡浮在水上！'],
  Creature.ankylosaurus: ['我是甲龍，背上有盔甲！', '我的尾巴像一個小鎚子！', '我走路慢慢的～'],
  Creature.parasaurolophus: ['我是副櫛龍，頭上有一根管子！', '我會吹出好聽的聲音！', '嘟嘟～你聽到了嗎？'],
  Creature.spinosaurus: ['我是棘龍，背上有一片大帆！', '我喜歡在水邊抓魚！', '我的帆像扇子一樣！'],
  Creature.raptor: ['我是迅猛龍，跑得好快！', '我很聰明喔！', '我們來賽跑吧！'],
  Creature.pachycephalosaurus: ['我是腫頭龍，頭硬硬的！', '我的頭像戴了安全帽！', '咚咚咚，我的頭好厲害！'],
  Creature.dinoEgg: ['我是恐龍蛋，快要孵出來了！', '咦？裡面好像有東西在動！', '我搖呀搖～'],
  Creature.taxi: ['我是計程車，你要去哪裡？', '請繫好安全帶喔！', '黃色的我很好認吧！'],
  Creature.garbageTruck: ['我是垃圾車，聽到音樂就是我來了！', '倒垃圾囉！', '我讓城市變乾淨！'],
  Creature.excavator: ['我是挖土機，挖挖挖！', '我的手臂好長！', '我可以挖好大的洞！'],
  Creature.mrt: ['我是捷運，嗶嗶嗶，門要關了！', '我每天載好多人上學上班！', '排隊上車喔！'],
  Creature.mushroom: ['我是小蘑菇，戴紅帽子！', '下雨過後我就長出來了！', '我身上有白點點！'],
  Creature.sakura: ['我是櫻花樹，花瓣飄飄！', '春天的時候我最漂亮！', '我開了好多粉紅色的花！'],
  Creature.dandelion: ['我是蒲公英，吹一口氣！', '我的種子會飛去好遠！', '呼～飛呀飛！'],
  Creature.pineapple: ['我是鳳梨，酸酸甜甜！', '我頭上有綠色的葉子！', '我身上有格子花紋！'],
  Creature.watermelon: ['我是西瓜，夏天最好吃！', '我裡面紅紅的，有黑色的籽！', '冰冰涼涼的我最棒！'],
  Creature.pumpkin: ['我是南瓜，圓圓胖胖的！', '我是橘色的！', '我可以做成南瓜湯喔！'],
  Creature.ant: ['我是小螞蟻，力氣好大！', '我在搬好吃的東西！', '我們排隊走路，一二一二！'],
  Creature.snail: ['我是蝸牛，背著我的家！', '我走路慢慢的～', '下雨天我最開心了！'],
  Creature.caterpillar: ['我是毛毛蟲，長大會變蝴蝶！', '我一直吃葉子！', '我扭呀扭～'],
  Creature.firefly: ['我是螢火蟲，屁股會發光！', '晚上的時候我一閃一閃！', '跟著我的光走吧！'],
  Creature.cicada: ['我是蟬，知了知了！', '夏天到了，我在唱歌！', '我的翅膀透明的！'],
  Creature.spider: ['我是小蜘蛛，會織網！', '我有八隻腳喔！', '我掛在絲上盪鞦韆！'],
  Creature.egg: ['我是雞蛋，圓圓的！', '小心拿，我會破喔！', '我可以變成荷包蛋！'],
  Creature.riceBall: ['我是飯糰，三角形的！', '我穿著海苔衣服！', '帶我去野餐吧！'],
  Creature.grapes: ['我是葡萄，一串一串的！', '我是紫色的！', '一顆一顆，好好吃！'],
  Creature.cheese: ['我是起司，身上有洞洞！', '老鼠最喜歡我了！', '我黃黃的，香香的！'],
  Creature.earth: ['我是地球，我們的家！', '我身上有海洋和陸地！', '我每天都在轉圈圈！'],
  Creature.sun: ['我是太陽，暖暖的！', '我給大家光和熱！', '早安！我起床了！'],
  Creature.satellite: ['我是人造衛星，嗶嗶嗶！', '我在太空看著地球！', '我的翅膀是太陽能板！'],
  Creature.comet: ['我是彗星，拖著長長的尾巴！', '咻～我飛過去了！', '快許願吧！'],
  Creature.wheelCake: ['我是車輪餅，裡面有紅豆！', '我圓圓的像車輪！', '熱熱的最好吃！'],
  Creature.grilledCorn: ['我是烤玉米，香噴噴！', '我身上有一顆一顆的玉米粒！', '刷上醬汁好好吃！'],
  Creature.stinkyTofu: ['我是臭豆腐，聞起來臭臭，吃起來香香！', '旁邊的泡菜是我的好朋友！', '外面酥酥的喔！'],
  Creature.marbleSoda: ['我是彈珠汽水，裡面有一顆彈珠！', '打開的時候會「啵」一聲！', '冰冰涼涼，咕嚕咕嚕！'],
  Creature.walrus: ['我是海象，有兩根長牙！', '我的鬍鬚刺刺的！', '我喜歡躺在冰上曬太陽！'],
  Creature.reindeer: ['我是馴鹿，鼻子紅紅的！', '我幫聖誕老公公拉雪橇！', '我的角像樹枝！'],
  Creature.narwhal: ['我是獨角鯨，頭上有一根長角！', '我住在冷冷的海裡！', '我是海裡的獨角獸！'],
  Creature.snowyOwl: ['我是雪鴞，白白的貓頭鷹！', '我的眼睛大大的！', '我晚上也看得很清楚！'],
  Creature.lollipop: ['我是棒棒糖，一圈一圈轉轉轉！', '我有兩種顏色喔！', '我的蝴蝶結好看嗎？'],
  Creature.donut: ['我是甜甜圈，中間有一個洞！', '我身上有彩色的糖粒！', '我圓圓的，會滾來滾去！'],
  Creature.cupcake: ['我是杯子蛋糕！', '我頭上有一顆紅櫻桃！', '我的奶油軟綿綿的！'],
  Creature.macaron: ['我是馬卡龍，像一個小漢堡！', '我外面脆脆、裡面軟軟！', '我跳一跳，好開心！'],
  Creature.chocolate: ['我是巧克力，一格一格的！', '我會走路喔，噠噠噠！', '天氣太熱我會融化喔！'],
  Creature.candy: ['我是糖果，包著漂亮的糖果紙！', '我飄起來了～', '我像一個小氣球！'],
  Creature.gummyBear: ['我是軟糖熊，QQ的！', '我跳跳跳，彈彈彈！', '我有好多顏色的兄弟姐妹！'],
  Creature.candyCane: ['我是拐杖糖，紅白紅白的！', '聖誕節的時候我最忙了！', '我彎彎的，像一把小雨傘的柄！'],
  Creature.cookie: ['我是巧克力餅乾！', '咦？是誰偷咬了我一口？', '我會滾來滾去喔！'],
  Creature.gingerbread: ['我是薑餅人，你追不到我！', '我的扣子是糖果做的！', '跑跑跑，我跑得好快！'],
  Creature.cake: ['我是草莓蛋糕！', '今天是誰生日呀？', '我有三顆紅紅的草莓！'],
  Creature.jelly: ['我是果凍，抖抖抖！', '我軟軟的，好好玩！', '我頭上有一顆櫻桃！'],
  Creature.cow: ['哞～我是乳牛！', '我身上有黑黑的斑點！', '我脖子上的鈴鐺叮叮噹！'],
  Creature.waterBuffalo: ['哞～我是水牛，最喜歡泡水了！', '我的角彎彎的！', '我會幫阿公耕田喔！'],
  Creature.pig: ['噗噗～我是小豬！', '我的鼻子圓圓的！', '我的尾巴捲捲的！'],
  Creature.hen: ['咯咯咯～我是母雞！', '我今天生了一顆蛋喔！', '我頭上有紅紅的雞冠！'],
  Creature.chick: ['啾啾啾～我是小雞！', '我黃黃的、圓圓的！', '我跟著媽媽走路！'],
  Creature.sheep: ['咩～我是綿羊！', '我的毛捲捲的、軟軟的！', '我像一朵白白的雲！'],
  Creature.goat: ['咩咩～我是山羊！', '我有一點點鬍子喔！', '我最會爬高高了！'],
  Creature.duck: ['呱呱呱～我是鴨子！', '我最喜歡在池塘游泳！', '我走路搖搖擺擺的！'],
  Creature.goose: ['嘎嘎～我是鵝！', '我的脖子長長的！', '我幫阿嬤看門喔！'],
  Creature.bunny: ['我是兔子，跳跳跳！', '我最喜歡吃紅蘿蔔！', '我的耳朵長長的！'],
  Creature.puppy: ['汪汪～我是小狗！', '我們來玩丟球！', '我的尾巴搖呀搖！'],
  Creature.tractor: ['噗噗噗～我是拖拉機！', '我的輪子大大的！', '我幫阿公搬好多東西！'],
};

/// When it just moved in.
List<String> _arrival(Residents residents) => switch (residents) {
      Residents.sweets => ['我搬進糖果館了！大家好～', '這裡甜甜的，好香喔！', '謝謝你帶我來這裡！'],
      Residents.goods => ['我上架了！', '請多多指教～', '我站在架子上了，看得到我嗎？'],
      Residents.space => ['我飛到太空了！大家好～', '哇，這裡好多星星！', '我飄起來了！'],
      Residents.visitors => ['我來囉！大家好～', '這裡好好玩喔！', '謝謝你帶我來這裡！'],
      Residents.vehicles => ['我開進來了！大家好～', '這裡好漂亮喔！', '我可以停在這裡嗎？好開心！'],
      Residents.plants => ['我種好了！大家好～', '這裡的陽光好舒服！', '我會在這裡慢慢長大！'],
      Residents.animals => ['我搬來了！大家好～', '這裡好漂亮喔！', '謝謝你帶我來這裡！'],
    };

/// The time of day, as the town shows it (sunrise to sunset in Taipei).
List<String> _timeOf(DateTime time) {
  final phase = dayPhaseAt(time);
  if (phase == DayPhase.night) return ['晚安～', '月亮出來了！', '星星一閃一閃的！'];
  if (phase == DayPhase.dusk) return ['太陽要下山了～', '天空變成橘色的了！'];
  if (time.hour < 10) return ['早安！', '早上的空氣好新鮮！', '你吃早餐了嗎？'];
  if (time.hour < 14) return ['午安！', '中午了，肚子餓了嗎？'];
  return ['下午好～', '我們來玩捉迷藏！'];
}

List<String> _festivalOf(Festival festival) => [
      '${festival.label}快樂！',
      ...switch (festival) {
        Festival.lunarNewYear => ['恭喜恭喜！新年好！', '要拿紅包囉！'],
        Festival.lantern => ['我們去提燈籠！', '湯圓圓圓的，好好吃！'],
        Festival.childrensDay => ['今天是你的節日喔！', '小朋友最棒了！'],
        Festival.dragonBoat => ['要吃粽子囉！', '咚咚咚，划龍舟！'],
        Festival.midAutumn => ['月亮好圓喔！', '我們一起吃月餅！'],
        Festival.christmas => ['叮叮噹，叮叮噹～', '聖誕老公公要來了！'],
        Festival.newYearsEve => ['倒數囉！五、四、三、二、一！', '你看，煙火好漂亮！'],
      },
    ];

/// The weather, as [creature] feels it.
List<String> _weatherOf(Weather weather, Creature creature) {
  final habitat = creature.habitat;
  return switch (weather) {
    Weather.sunny => const [],
    Weather.cloudy => ['雲好多喔，像棉花糖！', '太陽躲起來了～', '雲飄來飄去！'],
    Weather.rain when habitat == Habitat.candy => ['下糖粒雨了！五顏六色的！', '哇，天上掉下好多糖粒！', '糖粒雨，甜甜的～'],
    Weather.rain when habitat == Habitat.botanical => ['下雨了！我喝得飽飽的！', '滴答滴答，好舒服的雨！', '下雨的時候，我會長高喔！'],
    Weather.rain => ['下雨了！滴答滴答～', '我們來躲雨吧！', '下雨天，聽雨的聲音好好聽！', '下雨了，要記得帶雨傘喔！'],
    Weather.rainbow => ['你看，天上有彩虹！', '彩虹有好多顏色！', '雨停了，出彩虹了！'],
    Weather.windy => [
        '風好大，呼呼呼～',
        if (habitat == Habitat.botanical) '風吹過來，我搖呀搖～' else '風把葉子吹起來了！',
        '我們來追風吧！',
      ],
  };
}

/// Talking to the others in the same place.
List<String> _with(Creature neighbor, Residents residents) => residents == Residents.goods
    ? ['${neighbor.label}就在我旁邊！', '我跟${neighbor.label}一起等客人！']
    : ['${neighbor.label}，我們一起玩！', '我跟${neighbor.label}是好朋友！'];

/// When a child taps it again and again.
const _tickled = ['呵呵呵，好癢喔！', '你在跟我玩嗎？', '咻～我跳起來了！', '再一次！再一次！'];

/// Many others around, or only it.
const _crowd = ['這裡好熱鬧喔！', '好多好朋友喔！'];
const _roomy = ['這裡好大，我可以跑來跑去！', '我在這裡好舒服！'];

/// Everything [creature] may say at [moment] (without one: its everyday lines).
List<String> linesOf(Creature creature, [Moment? moment]) {
  final residents = creature.habitat.residents;
  return {
    ...?_own[creature],
    ..._shared(creature),
    if (moment != null) ...[
      ..._timeOf(moment.time),
      if (moment.festival case final f?) ..._festivalOf(f),
      if (moment.justArrived) ..._arrival(residents),
      ..._weatherOf(moment.weather, creature),
      for (final n in moment.neighbors.toSet()) if (n != creature) ..._with(n, residents),
      if (moment.taps >= 2) ..._tickled,
      if (moment.neighbors.length >= 5) ..._crowd,
      if (moment.neighbors.isEmpty) ..._roomy,
    ],
  }.toList();
}

List<String> _shared(Creature creature) => switch (creature.habitat) {
      Habitat.zoo || Habitat.aquarium || Habitat.dinoPark || Habitat.insects => _anyone,
      Habitat.transport => _riders,
      Habitat.botanical => _growing,
      Habitat.shop => _forSale,
      Habitat.space => _inSpace,
      Habitat.nightMarket => _atMarket,
      Habitat.polar => _inSnow,
      Habitat.candy => _sweet,
      Habitat.farm => _onFarm,
    };

/// One thing [creature] says at [moment]: what is going on comes first
/// (being tapped again and again, having just moved in), then now and then
/// the festival, the time of day or a neighbor, else its own lines or
/// everyday ones.
String lineFor(Creature creature, math.Random random, [Moment? moment]) {
  T pick<T>(List<T> from) => from[random.nextInt(from.length)];
  final residents = creature.habitat.residents;
  if (moment != null) {
    if (moment.taps >= 2 && random.nextDouble() < 0.7) return pick(_tickled);
    if (moment.justArrived && random.nextDouble() < 0.8) return pick(_arrival(residents));
    final festival = moment.festival;
    if (festival != null && random.nextDouble() < 0.25) return pick(_festivalOf(festival));
    final weather = _weatherOf(moment.weather, creature);
    if (weather.isNotEmpty && random.nextDouble() < 0.22) return pick(weather);
    if (random.nextDouble() < 0.18) return pick(_timeOf(moment.time));
    final others = [for (final n in moment.neighbors) if (n != creature) n];
    if (others.isNotEmpty && random.nextDouble() < 0.18) return pick(_with(pick(others), residents));
    if (random.nextDouble() < 0.08) {
      if (moment.neighbors.length >= 5) return pick(_crowd);
      if (moment.neighbors.isEmpty) return pick(_roomy);
    }
  }
  final own = _own[creature] ?? const <String>[];
  if (own.isNotEmpty && random.nextDouble() < 0.45) return pick(own);
  return pick(_shared(creature));
}

/// The shop: a customer asks for [item].
String wantToBuy(Creature item, math.Random random) =>
    ['我要買${item.label}！', '請給我${item.label}！', '${item.label}看起來好好吃！'][random.nextInt(3)];

/// The shop: what the goods say when a customer takes them home, and when
/// a new one is back on the shelf.
const soldLines = ['謝謝光臨！', '要好好享用喔！', '下次再來喔！'];
const restockedLines = ['又補貨囉！', '我回來了！'];

/// Space: a rocket counts down when tapped, then takes off.
const countdown = '3、2、1，發射！';

/// The night market: what the snacks say when the child's ring lands on them.
const ringed = ['套中了！好厲害！', '耶！被你套到了！', '好準喔！'];

/// What an animal says when it has eaten the food the child put out (0.19).
const fedLines = ['好好吃！', '謝謝你餵我！', '吃飽飽了！', '好好吃，還想再吃！'];
