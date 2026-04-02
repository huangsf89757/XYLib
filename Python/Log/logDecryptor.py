# logDecryptor.py
"""
将 .xlog 二进制日志解密/解压为可读的 .log 文本文件
输出文件编码：UTF-8
"""

import struct
import zlib
import traceback
import os
import sys

try:
    from spinner import start as _start_spinner, stop as _stop_spinner
    _HAS_SPINNER = True
except ImportError:
    # 如果没有 spinner 模块，则禁用动画（不影响核心功能）
    _HAS_SPINNER = False
    def _dummy(): pass
    _start_spinner = _stop_spinner = _dummy

# Magic numbers
MAGIC_NO_COMPRESS_START = 0x03
MAGIC_NO_COMPRESS_START1 = 0x06
MAGIC_NO_COMPRESS_NO_CRYPT_START = 0x08
MAGIC_COMPRESS_START = 0x04
MAGIC_COMPRESS_START1 = 0x05
MAGIC_COMPRESS_START2 = 0x07
MAGIC_COMPRESS_NO_CRYPT_START = 0x09
MAGIC_SYNC_ZSTD_START = 0x0A
MAGIC_SYNC_NO_CRYPT_ZSTD_START = 0x0B
MAGIC_ASYNC_ZSTD_START = 0x0C
MAGIC_ASYNC_NO_CRYPT_ZSTD_START = 0x0D
MAGIC_END = 0x00


def _get_crypt_key_len(magic):
    if magic in (MAGIC_NO_COMPRESS_START, MAGIC_COMPRESS_START, MAGIC_COMPRESS_START1):
        return 4
    elif magic in (
        MAGIC_COMPRESS_START2, MAGIC_NO_COMPRESS_START1, MAGIC_NO_COMPRESS_NO_CRYPT_START,
        MAGIC_COMPRESS_NO_CRYPT_START, MAGIC_SYNC_ZSTD_START, MAGIC_SYNC_NO_CRYPT_ZSTD_START,
        MAGIC_ASYNC_ZSTD_START, MAGIC_ASYNC_NO_CRYPT_ZSTD_START,
    ):
        return 64
    return None


def _find_log_start(buffer_data, count=2):
    offset = 0
    while offset < len(buffer_data):
        magic = buffer_data[offset]
        crypt_key_len = _get_crypt_key_len(magic)
        if crypt_key_len is not None:
            # 简化校验：只检查头尾
            header_len = 1 + 2 + 1 + 1 + 4 + crypt_key_len
            if offset + header_len + 1 <= len(buffer_data):
                length = struct.unpack_from("<I", buffer_data, offset + header_len - 4 - crypt_key_len)[0]
                end_pos = offset + header_len + length
                if end_pos + 1 <= len(buffer_data) and buffer_data[end_pos] == MAGIC_END:
                    return offset
        offset += 1
    return -1


def decrypt_xlog_to_log(input_path, output_path):
    try:
        with open(input_path, "rb") as f:
            data = bytearray(f.read())

        start = _find_log_start(data, 2)
        if start == -1:
            print("❌ 未找到有效的日志块起始位置。")
            return False

        out_lines = []
        pos = start
        last_seq = 0

        while pos < len(data):
            magic = data[pos]
            crypt_key_len = _get_crypt_key_len(magic)
            if crypt_key_len is None:
                break

            header_len = 1 + 2 + 1 + 1 + 4 + crypt_key_len
            if pos + header_len > len(data):
                break

            length = struct.unpack_from("<I", data, pos + header_len - 4 - crypt_key_len)[0]
            seq = struct.unpack_from("<H", data, pos + header_len - 4 - crypt_key_len - 2 - 2)[0]

            if seq not in (0, 1) and last_seq != 0 and seq != last_seq + 1:
                out_lines.append(f"[F] log seq:{last_seq+1}-{seq-1} is missing\n")
            if seq != 0:
                last_seq = seq

            raw_start = pos + header_len
            raw_end = raw_start + length
            if raw_end > len(data):
                break

            raw_data = data[raw_start:raw_end]

            # 解压逻辑（简化版，仅支持 zlib 和无压缩）
            try:
                if magic in (MAGIC_COMPRESS_START, MAGIC_COMPRESS_NO_CRYPT_START):
                    decompressor = zlib.decompressobj(-zlib.MAX_WBITS)
                    text = decompressor.decompress(raw_data).decode('utf-8', errors='replace')
                elif magic == MAGIC_COMPRESS_START1:
                    # 多块压缩
                    decompress_data = bytearray()
                    tmp = raw_data
                    while len(tmp) >= 2:
                        single_len = struct.unpack_from("<H", tmp, 0)[0]
                        if single_len + 2 > len(tmp):
                            break
                        decompress_data.extend(tmp[2:single_len + 2])
                        tmp = tmp[single_len + 2:]
                    decompressor = zlib.decompressobj(-zlib.MAX_WBITS)
                    text = decompressor.decompress(decompress_data).decode('utf-8', errors='replace')
                else:
                    # 无压缩
                    text = raw_data.decode('utf-8', errors='replace')

                out_lines.append(text)

            except Exception as e:
                out_lines.append(f"[F] decompress error at offset {pos}: {e}\n")

            # 跳到下一个块
            next_pos = raw_end + 1  # +1 for MAGIC_END
            if next_pos >= len(data) or data[next_pos] not in [m for m in range(256) if _get_crypt_key_len(m) is not None]:
                break
            pos = next_pos

        if not out_lines:
            print("⚠️  解密后内容为空。")
            return False

        with open(output_path, "w", encoding="utf-8") as f:
            f.write("".join(out_lines))

        return True

    except Exception as e:
        print(f"❌ 解密异常: {e}")
        traceback.print_exc()
        return False


def run(input_path, withSpinner=True):
    """
    带用户反馈的解密入口函数。
    
    参数:
        input_path (str): 输入的 .xlog 文件路径（必须以 .xlog 结尾）
        withSpinner (bool): 是否显示加载动画（默认 True）
    
    返回:
        bool: True 表示成功，False 表示失败
    """
    if not os.path.isfile(input_path):
        print("❌ 输入文件不存在")
        return False

    if not input_path.endswith('.xlog'):
        print("❌ 输入文件应以 .xlog 结尾")
        return False

    # 自动构造输出路径：同目录下，.xlog → .log
    output_path = os.path.splitext(input_path)[0] + '.log'

    # 启动加载动画（如果启用且可用）
    if withSpinner and _HAS_SPINNER:
        _start_spinner()

    try:
        success = decrypt_xlog_to_log(input_path, output_path)
        return success
    finally:
        # 确保停止动画
        if withSpinner and _HAS_SPINNER:
            _stop_spinner()


# ==============================
# 命令行入口（优化版）
# ==============================
if __name__ == "__main__":
    def print_usage():
        print("用法: python3 logDecryptor.py <input.xlog> [no-spinner]")
        print("说明: 将 .xlog 二进制日志解密并解压为同名 .log 文本文件（UTF-8 编码）")
        print("\n示例:")
        print("  python3 logDecryptor.py app.xlog")
        print("  # 输出 app.log")
        print("\n  python3 logDecryptor.py logs/debug.xlog no-spinner")
        print("  # 禁用加载动画，输出 logs/debug.log")

    # 参数数量检查：至少1个，最多2个
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print_usage()
        sys.exit(1)

    input_file = sys.argv[1]

    # 检查文件是否存在
    if not os.path.isfile(input_file):
        print(f"❌ 输入文件不存在：{input_file}")
        sys.exit(1)

    # 检查扩展名
    if not input_file.endswith('.xlog'):
        print("❌ 输入文件必须以 .xlog 结尾")
        sys.exit(1)

    # 解析是否禁用 spinner
    disable_spinner = False
    if len(sys.argv) == 3:
        arg = sys.argv[2].lower()
        if arg in ("no-spinner", "false", "0", "off"):
            disable_spinner = True
        else:
            print(f"⚠️  未知参数：'{sys.argv[2]}'，忽略或使用 'no-spinner'")
            # 也可以选择严格报错，这里选择宽容处理

    # 执行解密
    success = run(input_file, withSpinner=not disable_spinner)

    if success:
        output_file = os.path.splitext(input_file)[0] + '.log'
        print(f"\n✅ 解密成功！输出文件：{os.path.abspath(output_file)}")
    else:
        print("\n❌ 解密失败")
        sys.exit(1)
