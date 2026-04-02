import os
import re
import json
from datetime import datetime, timedelta

LOG_TIME_PATTERN = re.compile(
    r'\[(\w)\]\[(\d{4}-\d{2}-\d{2}) \+\d+\.?\d* (\d{2}:\d{2}:\d{2}\.\d{3})\]'
)

def parse_log_time(line):
    match = LOG_TIME_PATTERN.search(line)
    if not match:
        return None
    _, date_str, time_str = match.groups()
    dt_str = f"{date_str} {time_str}"
    try:
        return datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S.%f")
    except ValueError:
        return None

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
    """生成安全且可读的文件名片段，仅替换跨平台非法字符"""
    if not tag:
        return "empty"
    sanitized = re.sub(r'[\\/:\*\?"<>\|\x00-\x1f\x7f-\x9f]', '_', tag)
    sanitized = re.sub(r'_+', '_', sanitized)
    sanitized = sanitized.strip('_')
    return sanitized if sanitized else "empty"

def extract_life_data(life_lines, life_key):
    prefix = f"#A/B(KA): {life_key} "
    ground_pattern = re.compile(r'^[A-Z]:([a-z]+)=')
    entries = []
    for line in life_lines:
        dt = parse_log_time(line)
        if dt is None:
            continue
        ts = round(datetime_to_timestamp(dt), 3)
        if prefix not in line:
            continue
        rest = line.split(prefix, 1)[1].strip()
        ground_match = ground_pattern.match(rest)
        ground = ground_match.group(1) if ground_match else "unknown"
        entries.append({
            "timestamp": ts,
            "ground": ground,
            "content": rest
        })
    return entries

def do_time_analysis(lines, input_path):
    print("⏳ 正在执行时间分析...")
    parsed_times = [parse_log_time(line) for line in lines]
    
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
            delta_str = format_timedelta_for_prefix(delta_td)
            if delta_td.total_seconds() >= 60:
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
                ts = f"{m.group(2)} +8.0 {m.group(3)}"
                if first_ts is None:
                    first_ts = ts
                last_ts = ts

    summary_lines = ["【时间分析总结】\n"]
    summary_lines.append(f"- 时间范围：[{first_ts or 'unknown'}] → [{last_ts or 'unknown'}]\n")
    summary_lines.append(f"- 最大间隔：{max_interval_str}\n")
    summary_lines.append(f"- 间隔 ≥60秒 的记录数：{len(large_intervals)}\n")

    if large_intervals:
        summary_lines.append("\n详细记录：\n")
        for idx, (prev_line, curr_line, delta_td) in enumerate(large_intervals, 1):
            delta_str = format_timedelta_for_summary(delta_td)
            summary_lines.append(f"\n{idx}）{delta_str}\n")
            summary_lines.append(prev_line)
            summary_lines.append(curr_line)
    summary_lines.append("\n" + "="*40 + "\n")

    dir_name = os.path.dirname(input_path)
    base_name = os.path.basename(input_path)
    name_without_ext, ext = os.path.splitext(base_name)
    time_output_name = f"{name_without_ext}[Time]{ext}"
    time_output_path = os.path.join(dir_name, time_output_name)
    
    with open(time_output_path, 'w', encoding='utf-8') as f:
        f.writelines(summary_lines)
        f.writelines(output_lines)
    
    print(''.join(summary_lines))
    print(f"✅ 时间分析完成！结果已保存至：{time_output_path}")
    print("-" * 119)

def do_filter_analysis(lines, input_path):
    keyword = input("请输入过滤关键词（例如：#KA 或 #定(S)）：").strip()
    if not keyword:
        print("⚠️  关键词为空，取消过滤。")
        print("-" * 119)
        return

    filtered_lines = [line for line in lines if keyword in line]
    count = len(filtered_lines)
    print(f"🔍 共找到 {count} 行包含 '{keyword}'")

    if count == 0:
        print("⚠️  未找到匹配行，不生成文件。")
        print("-" * 119)
        return

    sanitized = sanitize_filename_part(keyword)
    dir_name = os.path.dirname(input_path)
    base_name = os.path.basename(input_path)
    name_without_ext, ext = os.path.splitext(base_name)
    filter_output_name = f"{name_without_ext}[Filter_{sanitized}]{ext}"
    filter_output_path = os.path.join(dir_name, filter_output_name)

    with open(filter_output_path, 'w', encoding='utf-8') as f:
        f.writelines(filtered_lines)
    print(f"✅ 过滤完成！结果已保存至：{filter_output_path}")
    print("-" * 119)

def do_life_analysis(lines, input_path):
    life_key = input("请输入生命周期关键词（例如：Timer）：").strip()
    if not life_key:
        print("⚠️  关键词为空，取消生命周期分析。")
        print("-" * 119)
        return

    search_str = f"#A/B(KA): {life_key}"
    life_lines = [line for line in lines if search_str in line]
    count = len(life_lines)
    print(f"🧬 共提取 {count} 条 '#A/B(KA): {life_key}' 记录")

    if count == 0:
        print("⚠️  未找到匹配记录，不生成文件。")
        print("-" * 119)
        return

    sanitized = sanitize_filename_part(life_key)
    dir_name = os.path.dirname(input_path)
    base_name = os.path.basename(input_path)
    name_without_ext, ext = os.path.splitext(base_name)

    life_log_name = f"{name_without_ext}[Life_{sanitized}]{ext}"
    life_log_path = os.path.join(dir_name, life_log_name)
    with open(life_log_path, 'w', encoding='utf-8') as f:
        f.writelines(life_lines)
    print(f"✅ 生命周期日志已保存至：{life_log_path}")

    life_json_entries = extract_life_data(life_lines, life_key)
    life_json_name = f"{name_without_ext}[Life_{sanitized}].json"
    life_json_path = os.path.join(dir_name, life_json_name)
    with open(life_json_path, 'w', encoding='utf-8') as f:
        json.dump(life_json_entries, f, indent=2, ensure_ascii=False)
    print(f"✅ 生命周期JSON已保存至：{life_json_path}")
    print("-" * 119)

def main():
    print("🚀 欢迎使用日志分析工具 (logAnalysis.py)")
    while True:
        print("\n【start】")
        log_path = input("请输入要分析的日志文件路径：").strip()
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
            print("-" * 119)
            print("\n请选择操作：")
            print("0. 退出")
            print("1. 过滤日志")
            print("2. 时间分析")
            print("3. 生命周期")
            choice = input("请输入选项编号（0-3）：").strip()

            if choice == '0':
                print("👋 再见！")
                return
            elif choice == '1':
                do_filter_analysis(lines, log_path)
            elif choice == '2':
                do_time_analysis(lines, log_path)
            elif choice == '3':
                do_life_analysis(lines, log_path)
            else:
                print("⚠️  无效选项，请输入 0-3。")
                print("-" * 119)  # ← 无效输入也加分隔线（保持一致性）
                continue

            print("\n操作完成，请选择：")
            print("0. 退出")
            print("1. 继续（使用当前日志文件）")
            print("2. 重开（分析新日志文件）")
            next_choice = input("请输入选项（0-2）：").strip()
            if next_choice == '0':
                print("👋 再见！")
                return
            elif next_choice == '1':
                continue
            elif next_choice == '2':
                break
            else:
                print("⚠️  无效选项，默认返回主菜单。")
                continue

if __name__ == "__main__":
    main()
