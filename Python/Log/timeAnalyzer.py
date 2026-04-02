# timeAnalyzer.py
"""
从 .log 日志文件中分析时间间隔，标记相邻日志的时间差，并提取大间隔片段。
输出文件编码：UTF-8
"""

import os
import sys
from datetime import timedelta

try:
    from fileHelper import (
        sanitize_filename_part,
        safe_input
    )
except ImportError as e:
    print(f"❌ 导入 fileHelper 失败：{e}")
    sys.exit(1)
    
try:
    from timeHelper import (
        parse_log_time_and_tz,
        format_timedelta_for_prefix,
        format_timedelta_for_summary,
        extract_timestamp_string
    )
except ImportError as e:
    print(f"❌ 导入 timeHelper 失败：{e}")
    sys.exit(1)
    
try:
    from spinner import start as spinner_start, stop as spinner_stop
    _HAS_SPINNER = True
except ImportError:
    _HAS_SPINNER = False
    def _dummy(): pass
    spinner_start = spinner_stop = _dummy


def run(log_path):
    # ====== 输入最小时间间隔 ======
    try:
        user_input = safe_input("⏱️  请输入最小时间间隔（秒，支持小数，默认60）：").strip()
        min_interval_sec = float(user_input) if user_input else 60.0
        if min_interval_sec < 0:
            print("⚠️  间隔不能为负数，取消操作。")
            return
    except ValueError:
        print("⚠️  请输入有效的数字，取消操作。")
        return
    

    # ====== 读取日志文件 ======
    if _HAS_SPINNER:
        spinner_start()
    try:
        with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"❌ 读取日志失败：{e}")
        if _HAS_SPINNER:
            spinner_stop()
        return

    file_line_count = len(lines)

    try:
        # ====== 解析有效日志行并建立索引（高性能 O(N)） ======
        time_index = {}      # line_number -> datetime
        valid_lines = []     # (index, dt, line)

        for i, line in enumerate(lines):
            dt, _ = parse_log_time_and_tz(line)
            if dt is not None:
                time_index[i] = dt
                valid_lines.append((i, dt, line))

        log_count = len(valid_lines)
        if log_count == 0:
            print("⚠️  未找到任何含时间戳的日志行。")
            if _HAS_SPINNER:
                spinner_stop()
            return

        # ====== 提取首尾时间戳 ======
        first_ts = extract_timestamp_string(valid_lines[0][2]) or "unknown"
        last_ts = extract_timestamp_string(valid_lines[-1][2]) or "unknown"

        # ====== 计算总跨度 ======
        total_span_td = valid_lines[-1][1] - valid_lines[0][1]
        total_span_str = format_timedelta_for_summary(total_span_td)

        # ====== 查找大间隔对 & 同时记录最大间隔 ======
        slow_pairs = []
        max_delta_td = timedelta(0)
        max_pair = None  # (prev_line, curr_line)

        for i in range(1, log_count):
            delta_td = valid_lines[i][1] - valid_lines[i - 1][1]
            # 更新最大间隔（无论是否超过阈值）
            if delta_td > max_delta_td:
                max_delta_td = delta_td
                max_pair = (
                    valid_lines[i - 1][2].rstrip('\n'),
                    valid_lines[i][2].rstrip('\n')
                )
            # 收集满足用户阈值的间隔
            if delta_td.total_seconds() >= min_interval_sec:
                prev_line = valid_lines[i - 1][2].rstrip('\n')
                curr_line = valid_lines[i][2].rstrip('\n')
                slow_pairs.append((delta_td, prev_line, curr_line))
                

        # ====== 构建总结文本 ======
        summary_lines = [
            "✅日志时间分析成功，结果如下：",
            f"文件行数：{file_line_count} 行",
            f"日志条数：{log_count} 条",
            f"时间范围：[{first_ts}]",
            f"\t\t[{last_ts}]",
            f"时间跨度：{total_span_str}",
        ]
        
        max_delta_str = format_timedelta_for_summary(max_delta_td)
        summary_lines.append(f"\n最大间隔：{max_delta_str}")
        if max_pair:
            summary_lines.append(max_pair[0])
            summary_lines.append(max_pair[1])

        summary_lines.append(f"\n最小时间间隔：{min_interval_sec}秒")

        if not slow_pairs:
            summary_lines.append("满足条件的日志共 0 处。")
        else:
            summary_lines.append(f"满足条件的日志共{len(slow_pairs)}处，分别是：")
            for idx, (delta_td, prev_log, curr_log) in enumerate(slow_pairs, 1):
                delta_str = format_timedelta_for_summary(delta_td)
                summary_lines.append(f"{idx}）{delta_str}")
                summary_lines.append(prev_log)
                summary_lines.append(curr_log)

        summary_text = "\n".join(summary_lines) + "\n"

        # ====== 打印总结到终端（无分割线） ======
        print()
        print(summary_text.rstrip())
        print()

        # ====== 生成带前缀的日志原文 ======
        output_log_lines = []
        prev_dt = None
        for i, line in enumerate(lines):
            if i in time_index:
                current_dt = time_index[i]
                prefix = "[-- --:--:--.---]" if prev_dt is None else format_timedelta_for_prefix(current_dt - prev_dt, False)
                prev_dt = current_dt
                output_log_lines.append(f"{prefix}{line}")
            else:
                output_log_lines.append(line)

        # ====== 生成输出文件名 ======
        base, ext = os.path.splitext(log_path)
        if min_interval_sec.is_integer():
            thresh = f"{int(min_interval_sec)}s"
        else:
            thresh = f"{min_interval_sec:.3f}".rstrip('0').rstrip('.') + "s"
        safe_thresh = sanitize_filename_part(f"Time≥{thresh}")
        out_path = f"{base}[{safe_thresh}]{ext}"

        # ====== 写入结果文件 ======
        try:
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write("==========================日志总结==========================\n")
                f.write(summary_text)
                f.write("\n==========================日志原文==========================\n")
                f.writelines(output_log_lines)
        except Exception as e:
            print(f"❌ 保存分析结果失败：{e}")
            if _HAS_SPINNER:
                spinner_stop()
            return

        # ====== 成功反馈 ======
        print(f"\n✅已保存至：{os.path.abspath(out_path)}")
        if _HAS_SPINNER:
            spinner_stop()

    except Exception as e:
        print(f"❌ 分析过程中出错：{e}")
        if _HAS_SPINNER:
            spinner_stop()
        return


# ==============================
# 命令行入口
# ==============================
if __name__ == "__main__":
    def print_usage():
        print("用法: python3 logTimeAnalyzer.py <input.log>")
        print("说明: 交互式输入时间间隔阈值，分析日志时间分布并标记大间隔")
        print("\n示例:")
        print("  python3 logTimeAnalyzer.py app.log")
        print("  # 输入 60，生成 app[Time≥60s].log")

    if len(sys.argv) != 2:
        print_usage()
        sys.exit(1)

    log_file = sys.argv[1]

    if not os.path.isfile(log_file):
        print(f"❌ 文件不存在：{log_file}")
        sys.exit(1)

    if not log_file.endswith('.log'):
        print("⚠️  注意：建议输入 .log 文件，但非强制。继续处理...")

    run(log_file)
