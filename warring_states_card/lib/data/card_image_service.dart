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
    'B001': 'weiwuzu.png',    // 魏武卒
    'B002': 'qinruishi.png',    // 秦锐士
    'B003': 'zhaobianqi.png',    // 赵边骑
    'B004': 'yansishi.png',     // 燕死士
    'B005': 'churuizu.png',      // 楚锐卒
    'B006': 'qijijishi.png',   // 齐技击士
    'B007': 'hanjibing.png',    // 韩戟兵
    'B008': 'sunwu.png',      // 孙武
    'B009': 'wuqi.png',  // 吴起
    'B010': 'sunbin.png', // 孙膑
    'B011': 'lianpo.png', // 廉颇
    'B012': 'limu.png',      // 李牧

    // ===== 法家 (12卡) =====
    'F001': 'zhifali.png',     // 执法吏
    'F002': 'xingtu.png',      // 刑徒
    'F003': 'yuzu.png',        // 狱卒
    'F004': 'lvlingguan.png',  // 律令官
    'F005': 'sikou.png',       // 司寇
    'F006': 'dali.png',        // 大理
    'F007': 'fajiadizi.png',   // 法家弟子
    'F008': 'shangyang.png', // 商鞅
    'F009': 'hanfei.png',   // 韩非
    'F010': 'likui.png',     // 李悝
    'F011': 'shenbuhai.png', // 申不害
    'F012': 'wuqibianfa.png',  // 吴起变法

    // ===== 儒家 (12卡) =====
    'R001': 'rusheng.png',     // 儒生
    'R002': 'liguan.png',      // 礼官
    'R003': 'yueshi.png',      // 乐师
    'R004': 'dianyuguan.png',  // 典狱官
    'R005': 'junzi.png',       // 君子
    'R006': 'xianren.png', // 贤人
    'R007': 'fuzi.png',        // 夫子
    'R008': 'kongzi.png',  // 孔子
    'R009': 'mengzi.png',  // 孟子
    'R010': 'xunzi.png',   // 荀子
    'R011': 'zilu.png',     // 子路（复用贤人）
    'R012': 'cengzi.png',       // 曾子（复用荀子）

    // ===== 道家 (12卡) =====
    'D001': 'daotong.png',    // 道童
    'D002': 'shoushanren.png', // 守山人
    'D003': 'guanxingzhe.png', // 观星者
    'D004': 'fushi.png',       // 符师
    'D005': 'zhenren.png',     // 真人
    'D006': 'yinshi.png', // 隐士
    'D007': 'fangshi.png',     // 方士
    'D008': 'laozi.png', // 老子
    'D009': 'zhuangzi.png', // 庄子
    'D010': 'liezi.png',   // 列子
    'D011': 'guanyinzi.png',     // 关尹子（复用方士）
    'D012': 'wenzi.png', // 文子（复用隐士）

    // ===== 墨家 (12卡) =====
    'M001': 'jiguannushou.png',   // 机关弩手
    'M002': 'jiguanshou.png', // 机关兽
    'M003': 'mojiadizi.png',    // 墨家弟子
    'M004': 'huchengnubing.png',      // 护城弩兵
    'M005': 'shouchenggongbing.png',    // 守城工兵
    'M006': 'gongchengjuxie.png', // 攻城巨械
    'M007': 'gongjiangdashi.png',    // 工匠大师
    'M008': 'mozi.png',  // 墨子
    'M009': 'gongshuban.png', // 公输班
    'M010': 'qinhuali.png',      // 禽滑厘
    'M011': 'tianjiu.png', // 田鸠
    'M012': 'futun.png', // 腹䵍（复用公输班）

    // ===== 阴阳家 (12卡) =====
    'Y001': 'wuzhu.png',       // 巫祝
    'Y002': 'zhanbushi.png',      // 占卜师
    'Y003': 'wuxingdizi.png',      // 五行弟子
    'Y004': 'jisi.png',        // 祭司
    'Y005': 'xingxiangshi.png',   // 星象师
    'Y006': 'fengshuishi.png',    // 风水师
    'Y007': 'fangshushi.png',  // 方术士
    'Y008': 'zouyan.png',  // 邹衍
    'Y009': 'gande.png',   // 甘德
    'Y010': 'shishen.png', // 石申
    'Y011': 'nangong.png', // 南公
    'Y012': 'anqisheng.png', // 安期生

    // ===== 纵横家 (12卡) =====
    'Z001': 'bianshi.png',    // 辩士
    'Z002': 'shuoke.png',      // 说客
    'Z003': 'cike.png',       // 刺客
    'Z004': 'shizhe.png',     // 使者
    'Z005': 'moushi.png',     // 谋士
    'Z006': 'waijiaoguan.png',    // 外交官
    'Z007': 'ceshi.png',      // 策士
    'Z008': 'suqin.png',  // 苏秦
    'Z009': 'zhangyi.png', // 张仪
    'Z010': 'fanju.png', // 范雎
    'Z011': 'linxiangru.png',     // 蔺相如（复用使者）
    'Z012': 'guiguzi.png', // 鬼谷子

    // ===== 中立 (28卡, 8图循环+4顶级专图) =====
    'N001': 'minbing.png',
    'N002': 'chihou.png',
    'N003': 'liulangzhe.png',
    'N004': 'shiwei.png',
    'N005': 'jianke.png',
    'N006': 'moushi.png',
    'N007': 'yaoshi.png',
    'N008': 'jiashi.png',
    'N009': 'gongshou.png',
    'N010': 'qibing.png',
    'N011': 'fangshi.png',
    'N012': 'yishi.png',
    'N013': 'jiangling.png',
    'N014': 'xiaowei.png',
    'N015': 'wushi.png',
    'N016': 'cike.png',
    'N017': 'duwei.png',
    'N018': 'mengjiang.png',
    'N019': 'mouzhu.png',
    'N020': 'mengma.png',
    'N021': 'jiangjun.png',
    'N022': 'yongshi.png',
    'N023': 'zongshi.png',
    'N024': 'shangjiangjun.png',
    'N025': 'zhanshen.png',
    'N026': 'bawang.png',
    'N027': 'tiandi.png',
    'N028': 'shenlong.png',
  };

  /// 法术卡牌图片映射 — 每张卡唯一素材 (spells_spell_=新版, spells_=废弃)
  static const Map<String, String> _spellImageMap = {
    // 儒家法术 (8, unique)
    'R013': 'renzhenghuamin.png',    // 仁政化民
    'R014': 'liyuetongchun.png',     // 礼乐同春
    'R015': 'jiaohuazhongsheng.png',    // 教化众生
    'R016': 'renyizhishi.png',    // 仁义之师
    'R017': 'yidefuren.png',     // 以德服人
    'R018': 'sanxingwushen.png',   // 三省吾身
    'R019': 'youjiaowulei.png',    // 有教无类
    'R020': 'kejifuli.png',    // 克己复礼

    // 道家法术 (8)
    'D013': 'daofaziran.png',    // 道法自然
    'D014': 'wuweierzhi.png',    // 无为而治
    'D015': 'shangshanruoshui.png',   // 上善若水
    'D016': 'xujingwuwei.png',     // 虚静无为
    'D017': 'qiwulun.png',        // 齐物论
    'D018': 'xiaoyaoyou.png',     // 逍遥游
    'D019': 'yangshengzhu.png',   // 养生主
    'D020': 'paodingjieniu.png',  // 庖丁解牛

    // 兵家法术 (8, unique)
    'B013': 'weiweijiuzhao.png',    // 围魏救赵
    'B014': 'pofuchenzhou.png',     // 破釜沉舟
    'B015': 'beishuiyizhan.png',     // 背水一战
    'B016': 'anduchencang.png',     // 暗度陈仓
    'B017': 'shengdongjixi.png',  // 声东击西
    'B018': 'shimianmaifu.png',     // 十面埋伏
    'B019': 'yiyidailao.png',     // 以逸待劳
    'B020': 'qinzeiqinwang.png',    // 擒贼擒王

    // 法家法术 (8, unique)
    'F013': 'xingmingzhifa.png',  // 刑名之法
    'F014': 'junfayanxing.png',    // 峻法严刑
    'F015': 'yiduanyufa.png',     // 一断于法
    'F016': 'yifazhiguo.png',     // 以法治国
    'F017': 'lianzuozhifa.png',   // 连坐之法
    'F018': 'jiangligengzhan.png',  // 奖励耕战
    'F019': 'feichujingtian.png',   // 废除井田
    'F020': 'tongyiduliang.png',   // 统一度量

    // 墨家法术 (8, unique)
    'M013': 'jianaifeigong.png',
    'M014': 'moshouchenggui.png',
    'M015': 'jiguanzhishu.png',
    'M016': 'dangshizhishu.png',
    'M017': 'jieyongjiezang.png',
    'M018': 'shangxianshangtong.png',
    'M019': 'tianzhiminggui.png',
    'M020': 'feilefeiming.png',

    // 阴阳家法术 (8, unique)
    'Y013': 'wuxingxiangsheng.png',
    'Y014': 'yinyangtiaohe.png',
    'Y015': 'tianxiangyibian.png',
    'Y016': 'zhanxingwenbu.png',
    'Y017': 'dajiuzhoushuo.png',
    'Y018': 'wudezhongshi.png',
    'Y019': 'zaiyiqiangao.png',
    'Y020': 'furuixiangzhao.png',

    // 纵横家法术 (8, unique)
    'Z013': 'lianheng.png',
    'Z014': 'hezong.png',
    'Z015': 'yuanjiaojingong.png',
    'Z016': 'zonghengbaihe.png',
    'Z017': 'wanbiguizhao.png',
    'Z018': 'lijianji.png',
    'Z019': 'kongchengji.png',
    'Z020': 'diaohulishan.png',

    // 中立法术 (10, unique)
    'N029': 'diaobingqianjiang.png',
    'N030': 'simianchuge.png',
    'N031': 'zhijizhibi.png',
    'N032': 'jianbiqingye.png',
    'N033': 'yishaoshengduo.png',
    'N034': 'qixi.png',
    'N035': 'zengyuan.png',
    'N036': 'jueshengju.png',
    'N037': 'hengsaoqianjun.png',
    'N038': 'fangeyiji.png',
  };

  /// 武器卡牌图片映射 — 每张卡唯一素材
  /// 英雄头像映射（heroId → 文件名）
  static const Map<String, String> _heroImageMap = {
    'H_B001': 'sunbin.png',
    'H_B002': 'wuqi.png',
    'H_B003': 'lianpo.png',
    'H_F001': 'shangyang.png',
    'H_F002': 'hanfei.png',
    'H_F003': 'shenbuhai.png',
    'H_R001': 'kongzi.png',
    'H_R002': 'mengzi.png',
    'H_R003': 'xunzi.png',
    'H_D001': 'laozi.png',
    'H_D002': 'zhuangzi.png',
    'H_D003': 'liezi.png',
    'H_M001': 'mozi.png',
    'H_M002': 'gongshuban.png',
    'H_M003': 'qinhuali.png',
    'H_Y001': 'zouyan.png',
    'H_Y002': 'gande.png',
    'H_Y003': 'shishen.png',
    'H_Z001': 'suqin.png',
    'H_Z002': 'zhangyi.png',
    'H_Z003': 'guiguzi.png',
  };

  static const Map<String, String> _weaponImageMap = {
    'RW001': 'rujiayugui.png',
    'RW002': 'liqibianzhong.png',
    'DW001': 'daojiafuchen.png',
    'DW002': 'taijijian.png',
    'BW001': 'wugou.png',
    'BW002': 'yuewangjian.png',
    'BW003': 'zhangbashemao.png',
    'FW001': 'fajialvchi.png',
    'FW002': 'xingding.png',
    'MW001': 'mojiajiguannu.png',
    'MW002': 'gongshuchi.png',
    'YW001': 'yinyangwuxingzhang.png',
    'YW002': 'zhanxingluopan.png',
    'ZW001': 'zonghengjiaduanjian.png',
    'ZW002': 'hezonglianhengshu.png',
    'NW001': 'qingtongjian.png',
    'NW002': 'zhangji.png',
    'NW003': 'qinwangjian.png',
  };

  /// 完整图片映射（动态，跟随 AssetStyle.current）
  static Map<String, String> get _imageMap => {
    ..._minionImageMap.map((k, v) => MapEntry(k, '$_baseMinions$v')),
    ..._spellImageMap.map((k, v) => MapEntry(k, '$_baseSpells$v')),
    ..._weaponImageMap.map((k, v) => MapEntry(k, '$_baseWeapons$v')),
  };
}
