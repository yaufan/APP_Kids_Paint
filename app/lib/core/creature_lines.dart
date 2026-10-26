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

/// Everything [creature] may say.
List<String> linesOf(Creature creature) => [...?_own[creature], ..._shared(creature)];

List<String> _shared(Creature creature) => creature.habitat.vehicles ? _riders : _anyone;

/// One thing [creature] says, its own lines a little more often.
String lineFor(Creature creature, math.Random random) {
  final own = _own[creature] ?? const <String>[];
  if (own.isNotEmpty && random.nextDouble() < 0.4) return own[random.nextInt(own.length)];
  final shared = _shared(creature);
  return shared[random.nextInt(shared.length)];
}
