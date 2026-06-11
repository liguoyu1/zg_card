/// 素材注册表 — 卡牌ID到资源路径的映射
/// 所有素材位于 assets/ 目录下
/// 素材注册表 — 卡牌ID到资源路径的映射
/// 所有素材位于 assets/ 目录下
class AssetRegistry {
  /// 获取英雄头像路径
  static String heroAsset(String heroId) {
    const map = {
      'H_B001': 'assets/heroes/bingjia_sunbin.png',
      'H_B002': 'assets/heroes/bingjia_wuqi.png',
      'H_B003': 'assets/heroes/bingjia_lianpo.png',
      'H_F001': 'assets/heroes/fajia_shangyang.png',
      'H_F002': 'assets/heroes/fajia_hanfei.png',
      'H_F003': 'assets/heroes/fajia_shenbuhai.png',
      'H_R001': 'assets/heroes/rujia_kongzi.png',
      'H_R002': 'assets/heroes/rujia_mengzi.png',
      'H_R003': 'assets/heroes/rujia_xunzi.png',
      'H_D001': 'assets/heroes/daojia_laozi.png',
      'H_D002': 'assets/heroes/daojia_zhuangzi.png',
      'H_D003': 'assets/heroes/daojia_liezi.png',
      'H_M001': 'assets/heroes/mojia_mozi.png',
      'H_M002': 'assets/heroes/mojia_gongshuban.png',
      'H_M003': 'assets/heroes/mojia_qinhuali.png',
      'H_Y001': 'assets/heroes/yinyangjia_zouyan.png',
      'H_Y002': 'assets/heroes/yinyangjia_gande.png',
      'H_Y003': 'assets/heroes/yinyangjia_shishen.png',
      'H_Z001': 'assets/heroes/zonghengjia_suqin.png',
      'H_Z002': 'assets/heroes/zonghengjia_zhangyi.png',
      'H_Z003': 'assets/heroes/zonghengjia_guiguzi.png',
    };
    return map[heroId] ?? 'assets/icons/icons_icon_bingjia.png';
  }

  /// 获取卡牌图片路径
  static String cardAsset(String cardId, String cardOwner) {
    const map = {
      'B008': 'assets/minions/bingjia_sunwu.png',
      'B009': 'assets/minions/bingjia_wuqi_minion.png',
      'B010': 'assets/minions/bingjia_sunbin_minion.png',
      'B011': 'assets/minions/bingjia_lianpo_minion.png',
      'B012': 'assets/minions/bingjia_li_mu.png',
      'F006': 'assets/minions/fajia_dali.png',
      'F008': 'assets/minions/fajia_shangyang_minion.png',
      'F009': 'assets/minions/fajia_hanfei_minion.png',
      'F010': 'assets/minions/fajia_dali.png',
      'F011': 'assets/minions/fajia_shenbuhai.png',
      'F012': 'assets/minions/fajia_wuqi_biange.png',
      'R006': 'assets/minions/rujia_xianren.png',
      'R008': 'assets/minions/rujia_kongzi_minion.png',
      'R009': 'assets/minions/rujia_mengzi_minion.png',
      'R010': 'assets/minions/rujia_xunzi_minion.png',
      'R012': 'assets/minions/rujia_xunzi_minion.png',
      'D008': 'assets/minions/daojia_laozi_minion.png',
      'D009': 'assets/minions/daojia_zhuangzi_minion.png',
      'D010': 'assets/minions/daojia_liezi_minion.png',
      'D012': 'assets/minions/daojia_yinshi.png',
      'M006': 'assets/minions/mojia_tianjiu.png',
      'M008': 'assets/minions/mojia_mozi_minion.png',
      'M009': 'assets/minions/mojia_gongshuban_minion.png',
      'M012': 'assets/minions/mojia_gongcheng_juxie.png',
      'Y006': 'assets/minions/yinyangjia_fangshushi.png',
      'Y008': 'assets/minions/yinyangjia_zouyan_minion.png',
      'Y009': 'assets/minions/yinyangjia_gande_minion.png',
      'Y010': 'assets/minions/yinyangjia_shishen_minion.png',
      'Z008': 'assets/minions/zonghengjia_guiguzi_minion.png',
      'Z009': 'assets/minions/zonghengjia_suqin_minion.png',
      'Z010': 'assets/minions/zonghengjia_zhangyi_minion.png',
      'N028': 'assets/minions/neutral_bawang.png',
      'N027': 'assets/minions/neutral_zhanshen.png',
      'N025': 'assets/minions/neutral_tiandi.png',
      'N026': 'assets/minions/neutral_shenlong.png',
    };
    if (map.containsKey(cardId)) return map[cardId]!;

    // 尝试法术/武器路径
    const spellMap = {
      'B013': 'assets/spells/spells_andc.png',
      'B014': 'assets/spells/spells_pofc.png',
      'B015': 'assets/spells/spells_beis.png',
      'B016': 'assets/spells/spells_andc.png',
      'B017': 'assets/spells/spells_shengdx.png',
      'B018': 'assets/spells/spells_shim.png',
      'B019': 'assets/spells/spells_yidf.png',
      'B020': 'assets/spells/spells_qinzq.png',
      'F013': 'assets/spells/spells_xingmzf.png',
      'F014': 'assets/spells/spells_junfy.png',
      'F015': 'assets/spells/spells_yifz.png',
      'F016': 'assets/spells/spells_yidf.png',
      'F017': 'assets/spells/spells_lianzf.png',
      'F018': 'assets/spells/spells_jianglg.png',
      'F019': 'assets/spells/spells_feicjt.png',
      'F020': 'assets/spells/spells_tongyd.png',
      'R013': 'assets/spells/spells_renzh.png',
      'R014': 'assets/spells/spells_lily.png',
      'R015': 'assets/spells/spells_jiaoh.png',
      'R016': 'assets/spells/spells_junfy.png',
      'R017': 'assets/spells/spells_yide.png',
      'R018': 'assets/spells/spells_shangr.png',
      'R019': 'assets/spells/spells_sanxs.png',
      'R020': 'assets/spells/spells_kejfl.png',
      'D013': 'assets/spells/spells_daofz.png',
      'D014': 'assets/spells/spells_wuwez.png',
      'D015': 'assets/spells/spells_youjwl.png',
      'D016': 'assets/spells/spells_xujw.png',
      'D017': 'assets/spells/spells_zaiyq.png',
      'D018': 'assets/spells/spells_danp.png',
      'D019': 'assets/spells/spells_daofz.png',
      'D020': 'assets/spells/spells_tianxy.png',
    };
    if (spellMap.containsKey(cardId)) return spellMap[cardId]!;

    // 默认：按职业显示图标
    const classIcons = {
      'bingjia': 'assets/icons/icons_icon_bingjia.png',
      'fajia': 'assets/icons/icons_icon_fajia.png',
      'rujia': 'assets/icons/icons_icon_rujia.png',
      'daojia': 'assets/icons/icons_icon_daojia.png',
      'mojia': 'assets/icons/icons_icon_mojia.png',
      'yinyangjia': 'assets/icons/icons_icon_yinyangjia.png',
      'zonghengjia': 'assets/icons/icons_icon_zonghengjia.png',
      'neutral': 'assets/icons/icons_icon_bingjia.png',
    };
    return classIcons[cardOwner] ?? 'assets/icons/icons_icon_bingjia.png';
  }

  /// 获取武器图片路径
  static String weaponAsset(String cardId) {
    const map = {
      'BW001': 'assets/weapons/weapons_weapon_qinwangjian.png',
      'BW002': 'assets/weapons/weapons_weapon_yuewangjian.png',
      'BW003': 'assets/weapons/weapons_weapon_zhangbashemao.png',
      'FW001': 'assets/weapons/weapons_weapon_fajialvchi.png',
      'FW002': 'assets/weapons/weapons_weapon_xingding.png',
      'R020': 'assets/weapons/weapons_weapon_rujiayugui.png',
      'RW001': 'assets/weapons/weapons_weapon_rujiayugui.png',
      'RW002': 'assets/weapons/weapons_weapon_liqibianzhong.png',
      'DW001': 'assets/weapons/weapons_weapon_taijijian.png',
      'DW002': 'assets/weapons/weapons_weapon_daojiafuchen.png',
      'MW001': 'assets/weapons/weapons_weapon_gongshuchi.png',
      'MW002': 'assets/weapons/weapons_weapon_mojiajgn.png',
      'YW001': 'assets/weapons/weapons_weapon_zhanxingluopan.png',
      'YW002': 'assets/weapons/weapons_weapon_wuxingzhang.png',
      'ZW001': 'assets/weapons/weapons_weapon_zonghengjia_dj.png',
      'ZW002': 'assets/weapons/weapons_weapon_hezhonglianhshu.png',
    };
    return map[cardId] ?? 'assets/weapons/weapons_weapon_qingtongjian.png';
  }
}