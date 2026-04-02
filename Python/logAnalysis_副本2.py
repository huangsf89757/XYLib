import os
import re
import json
import sys
import threading
import time
from datetime import datetime, timedelta
from itertools import cycle
import unicodedata

# === 跨平台清空 stdin 缓冲区 ===
def flush_input():
    """清空标准输入缓冲区，防止用户在操作期间误按的键干扰后续 input()"""
    try:
        if os.name == 'nt':  # Windows
            import msvcrt
            while msvcrt.kbhit():
                msvcrt.getch()
        else:  # Unix-like: macOS, Linux
            import termios
            termios.tcflush(sys.stdin, termios.TCIFLUSH)
    except Exception:
        pass  # 忽略异常（如重定向 stdin）

def safe_input(prompt):
    """安全输入：先清空缓冲区，再读取用户输入"""
    flush_input()
    try:
        return input(prompt).strip()
    except (EOFError, KeyboardInterrupt):
        print("\n👋 收到中断信号，正在退出...")
        sys.exit(0)

# === 计算终端显示宽度（关键修复）===
def get_display_width(text):
    """计算字符串在终端中的实际显示宽度（中文/Emoji = 2，ASCII = 1）"""
    width = 0
    for char in text:
        # East Asian Width 属性：F/W = 全宽（2列），其余 = 半宽（1列）
        if unicodedata.east_asian_width(char) in ('F', 'W'):
            width += 2
        else:
            width += 1
    return width

# === Spinner 动画工具（已修复宽度问题）===
class Spinner:
    def __init__(self, message="处理中"):
        self.message = message
        self.running = False
        self.thread = None
        self.spinner_cycle = cycle("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏")

    def _spin(self):
        while self.running:
            line = f"{self.message} {next(self.spinner_cycle)}"
            sys.stdout.write(f"\r{line}")
            sys.stdout.flush()
            time.sleep(0.1)
        
        # 停止后：按实际显示宽度清除整行
        clear_line = f"{self.message}  "  # 多加空格保险
        clear_width = get_display_width(clear_line)
        sys.stdout.write("\r" + " " * clear_width + "\r")
        sys.stdout.flush()

    def start(self):
        if not self.running:
            self.running = True
            self.thread = threading.Thread(target=self._spin, daemon=True)
            self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join()

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()
        if exc_type:
            print(f"\n❌ 操作过程中发生错误: {exc_val}")
        return False

def spinner(message="处理中"):
    return Spinner(message)

# === 日志解析相关函数 ===
LOG_TIME_PATTERN = re.compile(
    r'\[(\w)\]\[(\d{4}-\d{2}-\d{2}) ([+-]\d+\.?\d*) (\d{2}:\d{2}:\d{2}\.\d{3})\]'
)

def parse_log_time_and_tz(line):
    match = LOG_TIME_PATTERN.search(line)
    if not match:
        return None, None
    _, date_str, tz_str, time_str = match.groups()
    dt_str = f"{date_str} {time_str}"
    try:
        dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S.%f")
        return dt, tz_str
    except ValueError:
        return None, None

def format_tz_to_hhmm(tz_str):
    try:
        offset_hours = float(tz_str)
        total_minutes = int(round(abs(offset_hours) * 60))
        hours = total_minutes // 60
        minutes = total_minutes % 60
        sign = '-' if offset_hours < 0 else '+'
        return f"{sign}{hours:02d}{minutes:02d}"
    except (ValueError, TypeError):
        return "+0000"

def datetime_to_timestamp(dt):
    return dt.timestamp()

def format_timedelta_for_prefix(td):
    total_seconds = td.total_seconds()
    sign = '-' if total_seconds < 0 else ''
    total_seconds = abs(total_seconds)
    days = int(total_seconds // 86400)
    hours = int((total_seconds % 86400) // 3600)
    minutes = int((total_seconds % 3600) // 60)
    seconds = int(total_seconds % 60)
    milliseconds = int(round((total_seconds - int(total_seconds)) * 1000))
    if milliseconds >= 1000:
        seconds += 1
        milliseconds -= 1000
    return f"[{sign}{days:02d} {hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}]"

def format_timedelta_for_summary(td):
    total_seconds = abs(td.total_seconds())
    days = int(total_seconds // 86400)
    hours = int((total_seconds % 86400) // 3600)
    minutes = int((total_seconds % 3600) // 60)
    seconds = int(total_seconds % 60)
    milliseconds = int(round((total_seconds - int(total_seconds)) * 1000))
    if milliseconds >= 1000:
        seconds += 1
        milliseconds -= 1000
    return f"{days:02d} {hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}"

def sanitize_filename_part(tag):
    if not tag:
        return "empty"
    sanitized = re.sub(r'[\\/:\*\?"<>\|\x00-\x1f\x7f-\x9f]', '_', tag)
    sanitized = re.sub(r'_+', '_', sanitized)
    sanitized = sanitized.strip('_')
    return sanitized if sanitized else "empty"

# === 性能分析配置 ===
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

def _process_single_subtype(lines, input_path, type_name, subtype_name):
    pattern_str = r'#A/B\(KA\):\s+' + re.escape(type_name) + r'\s+' + re.escape(subtype_name)
    compiled_pattern = re.compile(pattern_str)

    matched_lines = []
    for line in lines:
        if compiled_pattern.search(line):
            matched_lines.append(line)

    count = len(matched_lines)
    if count == 0:
        return []

    json_entries = []
    log_output_lines = []
    for line in matched_lines:
        dt, tz_str = parse_log_time_and_tz(line)
        if dt and tz_str:
            ts = round(datetime_to_timestamp(dt), 3)
            formatted_tz = format_tz_to_hhmm(tz_str)
            time_str = dt.strftime("%Y/%m/%d %H:%M:%S") + f".{dt.microsecond // 1000:03d} {formatted_tz}"
        else:
            ts = 0.0
            time_str = ""

        start_marker = "#A/B(KA): "
        if start_marker in line:
            full_content = line.split(start_marker, 1)[1].strip()
        else:
            full_content = line.strip()

        entry = {
            "timestamp": ts,
            "timeStr": time_str,
            "type": type_name,
            "subtype": subtype_name,
            "value": "",
            "content": full_content
        }
        json_entries.append(entry)
        log_output_lines.append(line)

    sanitized_type = sanitize_filename_part(type_name)
    sanitized_subtype = sanitize_filename_part(subtype_name)
    base_name = os.path.basename(input_path)
    name_without_ext, ext = os.path.splitext(base_name)
    output_base = f"{name_without_ext}[Perf_{sanitized_type}_{sanitized_subtype}]"

    dir_name = os.path.dirname(input_path)

    log_path = os.path.join(dir_name, output_base + ext)
    with open(log_path, 'w', encoding='utf-8') as f:
        f.writelines(log_output_lines)

    json_path = os.path.join(dir_name, output_base + ".json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(json_entries, f, indent=2, ensure_ascii=False)

    return [(log_path, json_path)]


def do_perf_analysis(lines, input_path):
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
            print("⚠️  无效选项，请重新选择。")
            continue

        cat = PERF_CONFIG[choice]
        if not cat['enabled']:
            print(f"🚧 功能 '{cat['name']}' 正在开发中，敬请期待！")
            continue

        type_name = cat['name']
        sub_dict = cat['subs']

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

                actual_subtypes = []
                if subtype_name == "All":
                    actual_subtypes = [
                        info['name'] for info in sub_dict.values()
                        if info['name'] != "All" and info['enabled']
                    ]
                    if not actual_subtypes:
                        print("⚠️  该类别下无有效的子项可执行。")
                        continue
                    base_msg = f"🔄 正在批量分析 {len(actual_subtypes)} 个子项"
                else:
                    actual_subtypes = [subtype_name]
                    base_msg = f"🔄 正在分析 [{type_name} → {subtype_name}]"

                # ✅ 关键：换行 + 使用带 ... 的完整消息
                print()
                with spinner(base_msg + "..."):
                    generated_files = []
                    for sub_name in actual_subtypes:
                        files = _process_single_subtype(lines, input_path, type_name, sub_name)
                        generated_files.extend(files)

                if generated_files:
                    print(f"\n✅ 共生成 {len(generated_files)} 组文件：")
                    for log_p, json_p in generated_files:
                        print(f"   📄 {os.path.basename(log_p)}")
                        print(f"   📦 {os.path.basename(json_p)}")
                else:
                    if subtype_name == "All":
                        print(f"\n⚠️  批量分析完成，但在日志中未找到以下 {len(actual_subtypes)} 个子项的任何记录：")
                        for sn in actual_subtypes:
                            print(f"   • {sn}")
                    else:
                        print(f"\n⚠️  未在日志中找到 '{subtype_name}' 相关记录，不生成文件。")

            except (ValueError, IndexError):
                print("⚠️  无效子选项，请重新输入。")
                continue


def do_time_analysis(lines, input_path):
    print("⏳ 准备时间分析...")

    while True:
        try:
            user_input = safe_input("请输入最小时间间隔（秒，支持小数，默认60）：")
            if user_input == "":
                min_interval_sec = 60.0
            else:
                min_interval_sec = float(user_input)
                if min_interval_sec < 0:
                    print("⚠️  间隔不能为负数，请重新输入。")
                    continue
            break
        except ValueError:
            print("⚠️  请输入有效的数字（如 30、15.5、0.1 等）。")

    msg = f"⏱️ 正在分析时间间隔（阈值: {min_interval_sec}s）"
    print()
    with spinner(msg + "..."):
        parsed_times = []
        for line in lines:
            dt, _ = parse_log_time_and_tz(line)
            parsed_times.append(dt)
        
        output_lines = []
        large_intervals = []
        prev_dt = None
        prev_line = None

        for i, line in enumerate(lines):
            current_dt = parsed_times[i]
            if current_dt is None:
                output_lines.append(line)
                continue
            if prev_dt is None:
                delta_str = "[00 00:00:00.000]"
            else:
                delta_td = current_dt - prev_dt
                delta_seconds = delta_td.total_seconds()
                delta_str = format_timedelta_for_prefix(delta_td)
                if delta_seconds >= min_interval_sec:
                    large_intervals.append((prev_line, line, delta_td))
            output_lines.append(f"{delta_str} {line}")
            prev_dt = current_dt
            prev_line = line

        max_delta = timedelta(0)
        for i in range(1, len(parsed_times)):
            if parsed_times[i] and parsed_times[i - 1]:
                delta = parsed_times[i] - parsed_times[i - 1]
                if delta > max_delta:
                    max_delta = delta
        max_interval_str = format_timedelta_for_summary(max_delta)

        first_ts = last_ts = None
        for i, line in enumerate(lines):
            if parsed_times[i]:
                m = LOG_TIME_PATTERN.search(line)
                if m:
                    ts = f"{m.group(2)} {m.group(3)} {m.group(4)}"
                    if first_ts is None:
                        first_ts = ts
                    last_ts = ts

        summary_lines = ["【时间分析总结】\n"]
        summary_lines.append(f"- 时间范围：[{first_ts or 'unknown'}] → [{last_ts or 'unknown'}]\n")
        summary_lines.append(f"- 最大间隔：{max_interval_str}\n")
        summary_lines.append(f"- 间隔 ≥{min_interval_sec}秒 的记录数：{len(large_intervals)}\n")

        if large_intervals:
            summary_lines.append("\n详细记录（前一条 → 当前条）：\n")
            for idx, (prev_line, curr_line, delta_td) in enumerate(large_intervals, 1):
                delta_str = format_timedelta_for_summary(delta_td)
                summary_lines.append(f"\n{idx}）{delta_str}\n")
                summary_lines.append(prev_line)
                summary_lines.append(curr_line)
        summary_lines.append("\n" + "="*40 + "\n")

        dir_name = os.path.dirname(input_path)
        base_name = os.path.basename(input_path)
        name_without_ext, ext = os.path.splitext(base_name)

        if min_interval_sec.is_integer():
            threshold_str = f"{int(min_interval_sec)}s"
        else:
            threshold_str = f"{min_interval_sec:.3f}".rstrip('0').rstrip('.') + "s"
        sanitized_threshold = sanitize_filename_part(f"Time≥{threshold_str}")
        time_output_name = f"{name_without_ext}[{sanitized_threshold}]{ext}"
        time_output_path = os.path.join(dir_name, time_output_name)
        
        with open(time_output_path, 'w', encoding='utf-8') as f:
            f.writelines(summary_lines)
            f.writelines(output_lines)

    print(''.join(summary_lines))
    print(f"✅ 时间分析完成！结果已保存至：{time_output_path}")


def do_filter_analysis(lines, input_path):
    keyword = safe_input("请输入过滤关键词（例如：#KA 或 #定(S)）：")
    if not keyword:
        print("⚠️  关键词为空，取消过滤。")
        return

    msg = f"🔍 正在过滤包含 '{keyword}' 的日志"
    print()
    with spinner(msg + "..."):
        filtered_lines = [line for line in lines if keyword in line]
        count = len(filtered_lines)

        if count == 0:
            result = {"count": 0, "path": None}
        else:
            sanitized = sanitize_filename_part(keyword)
            dir_name = os.path.dirname(input_path)
            base_name = os.path.basename(input_path)
            name_without_ext, ext = os.path.splitext(base_name)
            filter_output_name = f"{name_without_ext}[Filter_{sanitized}]{ext}"
            filter_output_path = os.path.join(dir_name, filter_output_name)

            with open(filter_output_path, 'w', encoding='utf-8') as f:
                f.writelines(filtered_lines)
            result = {"count": count, "path": filter_output_path}

    if result["count"] == 0:
        print("⚠️  未找到匹配行，不生成文件。")
    else:
        print(f"✅ 共找到 {result['count']} 行，结果已保存至：{result['path']}")


def main():
    print("🚀 欢迎使用日志分析工具 (logAnalysis.py)")
    while True:
        print("\n【start】")
        log_path = safe_input("请输入要分析的日志文件路径：")
        if not log_path:
            print("❌ 路径不能为空，请重新输入。")
            continue
        if not os.path.isfile(log_path):
            print(f"❌ 文件不存在：{log_path}")
            continue

        try:
            with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            print(f"✅ 成功加载日志文件，共 {len(lines)} 行。")
        except Exception as e:
            print(f"❌ 读取文件失败：{e}")
            continue

        while True:
            print("\n" + "-" * 119 + "\n")
            print("当前位置：主菜单")
            print("\n请选择操作：")
            print("0. 退出")
            print("1. 过滤日志")
            print("2. 时间分析")
            print("3. 性能分析")
            choice = safe_input("请输入选项编号（0-3）：")

            if choice == '0':
                print("👋 再见！")
                return
            elif choice == '1':
                do_filter_analysis(lines, log_path)
            elif choice == '2':
                do_time_analysis(lines, log_path)
            elif choice == '3':
                do_perf_analysis(lines, log_path)
            else:
                print("⚠️  无效选项，请输入 0-3。")


if __name__ == "__main__":
    main()
