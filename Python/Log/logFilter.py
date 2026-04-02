# logFilter.py
"""
从 .log 日志文件中过滤包含指定关键词的行，并保存为新文件。
输出文件编码：UTF-8
"""

import os
import sys

try:
    from fileHelper import (
        sanitize_filename_part,
        safe_input
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
    _start_spinner = _stop_spinner = _dummy


def run(log_path):
    keyword = safe_input("🔍 请输入过滤关键词：").strip()
    if not keyword:
        print("⚠️  关键词为空，取消操作。")
        return

    # 启动 spinner（如果可用）
    if _HAS_SPINNER:
        spinner_start()

    try:
        # 读取日志文件
        try:
            with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"❌ 读取日志失败：{e}")
            return

        # 过滤匹配行（保留原始换行符前的内容）
        matched = [line.rstrip('\n\r') for line in lines if keyword in line]

        if not matched:
            print("🔍 未找到匹配内容。")
            return

        # 安全构造输出文件名
        base, ext = os.path.splitext(log_path)
        # 仅保留安全字符，避免文件系统错误
        safe_keyword = "".join(c if c.isalnum() or c in (' ', '-', '_') else '_' for c in keyword)[:20].strip('_')
        if not safe_keyword:
            safe_keyword = "keyword"
        safe_thresh = sanitize_filename_part(f"Filtered_{safe_keyword}")
        out_path = f"{base}[{safe_thresh}]{ext}"

        # 写入结果
        try:
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(matched) + '\n')
        except Exception as e:
            print(f"❌ 保存过滤结果失败：{e}")
            return

        # 成功反馈
        print(f"\n✅ 共找到 {len(matched)} 行包含 '{keyword}'")
        print(f"✅ 已保存至：{os.path.abspath(out_path)}")

    finally:
        # 确保停止 spinner
        if _HAS_SPINNER:
            spinner_stop()


# ==============================
# 命令行入口
# ==============================
if __name__ == "__main__":
    def print_usage():
        print("用法: python3 logFilter.py <input.log>")
        print("说明: 交互式输入关键词，自动在同目录生成带过滤结果的新日志文件")
        print("\n示例:")
        print("  python3 logFilter.py app.log")
        print("  # 然后输入关键词如 'ERROR'，生成 app[Filtered_ERROR].log")

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
