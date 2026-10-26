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
  Creature.stegosaurus: ['我背上有好多三角形！', '我的尾巴會搖來搖去～'],
  Creature.pterosaur: ['我會飛，飛得好高！', '咻～一起去天空玩！'],
  Creature.babyDino: ['我剛從蛋裡出來！', '哥哥姊姊好～'],
};

/// Everything [creature] may say.
List<String> linesOf(Creature creature) => [...?_own[creature], ..._anyone];

/// One thing [creature] says, its own lines a little more often.
String lineFor(Creature creature, math.Random random) {
  final own = _own[creature] ?? const <String>[];
  if (own.isNotEmpty && random.nextDouble() < 0.4) return own[random.nextInt(own.length)];
  return _anyone[random.nextInt(_anyone.length)];
}
