/// 卡牌图片资源映射服务
/// 根据卡牌ID映射到对应的图片资源路径
/// 每张卡牌有唯一图片，无重复
library;

import 'package:warring_states_card/core/asset_style.dart';

class CardImageService {
  static String get _base => 'assets/${AssetStyle.current.dirName}/';
  static String get _baseMinions => '${_base}minions/';
  static String get _baseSpells => '${_base}spells/';
  static String get _baseWeapons => '${_base}weapons/';
  static String get _baseHeroes => '${_base}heroes/';




  /// 根据卡牌ID获取图片资源路径
  static String getImageAsset(String cardId) {
    return _imageMap[cardId] ?? '';
  }

  /// 根据卡牌类型和ID获取完整路径
  static String getImageByType(String cardId, String type) {
    switch (type) {
      case 'minion':
        return '$_baseMinions${_minionImageMap[cardId] ?? ''}';
      case 'spell':
        return '$_baseSpells${_spellImageMap[cardId] ?? ''}';
      case 'weapon':
        return '$_baseWeapons${_weaponImageMap[cardId] ?? ''}';
      default:
        return '';
    }
  }

  /// 获取英雄头像路径（动态根据 AssetStyle.current）
  static String getHeroImageAsset(String heroId) {
    final fname = _heroImageMap[heroId];
    if (fname == null || fname.isEmpty) return '';
    return '$_baseHeroes$fname';
  }

  /// 随从卡牌图片映射 — 每张卡独立图片
  /// 兵卒 = X001-X007, 英雄 = X008-X012
  static const Map<String, String> _minionImageMap = {
    // ===== 兵家 (12卡) =====
    'B001': 'weiwuzu.webp',    // 魏武卒
    'B002': 'qinruishi.webp',    // 秦锐士
    'B003': 'zhaobianqi.webp',    // 赵边骑
    'B004': 'yansishi.webp',     // 燕死士
    'B005': 'churuizu.webp',      // 楚锐卒
    'B006': 'qijijishi.webp',   // 齐技击士
    'B007': 'hanjibing.webp',    // 韩戟兵
    'B008': 'sunwu.webp',      // 孙武
    'B009': 'wuqi.webp',  // 吴起
    'B010': 'sunbin.webp', // 孙膑
    'B011': 'lianpo.webp', // 廉颇
    'B012': 'limu.webp',      // 李牧

    // ===== 法家 (12卡) =====
    'F001': 'zhifali.webp',     // 执法吏
    'F002': 'xingtu.webp',      // 刑徒
    'F003': 'yuzu.webp',        // 狱卒
    'F004': 'lvlingguan.webp',  // 律令官
    'F005': 'sikou.webp',       // 司寇
    'F006': 'dali.webp',        // 大理
    'F007': 'fajiadizi.webp',   // 法家弟子
    'F008': 'shangyang.webp', // 商鞅
    'F009': 'hanfei.webp',   // 韩非
    'F010': 'likui.webp',     // 李悝
    'F011': 'shenbuhai.webp', // 申不害
    'F012': 'wuqibianfa.webp',  // 吴起变法

    // ===== 儒家 (12卡) =====
    'R001': 'rusheng.webp',     // 儒生
    'R002': 'liguan.webp',      // 礼官
    'R003': 'yueshi.webp',      // 乐师
    'R004': 'dianyuguan.webp',  // 典狱官
    'R005': 'junzi.webp',       // 君子
    'R006': 'xianren.webp', // 贤人
    'R007': 'fuzi.webp',        // 夫子
    'R008': 'kongzi.webp',  // 孔子
    'R009': 'mengzi.webp',  // 孟子
    'R010': 'xunzi.webp',   // 荀子
    'R011': 'zilu.webp',     // 子路（复用贤人）
    'R012': 'cengzi.webp',       // 曾子（复用荀子）

    // ===== 道家 (12卡) =====
    'D001': 'daotong.webp',    // 道童
    'D002': 'shoushanren.webp', // 守山人
    'D003': 'guanxingzhe.webp', // 观星者
    'D004': 'fushi.webp',       // 符师
    'D005': 'zhenren.webp',     // 真人
    'D006': 'yinshi.webp', // 隐士
    'D007': 'fangshi.webp',     // 方士
    'D008': 'laozi.webp', // 老子
    'D009': 'zhuangzi.webp', // 庄子
    'D010': 'liezi.webp',   // 列子
    'D011': 'guanyinzi.webp',     // 关尹子（复用方士）
    'D012': 'wenzi.webp', // 文子（复用隐士）

    // ===== 墨家 (12卡) =====
    'M001': 'jiguannushou.webp',   // 机关弩手
    'M002': 'jiguanshou.webp', // 机关兽
    'M003': 'mojiadizi.webp',    // 墨家弟子
    'M004': 'huchengnubing.webp',      // 护城弩兵
    'M005': 'shouchenggongbing.webp',    // 守城工兵
    'M006': 'gongchengjuxie.webp', // 攻城巨械
    'M007': 'gongjiangdashi.webp',    // 工匠大师
    'M008': 'mozi.webp',  // 墨子
    'M009': 'gongshuban.webp', // 公输班
    'M010': 'qinhuali.webp',      // 禽滑厘
    'M011': 'tianjiu.webp', // 田鸠
    'M012': 'futun.webp', // 腹䵍（复用公输班）

    // ===== 阴阳家 (12卡) =====
    'Y001': 'wuzhu.webp',       // 巫祝
    'Y002': 'zhanbushi.webp',      // 占卜师
    'Y003': 'wuxingdizi.webp',      // 五行弟子
    'Y004': 'jisi.webp',        // 祭司
    'Y005': 'xingxiangshi.webp',   // 星象师
    'Y006': 'fengshuishi.webp',    // 风水师
    'Y007': 'fangshushi.webp',  // 方术士
    'Y008': 'zouyan.webp',  // 邹衍
    'Y009': 'gande.webp',   // 甘德
    'Y010': 'shishen.webp', // 石申
    'Y011': 'nangong.webp', // 南公
    'Y012': 'anqisheng.webp', // 安期生

    // ===== 纵横家 (12卡) =====
    'Z001': 'bianshi.webp',    // 辩士
    'Z002': 'shuoke.webp',      // 说客
    'Z003': 'cike.webp',       // 刺客
    'Z004': 'shizhe.webp',     // 使者
    'Z005': 'moushi.webp',     // 谋士
    'Z006': 'waijiaoguan.webp',    // 外交官
    'Z007': 'ceshi.webp',      // 策士
    'Z008': 'suqin.webp',  // 苏秦
    'Z009': 'zhangyi.webp', // 张仪
    'Z010': 'fanju.webp', // 范雎
    'Z011': 'linxiangru.webp',     // 蔺相如（复用使者）
    'Z012': 'guiguzi.webp', // 鬼谷子

    // ===== 中立 (28卡, 8图循环+4顶级专图) =====
    'N001': 'minbing.webp',
    'N002': 'chihou.webp',
    'N003': 'liulangzhe.webp',
    'N004': 'shiwei.webp',
    'N005': 'jianke.webp',
    'N006': 'moushi.webp',
    'N007': 'yaoshi.webp',
    'N008': 'jiashi.webp',
    'N009': 'gongshou.webp',
    'N010': 'qibing.webp',
    'N011': 'fangshi.webp',
    'N012': 'yishi.webp',
    'N013': 'jiangling.webp',
    'N014': 'xiaowei.webp',
    'N015': 'wushi.webp',
    'N016': 'cike.webp',
    'N017': 'duwei.webp',
    'N018': 'mengjiang.webp',
    'N019': 'mouzhu.webp',
    'N020': 'mengma.webp',
    'N021': 'jiangjun.webp',
    'N022': 'yongshi.webp',
    'N023': 'zongshi.webp',
    'N024': 'shangjiangjun.webp',
    'N025': 'zhanshen.webp',
    'N026': 'bawang.webp',
    'N027': 'tiandi.webp',
    'N028': 'shenlong.webp',
  };

  /// 法术卡牌图片映射 — 每张卡唯一素材 (spells_spell_=新版, spells_=废弃)
  static const Map<String, String> _spellImageMap = {
    // 儒家法术 (8, unique)
    'R013': 'renzhenghuamin.webp',    // 仁政化民
    'R014': 'liyuetongchun.webp',     // 礼乐同春
    'R015': 'jiaohuazhongsheng.webp',    // 教化众生
    'R016': 'renyizhishi.webp',    // 仁义之师
    'R017': 'yidefuren.webp',     // 以德服人
    'R018': 'sanxingwushen.webp',   // 三省吾身
    'R019': 'youjiaowulei.webp',    // 有教无类
    'R020': 'kejifuli.webp',    // 克己复礼

    // 道家法术 (8)
    'D013': 'daofaziran.webp',    // 道法自然
    'D014': 'wuweierzhi.webp',    // 无为而治
    'D015': 'shangshanruoshui.webp',   // 上善若水
    'D016': 'xujingwuwei.webp',     // 虚静无为
    'D017': 'qiwulun.webp',        // 齐物论
    'D018': 'xiaoyaoyou.webp',     // 逍遥游
    'D019': 'yangshengzhu.webp',   // 养生主
    'D020': 'paodingjieniu.webp',  // 庖丁解牛

    // 兵家法术 (8, unique)
    'B013': 'weiweijiuzhao.webp',    // 围魏救赵
    'B014': 'pofuchenzhou.webp',     // 破釜沉舟
    'B015': 'beishuiyizhan.webp',     // 背水一战
    'B016': 'anduchencang.webp',     // 暗度陈仓
    'B017': 'shengdongjixi.webp',  // 声东击西
    'B018': 'shimianmaifu.webp',     // 十面埋伏
    'B019': 'yiyidailao.webp',     // 以逸待劳
    'B020': 'qinzeiqinwang.webp',    // 擒贼擒王

    // 法家法术 (8, unique)
    'F013': 'xingmingzhifa.webp',  // 刑名之法
    'F014': 'junfayanxing.webp',    // 峻法严刑
    'F015': 'yiduanyufa.webp',     // 一断于法
    'F016': 'yifazhiguo.webp',     // 以法治国
    'F017': 'lianzuozhifa.webp',   // 连坐之法
    'F018': 'jiangligengzhan.webp',  // 奖励耕战
    'F019': 'feichujingtian.webp',   // 废除井田
    'F020': 'tongyiduliang.webp',   // 统一度量

    // 墨家法术 (8, unique)
    'M013': 'jianaifeigong.webp',
    'M014': 'moshouchenggui.webp',
    'M015': 'jiguanzhishu.webp',
    'M016': 'dangshizhishu.webp',
    'M017': 'jieyongjiezang.webp',
    'M018': 'shangxianshangtong.webp',
    'M019': 'tianzhiminggui.webp',
    'M020': 'feilefeiming.webp',

    // 阴阳家法术 (8, unique)
    'Y013': 'wuxingxiangsheng.webp',
    'Y014': 'yinyangtiaohe.webp',
    'Y015': 'tianxiangyibian.webp',
    'Y016': 'zhanxingwenbu.webp',
    'Y017': 'dajiuzhoushuo.webp',
    'Y018': 'wudezhongshi.webp',
    'Y019': 'zaiyiqiangao.webp',
    'Y020': 'furuixiangzhao.webp',

    // 纵横家法术 (8, unique)
    'Z013': 'lianheng.webp',
    'Z014': 'hezong.webp',
    'Z015': 'yuanjiaojingong.webp',
    'Z016': 'zonghengbaihe.webp',
    'Z017': 'wanbiguizhao.webp',
    'Z018': 'lijianji.webp',
    'Z019': 'kongchengji.webp',
    'Z020': 'diaohulishan.webp',

    // 中立法术 (10, unique)
    'N029': 'diaobingqianjiang.webp',
    'N030': 'simianchuge.webp',
    'N031': 'zhijizhibi.webp',
    'N032': 'jianbiqingye.webp',
    'N033': 'yishaoshengduo.webp',
    'N034': 'qixi.webp',
    'N035': 'zengyuan.webp',
    'N036': 'jueshengju.webp',
    'N037': 'hengsaoqianjun.webp',
    'N038': 'fangeyiji.webp',
  };

  /// 武器卡牌图片映射 — 每张卡唯一素材
  /// 英雄头像映射（heroId → 文件名）
  static const Map<String, String> _heroImageMap = {
    'H_B001': 'sunbin.webp',
    'H_B002': 'wuqi.webp',
    'H_B003': 'lianpo.webp',
    'H_F001': 'shangyang.webp',
    'H_F002': 'hanfei.webp',
    'H_F003': 'shenbuhai.webp',
    'H_R001': 'kongzi.webp',
    'H_R002': 'mengzi.webp',
    'H_R003': 'xunzi.webp',
    'H_D001': 'laozi.webp',
    'H_D002': 'zhuangzi.webp',
    'H_D003': 'liezi.webp',
    'H_M001': 'mozi.webp',
    'H_M002': 'gongshuban.webp',
    'H_M003': 'qinhuali.webp',
    'H_Y001': 'zouyan.webp',
    'H_Y002': 'gande.webp',
    'H_Y003': 'shishen.webp',
    'H_Z001': 'suqin.webp',
    'H_Z002': 'zhangyi.webp',
    'H_Z003': 'guiguzi.webp',
  };

  static const Map<String, String> _weaponImageMap = {
    'RW001': 'rujiayugui.webp',
    'RW002': 'liqibianzhong.webp',
    'DW001': 'daojiafuchen.webp',
    'DW002': 'taijijian.webp',
    'BW001': 'wugou.webp',
    'BW002': 'yuewangjian.webp',
    'BW003': 'zhangbashemao.webp',
    'FW001': 'fajialvchi.webp',
    'FW002': 'xingding.webp',
    'MW001': 'mojiajiguannu.webp',
    'MW002': 'gongshuchi.webp',
    'YW001': 'yinyangwuxingzhang.webp',
    'YW002': 'zhanxingluopan.webp',
    'ZW001': 'zonghengjiaduanjian.webp',
    'ZW002': 'hezonglianhengshu.webp',
    'NW001': 'qingtongjian.webp',
    'NW002': 'zhangji.webp',
    'NW003': 'qinwangjian.webp',
  };

  /// 完整图片映射（动态，跟随 AssetStyle.current）
  static Map<String, String> get _imageMap => {
    ..._minionImageMap.map((k, v) => MapEntry(k, '$_baseMinions$v')),
    ..._spellImageMap.map((k, v) => MapEntry(k, '$_baseSpells$v')),
    ..._weaponImageMap.map((k, v) => MapEntry(k, '$_baseWeapons$v')),
  };

  /// 全部素材路径（英雄 + 卡牌），供启动全局预加载
  static List<String> getAllImagePaths() {
    final paths = <String>[
      for (final v in _heroImageMap.values)
        if (v.isNotEmpty) '$_baseHeroes$v',
      for (final v in _imageMap.values)
        if (v.isNotEmpty) v,
    ];
    return paths;
  }
}
