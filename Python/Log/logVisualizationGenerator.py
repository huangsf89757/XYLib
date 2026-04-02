# logVisualizationGenerator.py

import os
import sys
import glob
import json

def visualize_timer_data(json_files, output_html_path):
    try:
        from pyecharts import options as opts
        from pyecharts.charts import Scatter
    except ImportError:
        print("❌ 未安装 pyecharts，请运行：pip install pyecharts")
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

    for subtype, timestamps in data_by_subtype.items():
        points = [[round(t - min_ts, 3), 0] for t in sorted(timestamps)]
        c.add_yaxis(
            series_name=subtype,
            y_axis=points,
            symbol_size=12,
            label_opts=opts.LabelOpts(is_show=False),
            linestyle_opts=opts.LineStyleOpts(width=0),
        )

    c.set_global_opts(
        title_opts=opts.TitleOpts(title="Timer 事件时间分布", subtitle=f"总时长: {duration_sec:.3f} 秒 | 共 {len(all_timestamps)} 个事件"),
        xaxis_opts=opts.AxisOpts(type_="value", name="相对时间 (秒)", min_=0, max_=duration_sec, splitline_opts=opts.SplitLineOpts(is_show=True)),
        yaxis_opts=opts.AxisOpts(type_="value", name="", min_=-0.5, max_=0.5, axislabel_opts=opts.LabelOpts(is_show=False), axisline_opts=opts.AxisLineOpts(is_show=False), axistick_opts=opts.AxisTickOpts(is_show=False)),
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
    try:
        from pyecharts import options as opts
        from pyecharts.charts import Scatter
    except ImportError:
        print("❌ 未安装 pyecharts，请运行：pip install pyecharts")
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

    for subtype, timestamps in data_by_subtype.items():
        points = [[round(t - min_ts, 3), 0] for t in sorted(timestamps)]
        c.add_yaxis(
            series_name=subtype,
            y_axis=points,
            symbol_size=12,
            label_opts=opts.LabelOpts(is_show=False),
            linestyle_opts=opts.LineStyleOpts(width=0),
        )

    c.set_global_opts(
        title_opts=opts.TitleOpts(title="App 事件时间分布", subtitle=f"总时长: {duration_sec:.3f} 秒 | 共 {len(all_timestamps)} 个事件"),
        xaxis_opts=opts.AxisOpts(type_="value", name="相对时间 (秒)", min_=0, max_=duration_sec, splitline_opts=opts.SplitLineOpts(is_show=True)),
        yaxis_opts=opts.AxisOpts(type_="value", name="", min_=-0.5, max_=0.5, axislabel_opts=opts.LabelOpts(is_show=False), axisline_opts=opts.AxisLineOpts(is_show=False), axistick_opts=opts.AxisTickOpts(is_show=False)),
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

        choice = input("请选择要可视化的类别（0-8）：")
        if choice == '0':
            return
        if choice not in viz_menu:
            print("⚠️  无效选项。")
            continue

        selected = viz_menu[choice]
        if not selected['enabled']:
            print(f"🚧 '{selected['name']}' 的可视化功能暂未支持，敬请期待！")
            continue

        log_dir = os.path.dirname(input_log_path)
        base_name = os.path.splitext(os.path.basename(input_log_path))[0]
        pattern = os.path.join(log_dir, f"{base_name}[Perf_{selected['name']}*.json")
        json_files = glob.glob(pattern)

        if not json_files:
            print(f"⚠️  未在目录中找到匹配的 JSON 文件：{pattern}")
            print(f"💡 请先通过「性能分析 > {selected['name']} > All」生成相关 JSON 文件。")
            continue

        output_html = os.path.join(log_dir, f"{base_name}[Chart_{selected['name']}].html")

        success = False
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
