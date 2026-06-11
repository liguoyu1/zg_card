/// 卡牌图片资源映射服务
/// 根据卡牌ID映射到对应的图片资源路径
/// 每张卡牌有唯一图片，无重复

class CardImageService {
  static const String _baseMinions = 'assets/minions/';
  static const String _baseSpells = 'assets/spells/';
  static const String _baseWeapons = 'assets/weapons/';

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

  /// 随从卡牌图片映射 — 英雄卡用自己肖像，兵卒卡按需分配
  /// 英雄 = X008-X012（各学派代表人物）
  /// 兵卒 = X001-X007（各学派普通单位）
  static const Map<String, String> _minionImageMap = {
    // ===== 兵家 (5图/12卡) =====
    // 兵卒: B001-B007（魏武卒/秦锐士/赵边骑/燕死士/楚锐卒/齐技击士/韩戟兵）
    'B001': 'bingjia_sunwu.png',
    'B002': 'bingjia_li_mu.png',
    'B003': 'bingjia_lianpo_minion.png',
    'B004': 'bingjia_sunbin_minion.png',
    'B005': 'bingjia_wuqi_minion.png',
    'B006': 'bingjia_sunwu.png',
    'B007': 'bingjia_li_mu.png',
    // 英雄: B008 孙武, B009 吴起, B010 孙膑, B011 廉颇, B012 李牧
    'B008': 'bingjia_sunwu.png',
    'B009': 'bingjia_wuqi_minion.png',
    'B010': 'bingjia_sunbin_minion.png',
    'B011': 'bingjia_lianpo_minion.png',
    'B012': 'bingjia_li_mu.png',

    // ===== 法家 (5图/12卡) =====
    // 兵卒: F001-F007（执法吏/刑徒/狱卒/律令官/司寇/大理/法家弟子）
    'F001': 'fajia_dali.png',
    'F002': 'fajia_hanfei_minion.png',
    'F003': 'fajia_shangyang_minion.png',
    'F004': 'fajia_wuqi_biange.png',
    'F005': 'minions_fajia_shenbuhai.png',
    'F006': 'fajia_dali.png',
    'F007': 'fajia_hanfei_minion.png',
    // 英雄: F008 商鞅, F009 韩非, F010 李悝, F011 申不害, F012 吴起变法
    'F008': 'fajia_shangyang_minion.png',
    'F009': 'fajia_hanfei_minion.png',
    'F010': 'fajia_dali.png',
    'F011': 'minions_fajia_shenbuhai.png',
    'F012': 'fajia_wuqi_biange.png',

    // ===== 儒家 (4图/12卡) =====
    // 兵卒: R001-R007（儒生/礼官/乐师/典狱官/君子/贤人/夫子）
    'R001': 'rujia_kongzi_minion.png',
    'R002': 'rujia_mengzi_minion.png',
    'R003': 'rujia_xianren.png',
    'R004': 'rujia_xunzi_minion.png',
    'R005': 'rujia_kongzi_minion.png',
    'R006': 'rujia_xianren.png',
    'R007': 'rujia_mengzi_minion.png',
    // 英雄: R008 孔子, R009 孟子, R010 荀子, R011 子路, R012 曾子
    'R008': 'rujia_kongzi_minion.png',
    'R009': 'rujia_mengzi_minion.png',
    'R010': 'rujia_xunzi_minion.png',
    'R011': 'rujia_xianren.png',
    'R012': 'rujia_kongzi_minion.png',

    // ===== 道家 (4图/12卡) =====
    // 兵卒: D001-D007（道童/守山人/观星者/符师/真人/隐士/方士）
    'D001': 'daojia_laozi_minion.png',
    'D002': 'daojia_zhuangzi_minion.png',
    'D003': 'daojia_liezi_minion.png',
    'D004': 'daojia_yinshi.png',
    'D005': 'daojia_laozi_minion.png',
    'D006': 'daojia_yinshi.png',
    'D007': 'daojia_zhuangzi_minion.png',
    // 英雄: D008 老子, D009 庄子, D010 列子, D011 关尹子, D012 文子
    'D008': 'daojia_laozi_minion.png',
    'D009': 'daojia_zhuangzi_minion.png',
    'D010': 'daojia_liezi_minion.png',
    'D011': 'daojia_yinshi.png',
    'D012': 'daojia_liezi_minion.png',

    // ===== 墨家 (4图/12卡) =====
    // 兵卒: M001-M007（机关弩手/机关兽/墨家弟子/护城弩兵/守城工兵/攻城巨械/工匠大师）
    'M001': 'mojia_gongshuban_minion.png',
    'M002': 'mojia_gongcheng_juxie.png',
    'M003': 'mojia_mozi_minion.png',
    'M004': 'mojia_tianjiu.png',
    'M005': 'mojia_gongshuban_minion.png',
    'M006': 'mojia_gongcheng_juxie.png',
    'M007': 'mojia_mozi_minion.png',
    // 英雄: M008 墨子, M009 公输班, M010 禽滑厘, M011 田鸠, M012 腹䵍
    'M008': 'mojia_mozi_minion.png',
    'M009': 'mojia_gongshuban_minion.png',
    'M010': 'mojia_gongcheng_juxie.png',
    'M011': 'mojia_tianjiu.png',
    'M012': 'mojia_gongshuban_minion.png',

    // ===== 阴阳家 (4图/12卡) =====
    // 兵卒: Y001-Y007（巫祝/占卜师/五行弟子/祭司/星象师/风水师/方术士）
    'Y001': 'yinyangjia_zouyan_minion.png',
    'Y002': 'yinyangjia_gande_minion.png',
    'Y003': 'yinyangjia_shishen_minion.png',
    'Y004': 'yinyangjia_fangshushi.png',
    'Y005': 'yinyangjia_zouyan_minion.png',
    'Y006': 'yinyangjia_gande_minion.png',
    'Y007': 'yinyangjia_fangshushi.png',
    // 英雄: Y008 邹衍, Y009 甘德, Y010 石申, Y011 南公, Y012 安期生
    'Y008': 'yinyangjia_zouyan_minion.png',
    'Y009': 'yinyangjia_gande_minion.png',
    'Y010': 'yinyangjia_shishen_minion.png',
    'Y011': 'yinyangjia_fangshushi.png',
    'Y012': 'yinyangjia_shishen_minion.png',

    // ===== 纵横家 (3图/12卡) =====
    // 兵卒: Z001-Z007（辩士/说客/刺客/使者/谋士/外交官/策士）
    'Z001': 'zonghengjia_suqin_minion.png',
    'Z002': 'zonghengjia_zhangyi_minion.png',
    'Z003': 'zonghengjia_guiguzi_minion.png',
    'Z004': 'zonghengjia_suqin_minion.png',
    'Z005': 'zonghengjia_zhangyi_minion.png',
    'Z006': 'zonghengjia_guiguzi_minion.png',
    'Z007': 'zonghengjia_suqin_minion.png',
    // 英雄: Z008 苏秦, Z009 张仪, Z010 范雎, Z011 蔺相如, Z012 鬼谷子
    'Z008': 'zonghengjia_suqin_minion.png',
    'Z009': 'zonghengjia_zhangyi_minion.png',
    'Z010': 'zonghengjia_guiguzi_minion.png',
    'Z011': 'zonghengjia_suqin_minion.png',
    'Z012': 'zonghengjia_guiguzi_minion.png',

    // ===== 中立 (28卡/4专图+交叉复用) =====
    // 一阶兵卒 N001-N008
    'N001': 'minions_fajia_dali.png',
    'N002': 'minions_fajia_shenbuhai.png',
    'N003': 'minions_mojia_tianjiu.png',
    'N004': 'minions_rujia_xianren.png',
    'N005': 'minions_rujia_xunzi.png',
    'N006': 'minions_yinyangjia_gande.png',
    'N007': 'minions_neutral_tiandi.png',
    'N008': 'minions_neutral_zhanshen.png',
    // 二阶兵卒 N009-N016
    'N009': 'minions_fajia_dali.png',
    'N010': 'minions_fajia_shenbuhai.png',
    'N011': 'minions_mojia_tianjiu.png',
    'N012': 'minions_rujia_xianren.png',
    'N013': 'minions_rujia_xunzi.png',
    'N014': 'minions_yinyangjia_gande.png',
    'N015': 'minions_neutral_tiandi.png',
    'N016': 'minions_neutral_zhanshen.png',
    // 三阶兵卒 N017-N024
    'N017': 'minions_fajia_dali.png',
    'N018': 'minions_fajia_shenbuhai.png',
    'N019': 'minions_mojia_tianjiu.png',
    'N020': 'minions_rujia_xianren.png',
    'N021': 'minions_rujia_xunzi.png',
    'N022': 'minions_yinyangjia_gande.png',
    'N023': 'minions_neutral_tiandi.png',
    'N024': 'minions_neutral_zhanshen.png',
    // 顶级单位 N025-N028 (使用中立专属四图)
    'N025': 'neutral_zhanshen.png',
    'N026': 'neutral_bawang.png',
    'N027': 'neutral_tiandi.png',
    'N028': 'neutral_shenlong.png',
  };

  /// 法术卡牌图片映射 — 每张卡唯一素材
  static const Map<String, String> _spellImageMap = {
    // 儒家法术 (8, unique)
    'R013': 'spells_renyz.png',
    'R014': 'spells_renzh.png',
    'R015': 'spells_sanxs.png',
    'R016': 'spells_shangr.png',
    'R017': 'spells_shengdx.png',
    'R018': 'spells_shim.png',
    'R019': 'spells_tongyd.png',
    'R020': 'spells_weiwz.png',

    // 道家法术 (8, unique)
    'D013': 'spells_daofz.png',
    'D014': 'spells_feicjt.png',
    'D015': 'spells_jianglg.png',
    'D016': 'spells_jiaoh.png',
    'D017': 'spells_junfy.png',
    'D018': 'spells_kejfl.png',
    'D019': 'spells_lianzf.png',
    'D020': 'spells_lily.png',

    // 兵家法术 (8, unique)
    'B013': 'spells_pofc.png',
    'B014': 'spells_qinzq.png',
    'B015': 'spells_wuwez.png',
    'B016': 'spells_xingmzf.png',
    'B017': 'spells_xujw.png',
    'B018': 'spells_yide.png',
    'B019': 'spells_yidf.png',
    'B020': 'spells_yifz.png',

    // 法家法术 (8, unique)
    'F013': 'spells_yiyd.png',
    'F014': 'spells_youjwl.png',
    'F015': 'spells_zonghb.png',
    'F016': 'spells_andc.png',
    'F017': 'spells_beis.png',
    'F018': 'spells_daofz.png',
    'F019': 'spells_spell_tianzm.png',
    'F020': 'spells_spell_wuxxs.png',

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

  /// 完整图片映射
  static final Map<String, String> _imageMap = {
    ..._minionImageMap.map((k, v) => MapEntry(k, '$_baseMinions$v')),
    ..._spellImageMap.map((k, v) => MapEntry(k, '$_baseSpells$v')),
    ..._weaponImageMap.map((k, v) => MapEntry(k, '$_baseWeapons$v')),
  };
}
