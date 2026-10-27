import 'dart:math' as math;

import 'creatures.dart';

/// Little things any creature says: friendly, happy, never scary.
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
  '再畫一個朋友陪我好不好？',
];

/// What each creature likes to say about itself.
const _own = <Creature, List<String>>{
  Creature.elephant: ['我的鼻子長長的～', '噗噗～我會噴水喔！'],
  Creature.giraffe: ['我的脖子好長，看得好遠！', '高高的樹葉最好吃了！'],
  Creature.lion: ['吼～我是溫柔的獅子！', '你看我的鬃毛，蓬蓬的！'],
  Creature.panda: ['我最愛吃竹子了！', '抱抱～'],
  Creature.zebra: ['我身上有黑白條紋喔！', '噠噠噠，我跑得好快！'],
  Creature.monkey: ['香蕉好好吃！', '看我跳得好高！'],
  Creature.clownfish: ['我住在珊瑚裡面！', '咕嚕咕嚕～'],
  Creature.octopus: ['我有八隻腳喔！', '我可以一次抱好多人！'],
  Creature.turtle: ['我慢慢游，不用急～', '我的殼是我的家！'],
  Creature.whale: ['噗～我在噴水！', '我是海裡最大的！'],
  Creature.jellyfish: ['我飄呀飄～', '我軟軟的、亮亮的！'],
  Creature.crab: ['我橫著走路喔！', '夾夾～我在跟你揮手！'],
  Creature.trex: ['吼～我是暴龍，可是我不兇喔！', '我的手短短的，好可愛！'],
  Creature.triceratops: ['我頭上有三支角！', '我最喜歡吃草了！'],
  Creature.brachiosaurus: ['我的脖子可以碰到雲！', '你好小喔，我看到你了！'],
  Creature.stegosaurus: ['我背上有一片一片的骨板！', '我的尾巴會搖來搖去～'],
  Creature.pterosaur: ['我會飛，飛得好高！', '咻～一起去天空玩！'],
  Creature.babyDino: ['我剛從蛋裡出來！', '哥哥姊姊好～'],
  Creature.fireTruck: ['嗚伊嗚伊～消防車出動！', '我的雲梯好長好長！'],
  Creature.policeCar: ['我會保護大家喔！', '嗶嗶～大家要排隊喔！'],
  Creature.ambulance: ['我會載生病的人去看醫生！', '喔咿喔咿～請讓一讓！'],
  Creature.bus: ['下一站，畫畫小鎮！', '上車要刷卡喔！'],
  Creature.scooter: ['噗噗噗～出門要戴安全帽喔！', '我小小的，可以鑽來鑽去！'],
  Creature.train: ['嘟嘟～火車要開囉！', '轟隆轟隆，我在鐵軌上跑！'],
  Creature.airplane: ['咻～我要飛到很遠的地方！', '從天上看，房子好小喔！'],
  Creature.helicopter: ['我的螺旋槳轉呀轉！', '我可以停在空中喔！'],
  Creature.sunflower: ['我最喜歡看太陽了！', '我的種子就是葵瓜子喔！'],
  Creature.tulip: ['我長得像一個小杯子！', '我有好多種顏色喔！'],
  Creature.cactus: ['我不怕熱，也不太需要喝水！', '我身上有刺，要輕輕看喔！'],
  Creature.lotus: ['我住在池塘裡！', '我的葉子好大，青蛙會坐在上面！'],
  Creature.strawberry: ['我紅紅的、甜甜的！', '我身上有好多小小的種子喔！'],
  Creature.rose: ['我好香喔，你聞聞看！', '我的莖上有刺，要小心喔！'],
  Creature.butterfly: ['我以前是毛毛蟲喔！', '我最喜歡在花上跳舞！'],
  Creature.ladybug: ['我身上有黑色的點點！', '我小小的、圓圓的！'],
  Creature.bee: ['嗡嗡嗡～我在採花蜜！', '我會做好吃的蜂蜜喔！'],
  Creature.beetle: ['我頭上有一支大大的角！', '我是很有力氣的獨角仙！'],
  Creature.dragonfly: ['我的翅膀亮晶晶的！', '我飛得好快，還可以停在空中！'],
  Creature.mantis: ['我的手像兩把小鐮刀！', '我會靜靜地站著，一動也不動！'],
};

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
  '再畫一台車陪我好不好？',
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
  '再畫一棵陪我好不好？',
];

/// Everything [creature] may say.
List<String> linesOf(Creature creature) => [...?_own[creature], ..._shared(creature)];

List<String> _shared(Creature creature) => switch (creature.habitat.residents) {
      Residents.animals => _anyone,
      Residents.vehicles => _riders,
      Residents.plants => _growing,
    };

/// One thing [creature] says, its own lines a little more often.
String lineFor(Creature creature, math.Random random) {
  final own = _own[creature] ?? const <String>[];
  if (own.isNotEmpty && random.nextDouble() < 0.4) return own[random.nextInt(own.length)];
  final shared = _shared(creature);
  return shared[random.nextInt(shared.length)];
}
