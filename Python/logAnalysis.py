import os
import re
import json
import sys
import threading
import time
from datetime import datetime

# ==============================
# 工具函数
# ==============================

def safe_input(prompt):
    try:
        return input(prompt)
    except (KeyboardInterrupt, EOFError):
        print("\n👋 再见！")
        sys.exit(0)

def spinner(msg):
    """简易加载动画"""
    def spin():
        for c in cycle(['|', '/', '-', '\\']):
            if stop_spinner[0]:
                break
            sys.stdout.write(f'\r{msg} {c}')
            sys.stdout.flush()
            time.sleep(0.1)
        sys.stdout.write('\r' + ' ' * (len(msg) + 2) + '\r')
        sys.stdout.flush()

    from itertools import cycle
    stop_spinner = [False]
    t = threading.Thread(target=spin)
    t.daemon = True
    t.start()
    return _SpinnerContext(stop_spinner)

class _SpinnerContext:
    def __init__(self, flag):
        self.flag = flag
    def __enter__(self):
        return self
    def __exit__(self, *args):
        self.flag[0] = True
        time.sleep(0.1)


# ==============================
# 日志过滤模块
# ==============================

def do_filter_analysis(lines, log_path):
    print("\n【日志过滤】")
    keyword = safe_input("请输入要过滤的关键词（留空返回）：").strip()
    if not keyword:
        return

    matched = []
    for i, line in enumerate(lines, 1):
        if keyword in line:
            matched.append(f"{i:6}: {line.rstrip()}")

    if not matched:
        print("⚠️  未找到匹配内容。")
        return

    print(f"\n✅ 共找到 {len(matched)} 行匹配内容：")
    for m in matched[:50]:  # 最多显示前50行
        print(m)
    if len(matched) > 50:
        print(f"...（仅显示前50条，共{len(matched)}条）")

    save = safe_input("\n是否保存结果到文件？(y/n)：").strip().lower()
    if save == 'y':
        out_path = os.path.splitext(log_path)[0] + f"[Filtered_{keyword.replace(os.sep, '_')}].txt"
        try:
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(matched))
            print(f"✅ 结果已保存至：{out_path}")
        except Exception as e:
            print(f"❌ 保存失败：{e}")


# ==============================
# 时间分析模块
# ==============================

def do_time_analysis(lines, log_path):
    print("\n【时间分析】")
    time_pattern = re.compile(r'\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?')
    timestamps = []

    for line in lines:
        match = time_pattern.search(line)
        if match:
            try:
                dt_str = match.group()
                if '.' in dt_str:
                    dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S.%f")
                else:
                    dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
                timestamps.append(dt)
            except ValueError:
                continue

    if not timestamps:
        print("⚠️  未识别到有效时间戳。")
        return

    timestamps.sort()
    start = timestamps[0]
    end = timestamps[-1]
    duration = end - start
    total_lines = len(lines)
    log_duration_sec = duration.total_seconds()

    print(f"\n✅ 时间范围：{start} → {end}")
    print(f"   总时长：{duration}")
    print(f"   日志行数：{total_lines}")
    if log_duration_sec > 0:
        rate = total_lines / log_duration_sec
        print(f"   平均速率：{rate:.2f} 行/秒")

    # 按小时统计
    hourly = {}
    for ts in timestamps:
        hour_key = ts.strftime("%Y-%m-%d %H:00")
        hourly[hour_key] = hourly.get(hour_key, 0) + 1

    if len(hourly) <= 24:
        print("\n📊 每小时日志量：")
        for h, cnt in sorted(hourly.items()):
            print(f"  {h}: {cnt} 行")


# ==============================
# 性能分析模块
# ==============================

def do_perf_analysis(lines, log_path):
    perf_menu = {
        '1': {'name': 'All',      'enabled': True},
        '2': {'name': 'Timer',    'enabled': True},
        '3': {'name': 'Device',   'enabled': False},
        '4': {'name': 'Process',  'enabled': False},
        '5': {'name': 'App',      'enabled': True},
        '6': {'name': 'Scene',    'enabled': False},
        '7': {'name': 'CPU',      'enabled': False},
        '8': {'name': 'Memory',   'enabled': False},
    }

    while True:
        print("\n" + "-" * 119 + "\n")
        print("当前位置：主菜单 > 性能分析")
        print("\n【性能分析】")
        print("0. 返回上一级")
        for key in ['1', '2', '3', '4', '5', '6', '7', '8']:
            item = perf_menu[key]
            mark = " ✔" if item['enabled'] else ""
            print(f"{key}. {item['name']}{mark}")

        choice = safe_input("请选择类别（0-8）：")
        if choice == '0':
            return
        if choice not in perf_menu:
            print("⚠️  无效选项。")
            continue

        selected = perf_menu[choice]
        if not selected['enabled']:
            print(f"🚧 '{selected['name']}' 的分析功能暂未支持，敬请期待！")
            continue

        target_type = selected['name']
        subtype = None
        if choice != '1':  # 不是 All
            subtypes = get_subtypes_from_log(lines, target_type)
            if not subtypes:
                print(f"⚠️  日志中未找到任何 {target_type} 相关记录。")
                continue
            print(f"\n【{target_type} 子类型】")
            for i, st in enumerate(subtypes, 1):
                print(f"{i}. {st}")
            sub_choice = safe_input(f"请选择子类型（1-{len(subtypes)}），或输入 '0' 分析全部：")
            if sub_choice == '0':
                subtype = "All"
            elif sub_choice.isdigit() and 1 <= int(sub_choice) <= len(subtypes):
                subtype = subtypes[int(sub_choice) - 1]
            else:
                print("⚠️  无效选择。")
                continue

        # 执行分析
        msg = f"🔍 正在分析 {target_type}"
        if subtype and subtype != "All":
            msg += f" > {subtype}"
        print()
        result = []
        with spinner(msg + "..."):
            result = parse_perf_entries(lines, target_type, subtype)

        if not result:
            print("\n⚠️  未提取到有效数据。")
            continue

        # 保存 JSON
        base_name = os.path.splitext(os.path.basename(log_path))[0]
        suffix = f"Perf_{target_type}"
        if subtype and subtype != "All":
            safe_subtype = "".join(c if c.isalnum() or c in "._-" else "_" for c in subtype)
            suffix += f"_{safe_subtype}"
        else:
            suffix += "_All"
        json_path = os.path.join(os.path.dirname(log_path), f"{base_name}[{suffix}].json")

        try:
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            print(f"\n✅ 分析完成！结果已保存至：\n   📁 {json_path}")
        except Exception as e:
            print(f"\n❌ 保存失败：{e}")


def get_subtypes_from_log(lines, perf_type):
    """从日志中提取某类别的所有 subtype（去重）"""
    pattern_map = {
        'Timer': r'\[Timer\]\s*(\S+)',
        'App': r'\[App\]\s*(\S+)',
    }
    pattern = pattern_map.get(perf_type)
    if not pattern:
        return []

    subtypes = set()
    for line in lines:
        match = re.search(pattern, line)
        if match:
            subtypes.add(match.group(1))
    return sorted(subtypes)


def parse_perf_entries(lines, perf_type, subtype=None):
    """解析性能日志条目，返回带 timestamp 的字典列表"""
    patterns = {
        'Timer': r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\s+.*?\[Timer\]\s+(\S+)',
        'App':   r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\s+.*?\[App\]\s+(\S+)',
    }
    pattern = patterns.get(perf_type)
    if not pattern:
        return []

    results = []
    for line in lines:
        match = re.search(pattern, line)
        if match:
            ts_str, st = match.groups()
            if subtype and subtype != "All" and st != subtype:
                continue
            try:
                if '.' in ts_str:
                    dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S.%f")
                else:
                    dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
                timestamp = dt.timestamp()
                results.append({
                    "timestamp": timestamp,
                    "subtype": st,
                    "raw_line": line.strip()
                })
            except Exception:
                continue
    return results


# ==============================
# 可视化模块（Pyecharts >= 2.0 兼容版）
# ==============================

def visualize_timer_data(json_files, output_html_path):
    """绘制 Timer 事件时间分布图（适配 pyecharts 2.x）"""
    try:
        from pyecharts import options as opts
        from pyecharts.charts import Scatter
    except ImportError:
        print("❌ 未安装 pyecharts，请运行：pip install pyecharts")
        return False

    if not json_files:
        print("⚠️  未找到任何 Timer 相关的 JSON 文件。")
        return False

    data_by_subtype = {}
    all_timestamps = []

    for file_path in json_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                entries = json.load(f)
            if not isinstance(entries, list):
                continue
            for entry in entries:
                ts = entry.get("timestamp")
                st = entry.get("subtype", "Unknown")
                if ts is not None and st != "All":
                    data_by_subtype.setdefault(st, []).append(float(ts))
                    all_timestamps.append(float(ts))
        except Exception as e:
            print(f"⚠️  跳过无效文件 {os.path.basename(file_path)}: {e}")
            continue

    if not data_by_subtype:
        print("⚠️  未从 JSON 文件中提取到有效的 Timer 数据。")
        return False

    min_ts = min(all_timestamps)
    max_ts = max(all_timestamps)
    duration_sec = max_ts - min_ts

    c = Scatter(init_opts=opts.InitOpts(width="1000px", height="600px"))
    c.add_xaxis(xaxis_data=[])

    for subtype, timestamps in data_by_subtype.items():
        points = [[round(t - min_ts, 3), 0] for t in sorted(timestamps)]
        c.add_yaxis(
            series_name=subtype,
            y_axis=points,
            symbol_size=12,
            label_opts=opts.LabelOpts(is_show=False),
        )

    c.set_global_opts(
        title_opts=opts.TitleOpts(
            title="Timer 事件时间分布",
            subtitle=f"总时长: {duration_sec:.3f} 秒 | 共 {len(all_timestamps)} 个事件"
        ),
        xaxis_opts=opts.AxisOpts(
            type_="value",
            name="相对时间 (秒)",
            min_=0,
            max_=duration_sec,
            splitline_opts=opts.SplitLineOpts(is_show=True),
        ),
        yaxis_opts=opts.AxisOpts(
            type_="value",
            name="",
            min_=-0.5,
            max_=0.5,
            axislabel_opts=opts.LabelOpts(is_show=False),
            axisline_opts=opts.AxisLineOpts(is_show=False),
            axistick_opts=opts.AxisTickOpts(is_show=False),
        ),
        tooltip_opts=opts.TooltipOpts(trigger="item", formatter="{a}: {c[0]} 秒"),
        legend_opts=opts.LegendOpts(pos_left="center", pos_top="bottom"),
    )

    try:
        c.render(output_html_path)
        return True
    except Exception as e:
        print(f"❌ 渲染图表失败: {e}")
        return False


def visualize_app_data(json_files, output_html_path):
    """绘制 App 事件时间分布图（适配 pyecharts 2.x）"""
    try:
        from pyecharts import options as opts
        from pyecharts.charts import Scatter
    except ImportError:
        print("❌ 未安装 pyecharts，请运行：pip install pyecharts")
        return False

    if not json_files:
        print("⚠️  未找到任何 App 相关的 JSON 文件。")
        return False

    data_by_subtype = {}
    all_timestamps = []

    for file_path in json_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                entries = json.load(f)
            if not isinstance(entries, list):
                continue
            for entry in entries:
                ts = entry.get("timestamp")
                st = entry.get("subtype", "Unknown")
                if ts is not None and st != "All":
                    data_by_subtype.setdefault(st, []).append(float(ts))
                    all_timestamps.append(float(ts))
        except Exception as e:
            print(f"⚠️  跳过无效文件 {os.path.basename(file_path)}: {e}")
            continue

    if not data_by_subtype:
        print("⚠️  未从 JSON 文件中提取到有效的 App 数据。")
        return False

    min_ts = min(all_timestamps)
    max_ts = max(all_timestamps)
    duration_sec = max_ts - min_ts

    c = Scatter(init_opts=opts.InitOpts(width="1000px", height="600px"))
    c.add_xaxis(xaxis_data=[])

    for subtype, timestamps in data_by_subtype.items():
        points = [[round(t - min_ts, 3), 0] for t in sorted(timestamps)]
        c.add_yaxis(
            series_name=subtype,
            y_axis=points,
            symbol_size=12,
            label_opts=opts.LabelOpts(is_show=False),
        )

    c.set_global_opts(
        title_opts=opts.TitleOpts(
            title="App 事件时间分布",
            subtitle=f"总时长: {duration_sec:.3f} 秒 | 共 {len(all_timestamps)} 个事件"
        ),
        xaxis_opts=opts.AxisOpts(
            type_="value",
            name="相对时间 (秒)",
            min_=0,
            max_=duration_sec,
            splitline_opts=opts.SplitLineOpts(is_show=True),
        ),
        yaxis_opts=opts.AxisOpts(
            type_="value",
            name="",
            min_=-0.5,
            max_=0.5,
            axislabel_opts=opts.LabelOpts(is_show=False),
            axisline_opts=opts.AxisLineOpts(is_show=False),
            axistick_opts=opts.AxisTickOpts(is_show=False),
        ),
        tooltip_opts=opts.TooltipOpts(trigger="item", formatter="{a}: {c[0]} 秒"),
        legend_opts=opts.LegendOpts(pos_left="center", pos_top="bottom"),
    )

    try:
        c.render(output_html_path)
        return True
    except Exception as e:
        print(f"❌ 渲染图表失败: {e}")
        return False


def do_visualization(input_log_path):
    """可视化主菜单"""
    viz_menu = {
        '1': {'name': 'All',      'enabled': False},
        '2': {'name': 'Timer',    'enabled': True},
        '3': {'name': 'Device',   'enabled': False},
        '4': {'name': 'Process',  'enabled': False},
        '5': {'name': 'App',      'enabled': True},
        '6': {'name': 'Scene',    'enabled': False},
        '7': {'name': 'CPU',      'enabled': False},
        '8': {'name': 'Memory',   'enabled': False},
    }

    while True:
        print("\n" + "-" * 119 + "\n")
        print("当前位置：主菜单 > 可视化图表")
        print("\n【可视化图表】")
        print("0. 返回上一级")
        for key in ['1', '2', '3', '4', '5', '6', '7', '8']:
            item = viz_menu[key]
            mark = " ✔" if item['enabled'] else ""
            print(f"{key}. {item['name']}{mark}")

        choice = safe_input("请选择要可视化的类别（0-8）：")
        if choice == '0':
            return
        if choice not in viz_menu:
            print("⚠️  无效选项。")
            continue

        selected = viz_menu[choice]
        if not selected['enabled']:
            print(f"🚧 '{selected['name']}' 的可视化功能暂未支持，敬请期待！")
            continue

        if selected['name'] in ('Timer', 'App'):
            log_dir = os.path.dirname(input_log_path)
            base_name = os.path.splitext(os.path.basename(input_log_path))[0]
            import glob
            pattern = os.path.join(log_dir, f"{base_name}[Perf_{selected['name']}*.json")
            json_files = glob.glob(pattern)

            if not json_files:
                print(f"⚠️  未在目录中找到匹配的 JSON 文件：{pattern}")
                print(f"💡 请先通过「性能分析 > {selected['name']} > All」生成相关 JSON 文件。")
                continue

            output_html = os.path.join(log_dir, f"{base_name}[Chart_{selected['name']}].html")

            msg = f"📊 正在生成 {selected['name']} 可视化图表（共 {len(json_files)} 个文件）"
            print()
            success = False
            with spinner(msg + "..."):
                if selected['name'] == 'Timer':
                    success = visualize_timer_data(json_files, output_html)
                elif selected['name'] == 'App':
                    success = visualize_app_data(json_files, output_html)

            if success:
                print(f"\n✅ 图表已生成！文件路径：\n   📊 {output_html}")
                try:
                    if sys.platform == "win32":
                        os.startfile(output_html)
                    elif sys.platform == "darwin":
                        os.system(f"open '{output_html}'")
                    else:
                        os.system(f"xdg-open '{output_html}'")
                except Exception:
                    pass
            else:
                print("\n❌ 图表生成失败。")


# ==============================
# 主程序入口
# ==============================

def main():
    print("🚀 欢迎使用日志分析工具 (logAnalysis.py)")
    while True:
        print("\n【start】")
        log_path = safe_input("请输入要分析的日志文件路径：").strip()
        if not log_path:
            print("❌ 路径不能为空，请重新输入。")
            continue

        print(f"🔍 尝试访问路径：{repr(log_path)}")

        if not os.path.isfile(log_path):
            print(f"❌ 文件不存在：{log_path}")
            if os.path.exists(log_path):
                print("💡 注意：该路径存在，但不是一个普通文件（可能是目录或特殊文件）。")
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
            print("4. 可视化图表")
            choice = safe_input("请输入选项编号（0-4）：")

            if choice == '0':
                print("👋 再见！")
                return
            elif choice == '1':
                do_filter_analysis(lines, log_path)
            elif choice == '2':
                do_time_analysis(lines, log_path)
            elif choice == '3':
                do_perf_analysis(lines, log_path)
            elif choice == '4':
                do_visualization(log_path)
            else:
                print("⚠️  无效选项，请输入 0-4。")


if __name__ == "__main__":
    main()
