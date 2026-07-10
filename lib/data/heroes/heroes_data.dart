import '../../domain/models/models.dart';

/// 兵家英雄
const List<Hero> bingjiaHeroes = [
  Hero(id: 'H_B001', name: '孙膑', className: 'bingjia', kingdom: '齐',
       heroPowerName: '围魏救赵', heroPowerDescription: '获得2点护甲', skillType: SkillType.defensive,
       flavor: '围魏救赵，兵法典范。', artAsset: 'assets/heroes/bingjia_sunbin.png'),
  Hero(id: 'H_B002', name: '吴起', className: 'bingjia', kingdom: '卫',
       heroPowerName: '奖励耕战', heroPowerDescription: '使一个友方随从获得+1/+1', skillType: SkillType.buff,
       flavor: '奖励耕战，富国强兵。', artAsset: 'assets/heroes/bingjia_wuqi.png'),
  Hero(id: 'H_B003', name: '廉颇', className: 'bingjia', kingdom: '赵',
       heroPowerName: '负荆请罪', heroPowerDescription: '获得5点护甲', skillType: SkillType.defensive,
       flavor: '负荆请罪，将相和。', artAsset: 'assets/heroes/bingjia_lianpo.png'),
];

/// 法家英雄
const List<Hero> fajiaHeroes = [
  Hero(id: 'H_F001', name: '商鞅', className: 'fajia', kingdom: '秦',
       heroPowerName: '变法革新', heroPowerDescription: '使你手牌中费用最高的随从费用-2', skillType: SkillType.control,
       flavor: '商鞅变法，秦以富强。', artAsset: 'assets/heroes/fajia_shangyang.png'),
  Hero(id: 'H_F002', name: '韩非', className: 'fajia', kingdom: '韩',
       heroPowerName: '法家三术', heroPowerDescription: '沉默一个敌方随从', skillType: SkillType.control,
       flavor: '法家三术，势术法。', artAsset: 'assets/heroes/fajia_hanfei.png'),
  Hero(id: 'H_F003', name: '申不害', className: 'fajia', kingdom: '韩',
       heroPowerName: '循名责实', heroPowerDescription: '将一个敌方随从移回手牌', skillType: SkillType.control,
       flavor: '申不害言术，御下有方。', artAsset: 'assets/heroes/fajia_shenbuhai.png'),
];

/// 儒家英雄
const List<Hero> rujiaHeroes = [
  Hero(id: 'H_R001', name: '孔子', className: 'rujia', kingdom: '鲁',
       heroPowerName: '有教无类', heroPowerDescription: '抽一张牌', skillType: SkillType.draw,
       flavor: '孔子周游列国，弟子三千。', artAsset: 'assets/heroes/rujia_kongzi.png'),
  Hero(id: 'H_R002', name: '孟子', className: 'rujia', kingdom: '邹',
       heroPowerName: '民贵君轻', heroPowerDescription: '恢复3点生命值', skillType: SkillType.heal,
       flavor: '民为贵，社稷次之，君为轻。', artAsset: 'assets/heroes/rujia_mengzi.png'),
  Hero(id: 'H_R003', name: '荀子', className: 'rujia', kingdom: '赵',
       heroPowerName: '隆礼重法', heroPowerDescription: '使一个友方随从获得+2/+2', skillType: SkillType.buff,
       flavor: '荀子隆礼，礼法并重。', artAsset: 'assets/heroes/rujia_xunzi.png'),
];

/// 道家英雄
const List<Hero> daojiaHeroes = [
  Hero(id: 'H_D001', name: '老子', className: 'daojia', kingdom: '楚',
       heroPowerName: '道法自然', heroPowerDescription: '使所有友方随从获得+1/+1', skillType: SkillType.buff,
       flavor: '道可道，非常道。', artAsset: 'assets/heroes/daojia_laozi.png'),
  Hero(id: 'H_D002', name: '庄子', className: 'daojia', kingdom: '宋',
       heroPowerName: '逍遥游', heroPowerDescription: '使一个友方随从获得免疫', skillType: SkillType.defensive,
       flavor: '逍遥游，物我两忘。', artAsset: 'assets/heroes/daojia_zhuangzi.png'),
  Hero(id: 'H_D003', name: '列子', className: 'daojia', kingdom: '郑',
       heroPowerName: '御风而行', heroPowerDescription: '使一个友方随从获得冲锋', skillType: SkillType.buff,
       flavor: '列子御风，乘风而行。', artAsset: 'assets/heroes/daojia_liezi.png'),
];

/// 墨家英雄
const List<Hero> mojiaHeroes = [
  Hero(id: 'H_M001', name: '墨子', className: 'mojia', kingdom: '宋',
       heroPowerName: '兼爱非攻', heroPowerDescription: '召唤一个1/1的机关兽', skillType: SkillType.summon,
       flavor: '墨子兼爱，非攻止战。', artAsset: 'assets/heroes/mojia_mozi.png'),
  Hero(id: 'H_M002', name: '公输班', className: 'mojia', kingdom: '鲁',
       heroPowerName: '机关术', heroPowerDescription: '使你的武器获得+1攻击力', skillType: SkillType.buff,
       flavor: '公输班(鲁班)，木匠祖师。', artAsset: 'assets/heroes/mojia_gongshuban.png'),
  Hero(id: 'H_M003', name: '禽滑厘', className: 'mojia', kingdom: '卫',
       heroPowerName: '守城之术', heroPowerDescription: '获得3点护甲', skillType: SkillType.defensive,
       flavor: '墨家守城专家，禽滑厘。', artAsset: 'assets/heroes/mojia_qinhuali.png'),
];

/// 阴阳家英雄
const List<Hero> yinyangjiaHeroes = [
  Hero(id: 'H_Y001', name: '邹衍', className: 'yinyangjia', kingdom: '齐',
       heroPowerName: '五行相生', heroPowerDescription: '随机造成3点伤害', skillType: SkillType.random,
       flavor: '邹衍谈天，五行相生。', artAsset: 'assets/heroes/yinyangjia_zouyan.png'),
  Hero(id: 'H_Y002', name: '甘德', className: 'yinyangjia', kingdom: '齐',
       heroPowerName: '星象观测', heroPowerDescription: '发现一张法术牌', skillType: SkillType.random,
       flavor: '天文学家甘德，星图绘制。', artAsset: 'assets/heroes/yinyangjia_gande.png'),
  Hero(id: 'H_Y003', name: '石申', className: 'yinyangjia', kingdom: '魏',
       heroPowerName: '天象占卜', heroPowerDescription: '抽一张牌，如果为法术牌则复制', skillType: SkillType.random,
       flavor: '石申天文，与甘德齐名。', artAsset: 'assets/heroes/yinyangjia_shishen.png'),
];

/// 纵横家英雄
const List<Hero> zonghengjiaHeroes = [
  Hero(id: 'H_Z001', name: '苏秦', className: 'zonghengjia', kingdom: '周',
       heroPowerName: '合纵抗秦', heroPowerDescription: '使所有敌方随从获得-1/-1', skillType: SkillType.debuff,
       flavor: '苏秦合纵，六国拜相。', artAsset: 'assets/heroes/zonghengjia_suqin.png'),
  Hero(id: 'H_Z002', name: '张仪', className: 'zonghengjia', kingdom: '魏',
       heroPowerName: '连横破纵', heroPowerDescription: '抽两张牌', skillType: SkillType.draw,
       flavor: '张仪连横，瓦解合纵。', artAsset: 'assets/heroes/zonghengjia_zhangyi.png'),
  Hero(id: 'H_Z003', name: '鬼谷子', className: 'zonghengjia', kingdom: '卫',
       heroPowerName: '纵横捭阖', heroPowerDescription: '随机施放两个效果', skillType: SkillType.random,
       flavor: '鬼谷子，纵横家之祖。', artAsset: 'assets/heroes/zonghengjia_guiguzi.png'),
];

/// 获取所有英雄
List<Hero> getAllHeroes() {
  return [
    ...bingjiaHeroes,
    ...fajiaHeroes,
    ...rujiaHeroes,
    ...daojiaHeroes,
    ...mojiaHeroes,
    ...yinyangjiaHeroes,
    ...zonghengjiaHeroes,
  ];
}

/// 获取职业英雄
List<Hero> getHeroesByClass(String className) {
  return getAllHeroes().where((h) => h.className == className).toList();
}

/// 根据ID获取英雄
Hero? getHeroById(String id) {
  try {
    return getAllHeroes().firstWhere((h) => h.id == id);
  } catch (_) {
    return null;
  }
}