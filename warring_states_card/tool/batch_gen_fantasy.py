#!/usr/bin/env python3
"""批量生成 fantasy_rpg 风格 217张（196卡+21英雄）"""
import json, time, shutil, sys
from pathlib import Path
import httpx
from gradio_client import Client

API = "http://117.50.188.37:7860"
ROOT = Path(__file__).parent.parent / "assets"
NEGATIVE = "photorealistic, photo, realistic face, real human face, real person, modern elements, text, words, watermark, signature, label, lettering, modern weapons, guns, sci-fi"

ALL_PINYIN = {
  'B001':'weiwuzu','B002':'qinruishi','B003':'zhaobianqi','B004':'yansishi','B005':'churuizu',
  'B006':'qijijishi','B007':'hanjibing','B008':'sunwu','B009':'wuqi','B010':'sunbin',
  'B011':'lianpo','B012':'limu','D001':'daotong','D002':'shoushanren','D003':'guanxingzhe',
  'D004':'fushi','D005':'zhenren','D006':'yinshi','D007':'fangshi','D008':'laozi',
  'D009':'zhuangzi','D010':'liezi','D011':'guanyinzi','D012':'wenzi',
  'F001':'zhifali','F002':'xingtu','F003':'yuzu','F004':'lvlingguan','F005':'sikou',
  'F006':'dali','F007':'fajiadizi','F008':'shangyang','F009':'hanfei','F010':'likui',
  'F011':'shenbuhai','F012':'wuqibianfa',
  'M001':'jiguannushou','M002':'jiguanshou','M003':'mojiadizi','M004':'huchengnubing',
  'M005':'shouchenggongbing','M006':'gongchengjuxie','M007':'gongjiangdashi','M008':'mozi',
  'M009':'gongshuban','M010':'qinhuali','M011':'tianjiu','M012':'fu䵍',
  'N001':'minbing','N002':'chihou','N003':'liulangzhe','N004':'shiwei','N005':'jianke',
  'N006':'moushi','N007':'yaoshi','N008':'jiashi','N009':'gongshou','N010':'qibing',
  'N011':'fangshi','N012':'yishi','N013':'jiangling','N014':'xiaowei','N015':'wushi',
  'N016':'cike','N017':'duwei','N018':'mengjiang','N019':'mouzhu','N020':'mengma',
  'N021':'jiangjun','N022':'yongshi','N023':'zongshi','N024':'shangjiangjun',
  'N025':'zhanshen','N026':'bawang','N027':'tiandi','N028':'shenlong',
  'R001':'rusheng','R002':'liguan','R003':'yueshi','R004':'dianyuguan','R005':'junzi',
  'R006':'xianren','R007':'fuzi','R008':'kongzi','R009':'mengzi','R010':'xunzi',
  'R011':'zilu','R012':'cengzi',
  'Y001':'wuzhu','Y002':'zhanbushi','Y003':'wuxingdizi','Y004':'jisi','Y005':'xingxiangshi',
  'Y006':'fengshuishi','Y007':'fangshushi','Y008':'zouyan','Y009':'gande','Y010':'shishen',
  'Y011':'nangong','Y012':'anqisheng',
  'Z001':'bianshi','Z002':'shuoke','Z003':'cike','Z004':'shizhe','Z005':'moushi',
  'Z006':'waijiaoguan','Z007':'ceshi','Z008':'suqin','Z009':'zhangyi','Z010':'fanju',
  'Z011':'linxiangru','Z012':'guiguzi',
}
SPELL_PINYIN = {
  'B013':'weiweijiuzhao','B014':'pofuchenzhou','B015':'beishuiyizhan','B016':'anduchencang',
  'B017':'shengdongjixi','B018':'shimianmaifu','B019':'yiyidailao','B020':'qinzeiqinwang',
  'D013':'daofaziran','D014':'wuweierzhi','D015':'shangshanruoshui','D016':'xujingwuwei',
  'D017':'qiwulun','D018':'xiaoyaoyou','D019':'yangshengzhu','D020':'paodingjieniu',
  'F013':'xingmingzhifa','F014':'junfayanxing','F015':'yiduanyufa','F016':'yifazhiguo',
  'F017':'lianzuozhifa','F018':'jiangligengzhan','F019':'feichujingtian','F020':'tongyiduliang',
  'M013':'jianaifeigong','M014':'moshouchenggui','M015':'jiguanzhishu','M016':'dangshizhishu',
  'M017':'jieyongjiezang','M018':'shangxianshangtong','M019':'tianzhiminggui','M020':'feilefeiming',
  'N029':'diaobingqianjiang','N030':'simianchuge','N031':'zhijizhibi','N032':'jianbiqingye',
  'N033':'yishaoshengduo','N034':'qixi','N035':'zengyuan','N036':'jueshengju',
  'N037':'hengsaoqianjun','N038':'fangeyiji',
  'R013':'renzhenghuamin','R014':'liyuetongchun','R015':'jiaohuazhongsheng','R016':'renyizhishi',
  'R017':'yidefuren','R018':'sanxingwushen','R019':'youjiaowulei','R020':'kejifuli',
  'Y013':'wuxingxiangsheng','Y014':'yinyangtiaohe','Y015':'tianxiangyibian','Y016':'zhanxingwenbu',
  'Y017':'dajiuzhoushuo','Y018':'wudezhongshi','Y019':'zaiyiqiangao','Y020':'furuixiangzhao',
  'Z013':'lianheng','Z014':'hezong','Z015':'yuanjiaojingong','Z016':'zonghengbaihe',
  'Z017':'wanbiguizhao','Z018':'lijianji','Z019':'kongchengji','Z020':'diaohulishan',
}
WEAPON_PINYIN = {
  'BW001':'wugou','BW002':'yuewangjian','BW003':'zhangbashemao',
  'DW001':'daojiafuchen','DW002':'taijijian',
  'FW001':'fajialvchi','FW002':'xingding',
  'MW001':'mojiajiguannu','MW002':'gongshuchi',
  'NW001':'qingtongjian','NW002':'zhangji','NW003':'qinwangjian',
  'RW001':'rujiayugui','RW002':'liqibianzhong',
  'YW001':'yinyangwuxingzhang','YW002':'zhanxingluopan',
  'ZW001':'zonghengjiaduanjian','ZW002':'hezonglianhengshu',
}
HERO_PINYIN = {
  'H_B001':'sunbin','H_B002':'wuqi','H_B003':'lianpo',
  'H_D001':'laozi','H_D002':'zhuangzi','H_D003':'liezi',
  'H_F001':'shangyang','H_F002':'hanfei','H_F003':'shenbuhai',
  'H_M001':'mozi','H_M002':'gongshuban','H_M003':'qinhuali',
  'H_R001':'kongzi','H_R002':'mengzi','H_R003':'xunzi',
  'H_Y001':'zouyan','H_Y002':'gande','H_Y003':'shishen',
  'H_Z001':'suqin','H_Z002':'zhangyi','H_Z003':'guiguzi',
}

def pinyin_path(cid, ctype):
    if ctype == 'hero':  m, sub = HERO_PINYIN, 'heroes'
    elif ctype == 'spell': m, sub = SPELL_PINYIN, 'spells'
    elif ctype == 'weapon': m, sub = WEAPON_PINYIN, 'weapons'
    else: m, sub = ALL_PINYIN, 'minions'
    return sub, f"{m.get(cid,'unknown')}.png"

def build_queue(prompt_data, inventory):
    """构建有序任务列表：用 inventory.json 确定类型"""
    # inventory: {"cards": {id: {name,type,...}}, "heroes": {id: {name,...}}}
    type_map = {}
    for cid, cinfo in inventory.get("cards", {}).items():
        type_map[cid] = cinfo.get("type", "minion").lower()

    tasks = []
    for ct in ["minion", "spell", "weapon"]:
        for cid in sorted(type_map, key=lambda x: type_map.get(x, '') == ct):
            if type_map[cid] != ct: continue
            entry = prompt_data.get("cards", {}).get(cid)
            if not entry: continue
            sub, fname = pinyin_path(cid, ct)
            tasks.append((ct, cid, entry["prompt"], sub, fname))

    for hid, entry in prompt_data.get("heroes", {}).items():
        sub, fname = pinyin_path(hid, "hero")
        tasks.append(("hero", hid, entry["prompt"], sub, fname))
    return tasks

def main():
    OUT = ROOT / "fantasy_rpg"
    prompt_data = json.loads((ROOT / "prompts_fantasy_rpg.json").read_text())
    inventory = json.loads((Path(__file__).parent / "inventory.json").read_text())
    tasks = build_queue(prompt_data, inventory)

    print(f"任务数: {len(tasks)}")
    existing = 0
    for _, _, _, sub, fname in tasks:
        if (OUT / sub / fname).exists():
            existing += 1
    if existing:
        print(f"已存在: {existing}，跳过现有文件继续")

    client = Client(API, httpx_kwargs={"timeout": httpx.Timeout(600, connect=30)})
    try:
        # 1. 提交所有
        print(f"提交 {len(tasks)} 个任务到队列...", flush=True)
        t_submit = time.time()
        for ct, cid, prompt, sub, fname in tasks:
            out_path = OUT / sub / fname
            if out_path.exists():
                continue  # 跳过已有
            while True:
                try:
                    client.predict(
                        prompt, 9, NEGATIVE, 752, 1328,
                        None, "开启",
                        "None", 1, "None", 1, "None", 1, "None", 1,
                        False, False, 0.45, False,
                        api_name="/add_task_to_queue"
                    )
                    break
                except Exception as e:
                    print(f"  提交失败，重试: {e}")
                    time.sleep(3)
        print(f"提交完成 ({time.time()-t_submit:.0f}s), 等待生成...", flush=True)

        # 2. 轮询下载
        total = len(tasks)
        done_total = existing
        deadline = time.time() + 7200
        last_gallery_len = 0
        poll_count = 0

        while done_total < total and time.time() < deadline:
            time.sleep(5)
            try:
                r = client.predict(api_name="/refresh_ui_and_process_queue")
            except Exception as e:
                print(f"  poll 失败: {e}", flush=True)
                continue
            gallery = r[1] if isinstance(r[1], list) else []
            poll_count += 1

            while last_gallery_len < len(gallery) and last_gallery_len < len(tasks):
                ct, cid, _, sub, fname = tasks[last_gallery_len]
                out_path = OUT / sub / fname

                if out_path.exists():
                    last_gallery_len += 1
                    continue

                img = gallery[last_gallery_len]
                if isinstance(img, dict) and img.get('image'):
                    src = Path(str(img['image']))
                    if src.exists() and src.stat().st_size > 1000:
                        out_path.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(str(src), str(out_path))
                        done_total += 1
                        eta = (time.time() - t_submit) / done_total * (total - done_total)
                        print(f"  [{done_total}/{total}] {cid} {sub}/{fname} ({src.stat().st_size/1024:.0f}KB, ETA {eta/60:.0f}m)", flush=True)
                    else:
                        print(f"  [{last_gallery_len}] {cid} → 文件过小 {src.stat().st_size}b", flush=True)
                last_gallery_len += 1

            if poll_count % 12 == 0:
                eta = (time.time() - t_submit) / max(done_total - existing, 1) * (total - done_total) if done_total > existing else 0
                print(f"  进度: {done_total}/{total} (ETA {eta/60:.0f}m)", flush=True)

        print(f"\n完成: {done_total}/{total} ({time.time()-t_submit:.0f}s)", flush=True)

    finally:
        try: client.close()
        except: pass

if __name__ == "__main__":
    main()
