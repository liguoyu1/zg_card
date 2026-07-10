import 'package:equatable/equatable.dart';
import 'card.dart';

/// 英雄技能类型
enum SkillType { defensive, buff, control, summon, random, draw, heal, debuff }

/// 英雄数据模型
class Hero extends Equatable {
  
  const Hero({
    required this.id,
    required this.name,
    required this.className,
    required this.kingdom,
    this.health = 30,
    required this.heroPowerName,
    required this.heroPowerDescription,
    required this.skillType,
    this.artAsset = '',
    this.flavor = '',
  });
  final String id;
  final String name;
  final String className; // 职业
  final String kingdom;    // 国家
  final int health;
  final String heroPowerName;
  final String heroPowerDescription;
  final SkillType skillType;
  final String artAsset;
  final String flavor;

  /// 获取职业对应的CardOwner
  CardOwner get owner {
    switch (className) {
      case 'bingjia':
        return CardOwner.bingjia;
      case 'fajia':
        return CardOwner.fajia;
      case 'rujia':
        return CardOwner.rujia;
      case 'daojia':
        return CardOwner.daojia;
      case 'mojia':
        return CardOwner.mojia;
      case 'yinyangjia':
        return CardOwner.yinyangjia;
      case 'zonghengjia':
        return CardOwner.zonghengjia;
      default:
        return CardOwner.neutral;
    }
  }
  
  @override
  List<Object?> get props => [id, name, className, kingdom, health, heroPowerName, skillType, flavor];
}

/// 职业定义
class GameClass extends Equatable {
  
  const GameClass({
    required this.id,
    required this.name,
    required this.nameZh,
    required this.description,
    required this.owner,
  });
  final String id;
  final String name;
  final String nameZh;
  final String description;
  final CardOwner owner;
  
  @override
  List<Object?> get props => [id, name, nameZh];
}

/// 职业列表
const List<GameClass> gameClasses = [
  GameClass(id: 'bingjia', name: 'Military', nameZh: '兵家', description: 'Military tactics and warfare', owner: CardOwner.bingjia),
  GameClass(id: 'fajia', name: 'Legalist', nameZh: '法家', description: 'Law and governance', owner: CardOwner.fajia),
  GameClass(id: 'rujia', name: 'Confucian', nameZh: '儒家', description: 'Ethics and governance', owner: CardOwner.rujia),
  GameClass(id: 'daojia', name: 'Taoist', nameZh: '道家', description: 'Natural harmony', owner: CardOwner.daojia),
  GameClass(id: 'mojia', name: 'Mohist', nameZh: '墨家', description: 'Engineering and equality', owner: CardOwner.mojia),
  GameClass(id: 'yinyangjia', name: 'Yinyang', nameZh: '阴阳家', description: 'Five elements and cosmology', owner: CardOwner.yinyangjia),
  GameClass(id: 'zonghengjia', name: 'Diplomat', nameZh: '纵横家', description: 'Alliances and negotiations', owner: CardOwner.zonghengjia),
];