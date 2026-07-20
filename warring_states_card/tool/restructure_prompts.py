#!/usr/bin/env python3
"""将三套风格提示词从旧结构 {'style','cards':{ID:{name,prompt}}} 转换为每卡 {name,en_name,card_type,prompt}"""

import json, os

DIR = os.path.join(os.path.dirname(__file__), "..", "assets")

# === card_type 映射表（从 ID 前缀推断） ===
CARD_TYPE = {}
# 手动标注每个 ID 的 type
_EXPLICIT = {
    # 兵家
    "B013":"spell","B014":"spell","B015":"spell","B016":"spell",
    "B017":"spell","B018":"spell","B019":"spell","B020":"spell",
    "BW001":"weapon","BW002":"weapon","BW003":"weapon",
    # 法家
    "F013":"spell","F014":"spell","F015":"spell","F016":"spell",
    "F017":"spell","F018":"spell","F019":"spell","F020":"spell",
    "FW001":"weapon","FW002":"weapon",
    # 墨家
    "M013":"spell","M014":"spell","M015":"spell","M016":"spell",
    "M017":"spell","M018":"spell","M019":"spell","M020":"spell",
    "MW001":"weapon","MW002":"weapon",
    # 阴阳家
    "Y013":"spell","Y014":"spell","Y015":"spell","Y016":"spell",
    "Y017":"spell","Y018":"spell","Y019":"spell","Y020":"spell",
    "YW001":"weapon","YW002":"weapon",
    # 纵横家
    "Z013":"spell","Z014":"spell","Z015":"spell","Z016":"spell",
    "Z017":"spell","Z018":"spell","Z019":"spell","Z020":"spell",
    "ZW001":"weapon","ZW002":"weapon",
    # 中立
    "N029":"spell","N030":"spell","N031":"spell","N032":"spell",
    "N033":"spell","N034":"spell","N035":"spell","N036":"spell",
    "N037":"spell","N038":"spell",
    "NW001":"weapon","NW002":"weapon","NW003":"weapon",
    # 儒家
    "R013":"spell","R014":"spell","R015":"spell","R016":"spell",
    "R017":"spell","R018":"spell","R019":"spell","R020":"spell",
    "RW001":"weapon","RW002":"weapon",
    # 道家
    "D013":"spell","D014":"spell","D015":"spell","D016":"spell",
    "D017":"spell","D018":"spell","D019":"spell","D020":"spell",
    "DW001":"weapon","DW002":"weapon",
}
# 英雄 ID → card_type=hero
HERO_IDS = {
    "H_B001","H_B002","H_B003","H_F001","H_F002","H_F003",
    "H_R001","H_R002","H_R003","H_D001","H_D002","H_D003",
    "H_M001","H_M002","H_M003","H_Y001","H_Y002","H_Y003",
    "H_Z001","H_Z002","H_Z003","H_S001","H_S002","H_S003",
}

DEFAULT_TYPE = "minion"

def get_card_type(cid):
    if cid in _EXPLICIT:
        return _EXPLICIT[cid]
    if cid in HERO_IDS:
        return "hero"
    return DEFAULT_TYPE

# === 拼音（从 generate_gemini_prompts.py 复制）===
PINYIN = {
    "魏武卒":"wei_wu_zu","秦锐士":"qin_rui_shi","赵边骑":"zhao_bian_qi",
    "燕死士":"yan_si_shi","楚锐卒":"chu_rui_zu","齐技击士":"qi_ji_ji_shi",
    "韩戟兵":"han_ji_bing","孙武":"sun_wu","吴起":"wu_qi",
    "孙膑":"sun_bin","廉颇":"lian_po","李牧":"li_mu",
    "围魏救赵":"wei_wei_jiu_zhao","破釜沉舟":"po_fu_chen_zhou",
    "背水一战":"bei_shui_yi_zhan","暗度陈仓":"an_du_chen_cang",
    "声东击西":"sheng_dong_ji_xi","十面埋伏":"shi_mian_mai_fu",
    "以逸待劳":"yi_yi_dai_lao","擒贼擒王":"qin_zei_qin_wang",
    "吴钩":"wu_gou","越王剑":"yue_wang_jian","丈八蛇矛":"zhang_ba_she_mao",
    "执法吏":"zhi_fa_li","刑徒":"xing_tu","狱卒":"yu_zu",
    "律令官":"lv_ling_guan","司寇":"si_kou","大理":"da_li",
    "法家弟子":"fa_jia_di_zi","商鞅":"shang_yang","韩非":"han_fei",
    "李悝":"li_kui","申不害":"shen_bu_hai","吴起变法":"wu_qi_bian_fa",
    "刑名之法":"xing_ming_zhi_fa","峻法严刑":"jun_fa_yan_xing",
    "一断于法":"yi_duan_yu_fa","以法治国":"yi_fa_zhi_guo",
    "连坐之法":"lian_zuo_zhi_fa","奖励耕战":"jiang_li_geng_zhan",
    "废除井田":"fei_chu_jing_tian","统一度量":"tong_yi_du_liang",
    "法家律尺":"fa_jia_lv_chi","刑鼎":"xing_ding",
    "机关弩手":"ji_guan_nu_shou","机关兽":"ji_guan_shou",
    "墨家弟子":"mo_jia_di_zi","护城弩兵":"hu_cheng_nu_bing",
    "守城工兵":"shou_cheng_gong_bing","攻城巨械":"gong_cheng_ju_xie",
    "工匠大师":"gong_jiang_da_shi","墨子":"mo_zi",
    "公输班":"gong_shu_ban","禽滑厘":"qin_hua_li",
    "田鸠":"tian_jiu","腹䵍":"fu_tun",
    "兼爱非攻":"jian_ai_fei_gong","墨守成规":"mo_shou_cheng_gui",
    "机关之术":"ji_guan_zhi_shu","挡矢之术":"dang_shi_zhi_shu",
    "节用节葬":"jie_yong_jie_zang","尚贤尚同":"shang_xian_shang_tong",
    "天志明鬼":"tian_zhi_ming_gui","非乐非命":"fei_le_fei_ming",
    "墨家机关弩":"mo_jia_ji_guan_nu","公输尺":"gong_shu_chi",
    "巫祝":"wu_zhu","占卜师":"zhan_bu_shi","五行弟子":"wu_xing_di_zi",
    "祭司":"ji_si","星象师":"xing_xiang_shi","风水师":"feng_shui_shi",
    "方术士":"fang_shu_shi","邹衍":"zou_yan","甘德":"gan_de",
    "石申":"shi_shen","南公":"nan_gong","安期生":"an_qi_sheng",
    "五行相生":"wu_xing_xiang_sheng","阴阳调和":"yin_yang_tiao_he",
    "天象异变":"tian_xiang_yi_bian","占星问卜":"zhan_xing_wen_bu",
    "大九州说":"da_jiu_zhou_shuo","五德终始":"wu_de_zhong_shi",
    "灾异谴告":"zai_yi_qian_gao","符瑞祥兆":"fu_rui_xiang_zhao",
    "阴阳五行杖":"yin_yang_wu_xing_zhang","占星罗盘":"zhan_xing_luo_pan",
    "辩士":"bian_shi","说客":"shuo_ke","刺客":"ci_ke",
    "使者":"shi_zhe","谋士":"mou_shi","外交官":"wai_jiao_guan",
    "策士":"ce_shi","苏秦":"su_qin","张仪":"zhang_yi",
    "范雎":"fan_ju","蔺相如":"lin_xiang_ru","鬼谷子":"gui_gu_zi",
    "连横":"lian_heng","合纵":"he_zong","远交近攻":"yuan_jiao_jin_gong",
    "纵横捭阖":"zong_heng_bai_he","完璧归赵":"wan_bi_gui_zhao",
    "离间计":"li_jian_ji","空城计":"kong_cheng_ji","调虎离山":"diao_hu_li_shan",
    "纵横家短剑":"zong_heng_jia_duan_jian","合纵连横书":"he_zong_lian_heng_shu",
    "民兵":"min_bing","斥候":"chi_hou","流浪者":"liu_lang_zhe",
    "侍卫":"shi_wei","剑客":"jian_ke","药师":"yao_shi",
    "甲士":"jia_shi","弓手":"gong_shou","骑兵":"qi_bing",
    "方士":"fang_shi","医师":"yi_shi","将领":"jiang_ling",
    "校尉":"xiao_wei","武士":"wu_shi","都尉":"du_wei",
    "猛将":"meng_jiang","谋主":"mou_zhu","猛犸":"meng_ma",
    "将军":"jiang_jun","勇士":"yong_shi","宗师":"zong_shi",
    "上将军":"shang_jiang_jun","战神":"zhan_shen","霸王":"ba_wang",
    "天帝":"tian_di","神龙":"shen_long",
    "调兵遣将":"diao_bing_qian_jiang","四面楚歌":"si_mian_chu_ge",
    "知己知彼":"zhi_ji_zhi_bi","坚壁清野":"jian_bi_qing_ye",
    "以少胜多":"yi_shao_sheng_duo","奇袭":"qi_xi",
    "增援":"zeng_yuan","决胜局":"jue_sheng_ju",
    "横扫千军":"heng_sao_qian_jun","反戈一击":"fan_ge_yi_ji",
    "青铜剑":"qing_tong_jian","长戟":"chang_ji","秦王剑":"qin_wang_jian",
    "儒生":"ru_sheng","礼官":"li_guan","乐师":"yue_shi",
    "典狱官":"dian_yu_guan","君子":"jun_zi","贤人":"xian_ren",
    "夫子":"fu_zi","孔子":"kong_zi","孟子":"meng_zi",
    "荀子":"xun_zi","子路":"zi_lu","曾子":"ceng_zi",
    "仁政化民":"ren_zheng_hua_min","礼乐同春":"li_yue_tong_chun",
    "教化众生":"jiao_hua_zhong_sheng","仁义之师":"ren_yi_zhi_shi",
    "以德服人":"yi_de_fu_ren","三省吾身":"san_xing_wu_shen",
    "有教无类":"you_jiao_wu_lei","克己复礼":"ke_ji_fu_li",
    "儒家玉圭":"ru_jia_yu_gui","礼器编钟":"li_qi_bian_zhong",
    "道童":"dao_tong","守山人":"shou_shan_ren","观星者":"guan_xing_zhe",
    "符师":"fu_shi","真人":"zhen_ren","隐士":"yin_shi",
    "老子":"lao_zi","庄子":"zhuang_zi","列子":"lie_zi",
    "关尹子":"guan_yin_zi","文子":"wen_zi",
    "道法自然":"dao_fa_zi_ran","无为而治":"wu_wei_er_zhi",
    "上善若水":"shang_shan_ruo_shui","虚静无为":"xu_jing_wu_wei",
    "齐物论":"qi_wu_lun","逍遥游":"xiao_yao_you",
    "养生主":"yang_sheng_zhu","庖丁解牛":"pao_ding_jie_niu",
    "道家拂尘":"dao_jia_fu_chen","太极剑":"tai_ji_ji",
}

# === 遍历三套文件 ===
SRC_FILES = ["prompts_chibi_cute.json","prompts_euro_fantasy.json","prompts_fantasy_rpg.json"]
OUT_FILES = ["prompts_chibi_cute.json","prompts_euro_fantasy.json","prompts_fantasy_rpg.json"]

for src, out in zip(SRC_FILES, OUT_FILES):
    path = os.path.join(DIR, src)
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    # 合并 cards + heroes 到一个数组
    new_cards = []

    for cid, info in data.get("cards", {}).items():
        name = info["name"]
        card_type = get_card_type(cid)
        new_cards.append({
            "name": name,
            "en_name": PINYIN.get(name, cid.lower()),
            "card_type": card_type,
            "prompt": info["prompt"]
        })

    for hid, info in data.get("heroes", {}).items():
        name = info["name"]
        new_cards.append({
            "name": name,
            "en_name": PINYIN.get(name, hid.lower()),
            "card_type": "hero",
            "prompt": info["prompt"]
        })

    # 按 name 排序保持稳定
    new_cards.sort(key=lambda c: c["name"])

    out_path = os.path.join(DIR, out)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(new_cards, f, ensure_ascii=False, indent=2)

    print(f"✅ {src:35s} → {len(new_cards):3d} cards  ({out_path})")

print("\n三套提示词已完成数据结构升级")
