import 'package:warring_states_card/core/asset_style.dart';

class AssetRegistry {
  static String get _base => 'assets/${AssetStyle.current.dirName}/';

  static String heroAsset(String heroId) {
    const names = {
      'H_B001': 'bingjia_sunbin.png',
      'H_B002': 'bingjia_wuqi.png',
      'H_B003': 'bingjia_lianpo.png',
      'H_F001': 'fajia_shangyang.png',
      'H_F002': 'fajia_hanfei.png',
      'H_F003': 'fajia_shenbuhai.png',
      'H_R001': 'rujia_kongzi.png',
      'H_R002': 'rujia_mengzi.png',
      'H_R003': 'rujia_xunzi.png',
      'H_D001': 'daojia_laozi.png',
      'H_D002': 'daojia_zhuangzi.png',
      'H_D003': 'daojia_liezi.png',
      'H_M001': 'mojia_mozi.png',
      'H_M002': 'mojia_gongshuban.png',
      'H_M003': 'mojia_qinhuali.png',
      'H_Y001': 'yinyangjia_zouyan.png',
      'H_Y002': 'yinyangjia_gande.png',
      'H_Y003': 'yinyangjia_shishen.png',
      'H_Z001': 'zonghengjia_suqin.png',
      'H_Z002': 'zonghengjia_zhangyi.png',
      'H_Z003': 'zonghengjia_guiguzi.png',
    };
    final file = names[heroId] ?? 'icons_icon_bingjia.png';
    return '${_base}heroes/$file';
  }

  static String cardAsset(String cardId, String cardOwner) {
    const minions = {
      'B008': 'bingjia_sunwu.png',
      'B009': 'bingjia_wuqi_minion.png',
      'B010': 'bingjia_sunbin_minion.png',
      'B011': 'bingjia_lianpo_minion.png',
      'B012': 'bingjia_li_mu.png',
      'F006': 'fajia_dali.png',
      'F008': 'fajia_shangyang_minion.png',
      'F009': 'fajia_hanfei_minion.png',
      'F010': 'fajia_dali.png',
      'F011': 'fajia_shenbuhai.png',
      'F012': 'fajia_wuqi_biange.png',
      'R006': 'rujia_xianren.png',
      'R008': 'rujia_kongzi_minion.png',
      'R009': 'rujia_mengzi_minion.png',
      'R010': 'rujia_xunzi_minion.png',
      'R012': 'rujia_xunzi_minion.png',
      'D008': 'daojia_laozi_minion.png',
      'D009': 'daojia_zhuangzi_minion.png',
      'D010': 'daojia_liezi_minion.png',
      'D012': 'daojia_yinshi.png',
      'M006': 'mojia_tianjiu.png',
      'M008': 'mojia_mozi_minion.png',
      'M009': 'mojia_gongshuban_minion.png',
      'M012': 'mojia_gongcheng_juxie.png',
      'Y006': 'yinyangjia_fangshushi.png',
      'Y008': 'yinyangjia_zouyan_minion.png',
      'Y009': 'yinyangjia_gande_minion.png',
      'Y010': 'yinyangjia_shishen_minion.png',
      'Z008': 'zonghengjia_guiguzi_minion.png',
      'Z009': 'zonghengjia_suqin_minion.png',
      'Z010': 'zonghengjia_zhangyi_minion.png',
      'N028': 'neutral_bawang.png',
      'N027': 'neutral_zhanshen.png',
      'N025': 'neutral_tiandi.png',
      'N026': 'neutral_shenlong.png',
    };
    if (minions.containsKey(cardId)) {
      return '${_base}minions/${minions[cardId]}';
    }

    const spells = {
      'B013': 'spells_andc.png',
      'B014': 'spells_pofc.png',
      'B015': 'spells_beis.png',
      'B016': 'spells_andc.png',
      'B017': 'spells_shengdx.png',
      'B018': 'spells_shim.png',
      'B019': 'spells_yidf.png',
      'B020': 'spells_qinzq.png',
      'F013': 'spells_xingmzf.png',
      'F014': 'spells_junfy.png',
      'F015': 'spells_yifz.png',
      'F016': 'spells_yidf.png',
      'F017': 'spells_lianzf.png',
      'F018': 'spells_jianglg.png',
      'F019': 'spells_feicjt.png',
      'F020': 'spells_tongyd.png',
      'R013': 'spells_renzh.png',
      'R014': 'spells_lily.png',
      'R015': 'spells_jiaoh.png',
      'R016': 'spells_junfy.png',
      'R017': 'spells_yide.png',
      'R018': 'spells_shangr.png',
      'R019': 'spells_sanxs.png',
      'R020': 'spells_kejfl.png',
      'D013': 'spells_daofz.png',
      'D014': 'spells_wuwez.png',
      'D015': 'spells_youjwl.png',
      'D016': 'spells_xujw.png',
      'D017': 'spells_zaiyq.png',
      'D018': 'spells_danp.png',
      'D019': 'spells_daofz.png',
      'D020': 'spells_tianxy.png',
    };
    if (spells.containsKey(cardId)) {
      return '${_base}spells/${spells[cardId]}';
    }

    const classIcons = {
      'bingjia': 'icons_icon_bingjia.png',
      'fajia': 'icons_icon_fajia.png',
      'rujia': 'icons_icon_rujia.png',
      'daojia': 'icons_icon_daojia.png',
      'mojia': 'icons_icon_mojia.png',
      'yinyangjia': 'icons_icon_yinyangjia.png',
      'zonghengjia': 'icons_icon_zonghengjia.png',
      'neutral': 'icons_icon_bingjia.png',
    };
    return 'assets/icons/${classIcons[cardOwner] ?? "icons_icon_bingjia.png"}';
  }

  static String weaponAsset(String cardId) {
    const names = {
      'BW001': 'qinwangjian.png',
      'BW002': 'yuewangjian.png',
      'BW003': 'zhangbashemao.png',
      'FW001': 'fajialvchi.png',
      'FW002': 'xingding.png',
      'RW001': 'rujiayugui.png',
      'RW002': 'liqibianzhong.png',
      'DW001': 'taijijian.png',
      'DW002': 'daojiafuchen.png',
      'MW001': 'gongshuchi.png',
      'MW002': 'mojiajgn.png',
      'YW001': 'zhanxingluopan.png',
      'YW002': 'wuxingzhang.png',
      'ZW001': 'zonghengjia_dj.png',
      'ZW002': 'hezhonglianhshu.png',
    };
    final file = names[cardId] ?? 'qingtongjian.png';
    return '${_base}weapons/$file';
  }
}
