/// 卡牌图片资源映射服务
/// 根据卡牌ID映射到对应的图片资源路径
/// 每张卡牌有唯一图片，无重复

import 'package:warring_states_card/core/asset_style.dart';

class CardImageService {
  static String get _base => 'assets/${AssetStyle.current.dirName}/';
  static String get _baseMinions => '${_base}minions/';
  static String get _baseSpells => '${_base}spells/';
  static String get _baseWeapons => '${_base}weapons/';

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

  /// 随从卡牌图片映射 — 每张卡独立图片
  /// 兵卒 = X001-X007, 英雄 = X008-X012
  static const Map<String, String> _minionImageMap = {
    // ===== 兵家 (12卡) =====
    'B001': 'bingjia_wuwuzu.png',    // 魏武卒
    'B002': 'bingjia_ruishi.png',    // 秦锐士
    'B003': 'bingjia_bianqi.png',    // 赵边骑
    'B004': 'bingjia_sishi.png',     // 燕死士
    'B005': 'bingjia_ruiz.png',      // 楚锐卒
    'B006': 'bingjia_jijishi.png',   // 齐技击士
    'B007': 'bingjia_jibing.png',    // 韩戟兵
    'B008': 'bingjia_sunwu.png',      // 孙武
    'B009': 'bingjia_wuqi_minion.png',  // 吴起
    'B010': 'bingjia_sunbin_minion.png', // 孙膑
    'B011': 'bingjia_lianpo_minion.png', // 廉颇
    'B012': 'bingjia_li_mu.png',      // 李牧

    // ===== 法家 (12卡) =====
    'F001': 'fajia_zhifuli.png',     // 执法吏
    'F002': 'fajia_xingtu.png',      // 刑徒
    'F003': 'fajia_yuzu.png',        // 狱卒
    'F004': 'fajia_lvlingguan.png',  // 律令官
    'F005': 'fajia_sikou.png',       // 司寇
    'F006': 'fajia_dali.png',        // 大理
    'F007': 'fajia_disciples.png',   // 法家弟子
    'F008': 'fajia_shangyang_minion.png', // 商鞅
    'F009': 'fajia_hanfei_minion.png',   // 韩非
    'F010': 'fajia_dali_minion.png',     // 李悝
    'F011': 'minions_fajia_shenbuhai.png', // 申不害
    'F012': 'fajia_wuqi_biange.png',  // 吴起变法

    // ===== 儒家 (12卡) =====
    'R001': 'rujia_rusheng.png',     // 儒生
    'R002': 'rujia_liguan.png',      // 礼官
    'R003': 'rujia_yueshi.png',      // 乐师
    'R004': 'rujia_dianyuguan.png',  // 典狱官
    'R005': 'rujia_junzi.png',       // 君子
    'R006': 'rujia_xianren_minion.png', // 贤人
    'R007': 'rujia_fuzi.png',        // 夫子
    'R008': 'rujia_kongzi_minion.png',  // 孔子
    'R009': 'rujia_mengzi_minion.png',  // 孟子
    'R010': 'rujia_xunzi_minion.png',   // 荀子
    'R011': 'rujia_xianren.png',     // 子路（复用贤人）
    'R012': 'rujia_xunzi.png',       // 曾子（复用荀子）

    // ===== 道家 (12卡) =====
    'D001': 'daojia_daotong.png',    // 道童
    'D002': 'daojia_shoushanren.png', // 守山人
    'D003': 'daojia_guanxingzhe.png', // 观星者
    'D004': 'daojia_fushi.png',       // 符师
    'D005': 'daojia_zhenren.png',     // 真人
    'D006': 'daojia_yinshi_minion.png', // 隐士
    'D007': 'daojia_fangshi.png',     // 方士
    'D008': 'daojia_laozi_minion.png', // 老子
    'D009': 'daojia_zhuangzi_minion.png', // 庄子
    'D010': 'daojia_liezi_minion.png',   // 列子
    'D011': 'daojia_fangshi.png',     // 关尹子（复用方士）
    'D012': 'daojia_yinshi_minion.png', // 文子（复用隐士）

    // ===== 墨家 (12卡) =====
    'M001': 'mojia_jiguanshou.png',   // 机关弩手
    'M002': 'mojia_jiguanjiashi.png', // 机关兽
    'M003': 'mojia_disciples.png',    // 墨家弟子
    'M004': 'mojia_hucheng.png',      // 护城弩兵
    'M005': 'mojia_shoucheng.png',    // 守城工兵
    'M006': 'mojia_gongcheng_juxie.png', // 攻城巨械
    'M007': 'mojia_gongjiang.png',    // 工匠大师
    'M008': 'mojia_mozi_minion.png',  // 墨子
    'M009': 'mojia_gongshuban_minion.png', // 公输班
    'M010': 'mojia_tianjiu.png',      // 禽滑厘
    'M011': 'minions_mojia_tianjiu.png', // 田鸠
    'M012': 'mojia_gongshuban_minion.png', // 腹䵍（复用公输班）

    // ===== 阴阳家 (12卡) =====
    'Y001': 'yinyangjia_wuzhu.png',       // 巫祝
    'Y002': 'yinyangjia_zhanbu.png',      // 占卜师
    'Y003': 'yinyangjia_wuxing.png',      // 五行弟子
    'Y004': 'yinyangjia_jisi.png',        // 祭司
    'Y005': 'yinyangjia_xingxiang.png',   // 星象师
    'Y006': 'yinyangjia_fengshui.png',    // 风水师
    'Y007': 'yinyangjia_fangshushi.png',  // 方术士
    'Y008': 'yinyangjia_zouyan_minion.png',  // 邹衍
    'Y009': 'yinyangjia_gande_minion.png',   // 甘德
    'Y010': 'yinyangjia_shishen_minion.png', // 石申
    'Y011': 'yinyangjia_fangshushi_minion.png', // 南公
    'Y012': 'yinyangjia_fangshushi_minion.png', // 安期生

    // ===== 纵横家 (12卡) =====
    'Z001': 'zonghengjia_bianshi.png',    // 辩士
    'Z002': 'zonghengjia_suoke.png',      // 说客
    'Z003': 'zonghengjia_cike.png',       // 刺客
    'Z004': 'zonghengjia_shizhe.png',     // 使者
    'Z005': 'zonghengjia_moushi.png',     // 谋士
    'Z006': 'zonghengjia_waijiao.png',    // 外交官
    'Z007': 'zonghengjia_ceshi.png',      // 策士
    'Z008': 'zonghengjia_suqin_minion.png',  // 苏秦
    'Z009': 'zonghengjia_zhangyi_minion.png', // 张仪
    'Z010': 'zonghengjia_guiguzi_minion.png', // 范雎
    'Z011': 'zonghengjia_shizhe.png',     // 蔺相如（复用使者）
    'Z012': 'zonghengjia_guiguzi_minion.png', // 鬼谷子

    // ===== 中立 (28卡, 8图循环+4顶级专图) =====
    'N001': 'minions_fajia_dali.png',
    'N002': 'minions_fajia_shenbuhai.png',
    'N003': 'minions_mojia_tianjiu.png',
    'N004': 'minions_rujia_xianren.png',
    'N005': 'minions_rujia_xunzi.png',
    'N006': 'minions_yinyangjia_gande.png',
    'N007': 'minions_neutral_tiandi.png',
    'N008': 'minions_neutral_zhanshen.png',
    'N009': 'minions_fajia_dali.png',
    'N010': 'minions_fajia_shenbuhai.png',
    'N011': 'minions_mojia_tianjiu.png',
    'N012': 'minions_rujia_xianren.png',
    'N013': 'minions_rujia_xunzi.png',
    'N014': 'minions_yinyangjia_gande.png',
    'N015': 'minions_neutral_tiandi.png',
    'N016': 'minions_neutral_zhanshen.png',
    'N017': 'minions_fajia_dali.png',
    'N018': 'minions_fajia_shenbuhai.png',
    'N019': 'minions_mojia_tianjiu.png',
    'N020': 'minions_rujia_xianren.png',
    'N021': 'minions_rujia_xunzi.png',
    'N022': 'minions_yinyangjia_gande.png',
    'N023': 'minions_neutral_tiandi.png',
    'N024': 'minions_neutral_zhanshen.png',
    'N025': 'neutral_zhanshen.png',
    'N026': 'neutral_bawang.png',
    'N027': 'neutral_tiandi.png',
    'N028': 'neutral_shenlong.png',
  };

  /// 法术卡牌图片映射 — 每张卡唯一素材 (spells_spell_=新版, spells_=废弃)
  static const Map<String, String> _spellImageMap = {
    // 儒家法术 (8, unique)
    'R013': 'spells_spell_renzh.png',    // 仁政化民
    'R014': 'spells_spell_lily.png',     // 礼乐同春
    'R015': 'spells_spell_jiaoh.png',    // 教化众生
    'R016': 'spells_spell_junfy.png',    // 仁义之师
    'R017': 'spells_spell_yide.png',     // 以德服人
    'R018': 'spells_spell_shangr.png',   // 三省吾身
    'R019': 'spells_spell_sanxs.png',    // 有教无类
    'R020': 'spells_spell_kejfl.png',    // 克己复礼

    // 道家法术 (6+2待生成)
    'D013': 'spells_spell_daofz.png',    // 道法自然
    'D014': 'spells_spell_wuwez.png',    // 无为而治
    'D015': 'spells_spell_youjwl.png',   // 上善若水
    'D016': 'spells_spell_xujw.png',     // 虚静无为
    // D017 齐物论 — 待生成新版素材
    // D018 逍遥游 — 待生成新版素材
    'D019': 'spells_spell_daofz.png',    // 养生主
    'D020': 'spells_spell_tianxy.png',   // 庖丁解牛

    // 兵家法术 (8, unique)
    'B013': 'spells_spell_weiwz.png',    // 围魏救赵
    'B014': 'spells_spell_pofc.png',     // 破釜沉舟
    'B015': 'spells_spell_beis.png',     // 背水一战
    'B016': 'spells_spell_andc.png',     // 暗度陈仓
    'B017': 'spells_spell_shengdx.png',  // 声东击西
    'B018': 'spells_spell_shim.png',     // 十面埋伏
    'B019': 'spells_spell_yidf.png',     // 以逸待劳
    'B020': 'spells_spell_qinzq.png',    // 擒贼擒王

    // 法家法术 (8, unique)
    'F013': 'spells_spell_xingmzf.png',  // 刑名之法
    'F014': 'spells_spell_junfy.png',    // 峻法严刑
    'F015': 'spells_spell_yifz.png',     // 一断于法
    'F016': 'spells_spell_yidf.png',     // 以法治国
    'F017': 'spells_spell_lianzf.png',   // 连坐之法
    'F018': 'spells_spell_jianglg.png',  // 奖励耕战
    'F019': 'spells_spell_feicjt.png',   // 废除井田
    'F020': 'spells_spell_tongyd.png',   // 统一度量

    // 墨家法术 (8, unique)
    'M013': 'spells_spell_wudzs.png',
    'M014': 'spells_spell_wanbgz.png',
    'M015': 'spells_spell_tianxy.png',
    'M016': 'spells_spell_andc.png',
    'M017': 'spells_spell_beis.png',
    'M018': 'spells_spell_dajzs.png',
    'M019': 'spells_spell_dangsz.png',
    'M020': 'spells_spell_daofz.png',

    // 阴阳家法术 (8, unique)
    'Y013': 'spells_spell_diaohl.png',
    'Y014': 'spells_spell_feicjt.png',
    'Y015': 'spells_spell_feiyf.png',
    'Y016': 'spells_spell_furuix.png',
    'Y017': 'spells_spell_hezong.png',
    'Y018': 'spells_spell_jianaf.png',
    'Y019': 'spells_spell_jianglg.png',
    'Y020': 'spells_spell_jiaoh.png',

    // 纵横家法术 (8, unique)
    'Z013': 'spells_spell_jieyj.png',
    'Z014': 'spells_spell_jigzs.png',
    'Z015': 'spells_spell_junfy.png',
    'Z016': 'spells_spell_kejfl.png',
    'Z017': 'spells_spell_kongcj.png',
    'Z018': 'spells_spell_lianh.png',
    'Z019': 'spells_spell_lianzf.png',
    'Z020': 'spells_spell_lijj.png',

    // 中立法术 (10, unique)
    'N029': 'spells_spell_lily.png',
    'N030': 'spells_spell_moshcg.png',
    'N031': 'spells_spell_paodjn.png',
    'N032': 'spells_spell_pofc.png',
    'N033': 'spells_spell_qinzq.png',
    'N034': 'spells_spell_qiwl.png',
    'N035': 'spells_spell_renyz.png',
    'N036': 'spells_spell_renzh.png',
    'N037': 'spells_spell_sanxs.png',
    'N038': 'spells_spell_shangr.png',
  };

  /// 武器卡牌图片映射 — 每张卡唯一素材
  static const Map<String, String> _weaponImageMap = {
    'RW001': 'weapons_weapon_rujiayugui.png',
    'RW002': 'weapons_weapon_liqibianzhong.png',
    'DW001': 'weapons_weapon_daojiafuchen.png',
    'DW002': 'weapons_weapon_taijijian.png',
    'BW001': 'weapons_weapon_wugou.png',
    'BW002': 'weapons_weapon_yuewangjian.png',
    'BW003': 'weapons_weapon_zhangbashemao.png',
    'FW001': 'weapons_weapon_fajialvchi.png',
    'FW002': 'weapons_weapon_xingding.png',
    'MW001': 'weapons_weapon_mojiajgn.png',
    'MW002': 'weapons_weapon_gongshuchi.png',
    'YW001': 'weapons_weapon_wuxingzhang.png',
    'YW002': 'weapons_weapon_zhanxingluopan.png',
    'ZW001': 'weapons_weapon_zonghengjia_dj.png',
    'ZW002': 'weapons_weapon_hezhonglianhshu.png',
    'NW001': 'weapons_weapon_qingtongjian.png',
    'NW002': 'weapons_weapon_changji.png',
    'NW003': 'weapons_weapon_qinwangjian.png',
  };

  /// 完整图片映射（动态，跟随 AssetStyle.current）
  static Map<String, String> get _imageMap => {
    ..._minionImageMap.map((k, v) => MapEntry(k, '$_baseMinions$v')),
    ..._spellImageMap.map((k, v) => MapEntry(k, '$_baseSpells$v')),
    ..._weaponImageMap.map((k, v) => MapEntry(k, '$_baseWeapons$v')),
  };
}
