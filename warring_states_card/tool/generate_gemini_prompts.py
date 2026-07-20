#!/usr/bin/env python3
"""从 prompts_fantasy_rpg.json 生成 gemini-2.5-flash-image-preview 专用三套卡牌提示词"""

import json
import os

# === 手动拼音映射 ===
PINYIN = {
    # 兵家 minions
    "魏武卒": "wei_wu_zu", "秦锐士": "qin_rui_shi", "赵边骑": "zhao_bian_qi",
    "燕死士": "yan_si_shi", "楚锐卒": "chu_rui_zu", "齐技击士": "qi_ji_ji_shi",
    "韩戟兵": "han_ji_bing", "孙武": "sun_wu", "吴起": "wu_qi",
    "孙膑": "sun_bin", "廉颇": "lian_po", "李牧": "li_mu",
    # 兵家 spells
    "围魏救赵": "wei_wei_jiu_zhao", "破釜沉舟": "po_fu_chen_zhou",
    "背水一战": "bei_shui_yi_zhan", "暗度陈仓": "an_du_chen_cang",
    "声东击西": "sheng_dong_ji_xi", "十面埋伏": "shi_mian_mai_fu",
    "以逸待劳": "yi_yi_dai_lao", "擒贼擒王": "qin_zei_qin_wang",
    # 兵家 weapons
    "吴钩": "wu_gou", "越王剑": "yue_wang_jian", "丈八蛇矛": "zhang_ba_she_mao",
    # 法家 minions
    "执法吏": "zhi_fa_li", "刑徒": "xing_tu", "狱卒": "yu_zu",
    "律令官": "lv_ling_guan", "司寇": "si_kou", "大理": "da_li",
    "法家弟子": "fa_jia_di_zi", "商鞅": "shang_yang", "韩非": "han_fei",
    "李悝": "li_kui", "申不害": "shen_bu_hai", "吴起变法": "wu_qi_bian_fa",
    # 法家 spells
    "刑名之法": "xing_ming_zhi_fa", "峻法严刑": "jun_fa_yan_xing",
    "一断于法": "yi_duan_yu_fa", "以法治国": "yi_fa_zhi_guo",
    "连坐之法": "lian_zuo_zhi_fa", "奖励耕战": "jiang_li_geng_zhan",
    "废除井田": "fei_chu_jing_tian", "统一度量": "tong_yi_du_liang",
    # 法家 weapons
    "法家律尺": "fa_jia_lv_chi", "刑鼎": "xing_ding",
    # 墨家 minions
    "机关弩手": "ji_guan_nu_shou", "机关兽": "ji_guan_shou",
    "墨家弟子": "mo_jia_di_zi", "护城弩兵": "hu_cheng_nu_bing",
    "守城工兵": "shou_cheng_gong_bing", "攻城巨械": "gong_cheng_ju_xie",
    "工匠大师": "gong_jiang_da_shi", "墨子": "mo_zi",
    "公输班": "gong_shu_ban", "禽滑厘": "qin_hua_li",
    "田鸠": "tian_jiu", "腹䵍": "fu_tun",
    # 墨家 spells
    "兼爱非攻": "jian_ai_fei_gong", "墨守成规": "mo_shou_cheng_gui",
    "机关之术": "ji_guan_zhi_shu", "挡矢之术": "dang_shi_zhi_shu",
    "节用节葬": "jie_yong_jie_zang", "尚贤尚同": "shang_xian_shang_tong",
    "天志明鬼": "tian_zhi_ming_gui", "非乐非命": "fei_le_fei_ming",
    # 墨家 weapons
    "墨家机关弩": "mo_jia_ji_guan_nu", "公输尺": "gong_shu_chi",
    # 阴阳家 minions
    "巫祝": "wu_zhu", "占卜师": "zhan_bu_shi", "五行弟子": "wu_xing_di_zi",
    "祭司": "ji_si", "星象师": "xing_xiang_shi", "风水师": "feng_shui_shi",
    "方术士": "fang_shu_shi", "邹衍": "zou_yan", "甘德": "gan_de",
    "石申": "shi_shen", "南公": "nan_gong", "安期生": "an_qi_sheng",
    # 阴阳家 spells
    "五行相生": "wu_xing_xiang_sheng", "阴阳调和": "yin_yang_tiao_he",
    "天象异变": "tian_xiang_yi_bian", "占星问卜": "zhan_xing_wen_bu",
    "大九州说": "da_jiu_zhou_shuo", "五德终始": "wu_de_zhong_shi",
    "灾异谴告": "zai_yi_qian_gao", "符瑞祥兆": "fu_rui_xiang_zhao",
    # 阴阳家 weapons
    "阴阳五行杖": "yin_yang_wu_xing_zhang", "占星罗盘": "zhan_xing_luo_pan",
    # 纵横家 minions
    "辩士": "bian_shi", "说客": "shuo_ke", "刺客": "ci_ke",
    "使者": "shi_zhe", "谋士": "mou_shi", "外交官": "wai_jiao_guan",
    "策士": "ce_shi", "苏秦": "su_qin", "张仪": "zhang_yi",
    "范雎": "fan_ju", "蔺相如": "lin_xiang_ru", "鬼谷子": "gui_gu_zi",
    # 纵横家 spells
    "连横": "lian_heng", "合纵": "he_zong", "远交近攻": "yuan_jiao_jin_gong",
    "纵横捭阖": "zong_heng_bai_he", "完璧归赵": "wan_bi_gui_zhao",
    "离间计": "li_jian_ji", "空城计": "kong_cheng_ji", "调虎离山": "diao_hu_li_shan",
    # 纵横家 weapons
    "纵横家短剑": "zong_heng_jia_duan_jian", "合纵连横书": "he_zong_lian_heng_shu",
    # 中立 minions
    "民兵": "min_bing", "斥候": "chi_hou", "流浪者": "liu_lang_zhe",
    "侍卫": "shi_wei", "剑客": "jian_ke", "谋士": "mou_shi",
    "药师": "yao_shi", "甲士": "jia_shi", "弓手": "gong_shou",
    "骑兵": "qi_bing", "方士": "fang_shi", "医师": "yi_shi",
    "将领": "jiang_ling", "校尉": "xiao_wei", "武士": "wu_shi",
    "刺客": "ci_ke", "都尉": "du_wei", "猛将": "meng_jiang",
    "谋主": "mou_zhu", "猛犸": "meng_ma", "将军": "jiang_jun",
    "勇士": "yong_shi", "宗师": "zong_shi", "上将军": "shang_jiang_jun",
    "战神": "zhan_shen", "霸王": "ba_wang", "天帝": "tian_di",
    "神龙": "shen_long",
    # 中立 spells
    "调兵遣将": "diao_bing_qian_jiang", "四面楚歌": "si_mian_chu_ge",
    "知己知彼": "zhi_ji_zhi_bi", "坚壁清野": "jian_bi_qing_ye",
    "以少胜多": "yi_shao_sheng_duo", "奇袭": "qi_xi",
    "增援": "zeng_yuan", "决胜局": "jue_sheng_ju",
    "横扫千军": "heng_sao_qian_jun", "反戈一击": "fan_ge_yi_ji",
    # 中立 weapons
    "青铜剑": "qing_tong_jian", "长戟": "chang_ji", "秦王剑": "qin_wang_jian",
    # 儒家 minions
    "儒生": "ru_sheng", "礼官": "li_guan", "乐师": "yue_shi",
    "典狱官": "dian_yu_guan", "君子": "jun_zi", "贤人": "xian_ren",
    "夫子": "fu_zi", "孔子": "kong_zi", "孟子": "meng_zi",
    "荀子": "xun_zi", "子路": "zi_lu", "曾子": "ceng_zi",
    # 儒家 spells
    "仁政化民": "ren_zheng_hua_min", "礼乐同春": "li_yue_tong_chun",
    "教化众生": "jiao_hua_zhong_sheng", "仁义之师": "ren_yi_zhi_shi",
    "以德服人": "yi_de_fu_ren", "三省吾身": "san_xing_wu_shen",
    "有教无类": "you_jiao_wu_lei", "克己复礼": "ke_ji_fu_li",
    # 儒家 weapons
    "儒家玉圭": "ru_jia_yu_gui", "礼器编钟": "li_qi_bian_zhong",
    # 道家 minions
    "道童": "dao_tong", "守山人": "shou_shan_ren", "观星者": "guan_xing_zhe",
    "符师": "fu_shi", "真人": "zhen_ren", "隐士": "yin_shi",
    "方士": "fang_shi", "老子": "lao_zi", "庄子": "zhuang_zi",
    "列子": "lie_zi", "关尹子": "guan_yin_zi", "文子": "wen_zi",
    # 道家 spells
    "道法自然": "dao_fa_zi_ran", "无为而治": "wu_wei_er_zhi",
    "上善若水": "shang_shan_ruo_shui", "虚静无为": "xu_jing_wu_wei",
    "齐物论": "qi_wu_lun", "逍遥游": "xiao_yao_you",
    "养生主": "yang_sheng_zhu", "庖丁解牛": "pao_ding_jie_niu",
    # 道家 weapons
    "道家拂尘": "dao_jia_fu_chen", "太极剑": "tai_ji_jian",
}

# === gemini-2.5-flash-image-preview 优化提示词 ===
# gemini 处理中文好，不需要英译中垫词，短句自然语言效果好

def gemini_minion_prompt(name, faction, is_legendary=False):
    """随从提示词"""
    base = f"Ancient Chinese Warring States period illustration of {name}, a {faction} warrior, full character portrait in traditional ink-wash meets realistic fantasy style, earthy bronze and jade color palette, dramatic atmosphere"
    if is_legendary:
        base += ", mythical aura, divine radiance, epic composition befitting a legendary figure"
    return base

def gemini_spell_prompt(name, faction):
    """法术提示词"""
    return f"Ancient Chinese Warring States period magic spell visualization of '{name}', {faction} philosophical energy, dynamic swirling ink and calligraphy effects, ethereal mist and ancient talismans, dramatic contrast between darkness and golden light, traditional Chinese aesthetic"

def gemini_weapon_prompt(name, faction):
    """武器提示词"""
    return f"Ancient Chinese Warring States period weapon showcase of {name}, a {faction} artifact, detailed close-up against aged parchment or silk background, intricate bronze and jade craftsmanship, dramatic lighting highlighting texture and patina, museum-quality archaeological aesthetic"

# === faction 映射 ===
FACTION = {
    "B": "bingjia military", "F": "fajia legalist", "M": "mojia mohist",
    "Y": "yinyangjia", "Z": "zonghengjia strategist",
    "N": "neutral commoner", "R": "rujia confucian", "D": "daojia daoist",
    "BW": "bingjia", "FW": "fajia", "MW": "mojia",
    "YW": "yinyangjia", "ZW": "zonghengjia", "NW": "neutral",
    "RW": "rujia", "DW": "daojia",
}

def get_faction(card_id, is_weapon=False):
    prefix = card_id[0]
    if is_weapon:
        prefix2 = card_id[:2]
        return FACTION.get(prefix2, "ancient Chinese")
    if prefix == "N":
        return "neutral commoner"
    return FACTION.get(prefix, "ancient Chinese")

def is_legendary(name):
    legends = {"孙武","吴起","孙膑","廉颇","李牧","商鞅","韩非","墨子","公输班",
               "邹衍","甘德","石申","苏秦","张仪","鬼谷子","孔子","孟子","荀子",
               "老子","庄子","列子","战神","霸王","天帝","神龙"}
    return name in legends

# === 主流程 ===
with open(os.path.join(os.path.dirname(__file__), "prompts_fantasy_rpg.json"), encoding="utf-8") as f:
    data = json.load(f)

cards = data.get("cards", {})
# 初始化三套
sets = {"minions": [], "spells": [], "weapons": []}

for cid, info in cards.items():
    name = info["name"]
    ctype = info["type"]
    faction = get_faction(cid, is_weapon=(ctype == "weapon"))
    en_name = PINYIN.get(name, cid.lower())
    
    if ctype == "minion":
        leg = is_legendary(name)
        prompt = gemini_minion_prompt(name, faction, leg)
    elif ctype == "spell":
        prompt = gemini_spell_prompt(name, faction)
    elif ctype == "weapon":
        prompt = gemini_weapon_prompt(name, faction)
    else:
        continue
    
    sets[ctype + "s"].append({
        "name": name,
        "en_name": en_name,
        "card_type": ctype,
        "prompt": prompt
    })

# === 写出三套文件 ===
assets_dir = os.path.join(os.path.dirname(__file__), "..", "..", "assets")
os.makedirs(assets_dir, exist_ok=True)

for key, filename in [("minions", "card_prompts_minions.json"),
                      ("spells", "card_prompts_spells.json"),
                      ("weapons", "card_prompts_weapons.json")]:
    path = os.path.join(assets_dir, filename)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(sets[key], f, ensure_ascii=False, indent=2)
    print(f"✅ {path}  ({len(sets[key])} cards)")

# === 汇总 ===
total = sum(len(v) for v in sets.values())
print(f"\n总计: {total} 张卡牌提示词已生成")
