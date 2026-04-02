# performanceAnalyzer.py
import re
import json
import os
from datetime import datetime

try:
    from fileHelper import (
        sanitize_filename_part
    )
except ImportError as e:
    print(f"❌ 导入 fileHelper 失败：{e}")
    sys.exit(1)
    
try:
    from spinner import start as spinner_start, stop as spinner_stop
    _HAS_SPINNER = True
except ImportError:
    _HAS_SPINNER = False
    def _dummy(): pass
    spinner_start = spinner_stop = _dummy

# ========================
# 配置区 —— 所有性能分析类型与子类型
# ========================
PERF_CONFIG = {
    '1': {'name': 'All',       'enabled': True,  'subs': {}},
    '2': {'name': 'Timer',     'enabled': True,  'subs': {
        '1': {'name': 'All',      'enabled': True},
        '2': {'name': 'Ground',   'enabled': True},
        '3': {'name': 'Suspend',  'enabled': True},
        '4': {'name': 'Resume',   'enabled': True},
    }},
    '3': {'name': 'Device',    'enabled': True,  'subs': {
        '1': {'name': 'All',             'enabled': True},
        '2': {'name': 'BatteryState',    'enabled': True},
        '3': {'name': 'BatteryLevel',    'enabled': True},
        '4': {'name': 'BatteryHealth',   'enabled': True},
    }},
    '4': {'name': 'Process',   'enabled': True,  'subs': {
        '1': {'name': 'All',             'enabled': True},
        '2': {'name': 'ThermalState',    'enabled': True},
        '3': {'name': 'LowPowerMode',    'enabled': True},
    }},
    '5': {'name': 'App',       'enabled': True,  'subs': {
        '1': {'name': 'All',                               'enabled': True},
        '2': {'name': 'DidEnterBackground',                'enabled': True},
        '3': {'name': 'WillEnterForeground',               'enabled': True},
        '4': {'name': 'DidFinishLaunching',                'enabled': True},
        '5': {'name': 'DidBecomeActive',                   'enabled': True},
        '6': {'name': 'WillResignActive',                  'enabled': True},
        '7': {'name': 'WillTerminate',                     'enabled': True},
        '8': {'name': 'DidReceiveMemoryWarning',          'enabled': True},
        '9': {'name': 'BackgroundRefreshStatusDidChange',  'enabled': True},
        '10':{'name': 'SignificantTimeChange',             'enabled': True},
        '11':{'name': 'ProtectedDataWillBecomeUnavailable','enabled': True},
        '12':{'name': 'ProtectedDataDidBecomeAvailable',   'enabled': True},
        '13':{'name': 'UserDidTakeScreenshot',             'enabled': True},
    }},
    '6': {'name': 'Scene',     'enabled': True,  'subs': {
        '1': {'name': 'All',             'enabled': True},
        '2': {'name': 'WillConnect',     'enabled': True},
        '3': {'name': 'DidDisconnect',   'enabled': True},
        '4': {'name': 'DidActivate',     'enabled': True},
        '5': {'name': 'WillDeactivate',  'enabled': True},
        '6': {'name': 'WillEnterForeground', 'enabled': True},
        '7': {'name': 'DidEnterBackground',  'enabled': True},
    }},
    '7': {'name': 'CPU',       'enabled': False, 'subs': {
        '1': {'name': 'All',      'enabled': False},
        '2': {'name': 'Thread',   'enabled': False},
        '3': {'name': 'Process',  'enabled': False},
        '4': {'name': 'System',   'enabled': False},
    }},
    '8': {'name': 'Memory',    'enabled': False, 'subs': {
        '1': {'name': 'All',      'enabled': False},
        '2': {'name': 'Pressure', 'enabled': False},
        '3': {'name': 'Mach',     'enabled': False},
        '4': {'name': 'Usage',    'enabled': False},
        '5': {'name': 'Size',     'enabled': False},
    }},
}

def safe_input(prompt):
    try:
        return input(prompt).strip()
    except (KeyboardInterrupt, EOFError):
        print("\n👋 操作已取消。")
        exit(0)

def _extract_entries_by_pattern(lines, type_name, subtype_name):
    """
    支持两种日志格式：
    1. 新格式: #A/B(KA): Timer Ground ...
    2. 旧格式: [Timer] Ground ...
    返回匹配的行列表。
    """
    # 尝试新格式
    new_pattern = re.compile(rf'#A/B\(KA\):\s+{re.escape(type_name)}\s+{re.escape(subtype_name)}')
    matched_lines_new = [line for line in lines if new_pattern.search(line)]
    
    if matched_lines_new:
        return matched_lines_new

    # 回退到旧格式
    old_patterns = {
        'Timer': r'\[Timer\]\s+' + re.escape(subtype_name),
        'App':   r'\[App\]\s+'   + re.escape(subtype_name),
        'Device': r'\[Device\]\s+' + re.escape(subtype_name),
        'Process': r'\[Process\]\s+' + re.escape(subtype_name),
        'Scene': r'\[Scene\]\s+' + re.escape(subtype_name),
    }
    pattern_str = old_patterns.get(type_name)
    if not pattern_str:
        return []
    old_pattern = re.compile(pattern_str)
    return [line for line in lines if old_pattern.search(line)]

def _parse_timestamp_from_line(line):
    """从行首提取时间戳，支持带或不带毫秒"""
    ts_match = re.match(r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)', line)
    if not ts_match:
        return None, ""
    ts_str = ts_match.group(1)
    try:
        if '.' in ts_str:
            dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S.%f")
        else:
            dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
        return dt, dt.timestamp()
    except ValueError:
        return None, 0.0

def _process_single_subtype(lines, log_path, type_name, subtype_name):
    matched_lines = _extract_entries_by_pattern(lines, type_name, subtype_name)
    if not matched_lines:
        return []

    json_entries = []
    output_lines = []

    for line in matched_lines:
        dt, ts = _parse_timestamp_from_line(line)
        time_str = dt.strftime("%Y/%m/%d %H:%M:%S") + f".{dt.microsecond // 1000:03d}" if dt else ""

        # 提取内容部分（去掉时间戳和标签）
        content = line
        # 移除开头的时间戳
        content = re.sub(r'^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?\s*', '', content)
        # 移除新/旧标签
        content = re.sub(r'^\[.*?\]\s*', '', content)
        content = re.sub(r'^#A/B\(KA\):\s+\S+\s+\S+\s*', '', content)
        content = content.strip()

        entry = {
            "timestamp": round(ts, 3) if ts else 0.0,
            "timeStr": time_str,
            "type": type_name,
            "subtype": subtype_name,
            "content": content
        }
        json_entries.append(entry)
        output_lines.append(line)

    if not json_entries:
        return []

    base_name = os.path.splitext(os.path.basename(log_path))[0]
    sanitized_type = sanitize_filename_part(type_name)
    sanitized_subtype = sanitize_filename_part(subtype_name)
    output_base = f"{base_name}[Perf_{sanitized_type}_{sanitized_subtype}]"
    dir_name = os.path.dirname(log_path)

    log_out_path = os.path.join(dir_name, output_base + ".log")
    json_out_path = os.path.join(dir_name, output_base + ".json")

    with open(log_out_path, 'w', encoding='utf-8') as f:
        f.writelines(line if line.endswith('\n') else line + '\n' for line in output_lines)

    with open(json_out_path, 'w', encoding='utf-8') as f:
        json.dump(json_entries, f, indent=2, ensure_ascii=False)

    return [(log_out_path, json_out_path)]

def do_perf_analysis(lines, log_path):
    while True:
        print("\n" + "-" * 119 + "\n")
        print("当前位置：主菜单 > 性能分析")
        print("\n【性能分析】请选择类别：")
        print("0. 返回上一级")
        for key in ['1', '2', '3', '4', '5', '6', '7', '8']:
            cat = PERF_CONFIG[key]
            mark = " ✔" if cat['enabled'] else ""
            print(f"{key}. {cat['name']}{mark}")

        choice = safe_input("请输入选项（0-8）：")

        if choice == '0':
            return

        if choice not in PERF_CONFIG:
            print("⚠️ 无效选项，请重新选择。")
            continue

        cat = PERF_CONFIG[choice]
        if not cat['enabled']:
            print(f"🚧 功能 '{cat['name']}' 正在开发中，敬请期待！")
            continue

        type_name = cat['name']
        sub_dict = cat['subs']

        # 特殊处理 "All" 类型（即 choice == '1'）
        if choice == '1':
            all_files = []
            print("\n🔄 正在批量分析所有启用的类别...")
            for key2 in ['2', '3', '4', '5', '6']:  # 跳过 CPU/Memory（disabled）
                sub_cat = PERF_CONFIG[key2]
                if not sub_cat['enabled']:
                    continue
                tname = sub_cat['name']
                subs = [info['name'] for info in sub_cat['subs'].values() if info['name'] != 'All' and info['enabled']]
                for sname in subs:
                    files = _process_single_subtype(lines, log_path, tname, sname)
                    all_files.extend(files)
            if all_files:
                print(f"\n✅ 共生成 {len(all_files)} 组文件：")
                for log_p, json_p in all_files:
                    print(f"   📄 {os.path.basename(log_p)}")
                    print(f"   📦 {os.path.basename(json_p)}")
            else:
                print("\n⚠️ 未找到任何匹配的日志记录。")
            continue

        # 子类型选择
        while True:
            print("\n" + "-" * 119 + "\n")
            print(f"当前位置：主菜单 > 性能分析 > {type_name}")
            print(f"\n【{type_name}】")
            print("0. 返回上一级")
            sorted_sub_keys = sorted(sub_dict.keys(), key=int)
            for idx, sub_key in enumerate(sorted_sub_keys, 1):
                sub_info = sub_dict[sub_key]
                mark = " ✔" if sub_info['enabled'] else ""
                print(f"{idx}. {sub_info['name']}{mark}")

            sub_input = safe_input(f"请输入子选项（0-{len(sorted_sub_keys)}）：")
            if sub_input == '0':
                break

            try:
                sub_choice_idx = int(sub_input)
                if not (1 <= sub_choice_idx <= len(sorted_sub_keys)):
                    raise ValueError
                selected_sub_key = sorted_sub_keys[sub_choice_idx - 1]
                selected_sub = sub_dict[selected_sub_key]

                if not selected_sub['enabled']:
                    print(f"🚧 子功能 '{selected_sub['name']}' 正在开发中！")
                    continue

                subtype_name = selected_sub['name']

                if subtype_name == "All":
                    actual_subtypes = [
                        info['name'] for info in sub_dict.values()
                        if info['name'] != "All" and info['enabled']
                    ]
                    if not actual_subtypes:
                        print("⚠️ 该类别下无有效的子项可执行。")
                        continue
                    print(f"\n🔄 正在批量分析 {len(actual_subtypes)} 个子项...")
                    generated_files = []
                    for sn in actual_subtypes:
                        files = _process_single_subtype(lines, log_path, type_name, sn)
                        generated_files.extend(files)
                else:
                    print(f"\n🔄 正在分析 [{type_name} → {subtype_name}]...")
                    generated_files = _process_single_subtype(lines, log_path, type_name, subtype_name)

                if generated_files:
                    print(f"\n✅ 共生成 {len(generated_files)} 组文件：")
                    for log_p, json_p in generated_files:
                        print(f"   📄 {os.path.basename(log_p)}")
                        print(f"   📦 {os.path.basename(json_p)}")
                else:
                    msg = f"未在日志中找到 '{subtype_name}' 相关记录。" if subtype_name != "All" else \
                          f"批量分析完成，但未找到以下 {len(actual_subtypes)} 个子项的任何记录。"
                    print(f"\n⚠️ {msg}")

            except (ValueError, IndexError):
                print("⚠️ 无效子选项，请重新输入。")
