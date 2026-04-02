# logAnalyzer.py
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

def main():
    print("🚀 日志分析工具 v1.0")
    print("支持拖入 .xlog 加密日志文件\n")

    # 步骤1：获取日志文件路径
    while True:
        raw_path = safe_input("请输入或拖入日志文件路径：").strip().strip('"')
        if not raw_path:
            print("❌ 路径不能为空。")
            continue
        if not os.path.isfile(raw_path):
            print("❌ 文件不存在，请重新输入。")
            continue
        break

    # 记录原始文件
    original_file = raw_path
    decrypted_file = None  # 解密后的 .log 文件路径

    # 步骤2：主菜单循环
    while True:
        print("\n" + "=" * 50)
        print("【主菜单】")
        print("0. 退出")
        print("1. 解密日志")
        print("2. 过滤日志")
        print("3. 时间分析")
        print("4. 生命周期")
        print("5. 图表分析")
        choice = safe_input("请选择操作（0-5）：").strip()

        if choice == '0':
            print("👋 再见！")
            break

        elif choice == '1':
            # 解密
            if not original_file.endswith('.xlog'):
                print("⚠️  当前文件不是 .xlog 格式，无需解密。")
                decrypted_file = original_file  # 视为已“解密”
            else:
                from logDecryptor import run
                output_path = original_file[:-5] + ".log"  # 替换 .xlog → .log
                if run(original_file, True):
                    decrypted_file = output_path
                    print(f"✅ 解密成功！生成文件：{output_path}")
                else:
                    print("❌ 解密失败。")

        elif choice in ['2', '3', '4', '5']:
            # 检查是否已解密
            if decrypted_file is None:
                print("❗ 请先执行「1. 解密日志」生成 .log 文件后再进行此操作。")
                continue

            if not os.path.isfile(decrypted_file):
                print("❗ 解密后的日志文件丢失，请重新解密。")
                decrypted_file = None
                continue

            # 调用对应模块
            try:
                if choice == '2':
                    from logFilter import run
                    run(decrypted_file)
                elif choice == '3':
                    from timeAnalyzer import run
                    run(decrypted_file)
                elif choice == '4':
                    from logLifecycleAnalyzer import run
                    run(decrypted_file)
                elif choice == '5':
                    from logChartGenerator import run
                    run(decrypted_file)
            except Exception as e:
                print(f"❌ 执行出错：{e}")

        else:
            print("⚠️  无效选项，请输入 0-5。")

if __name__ == "__main__":
    main()
