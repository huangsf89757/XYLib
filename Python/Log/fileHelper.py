import re
from typing import Optional

def sanitize_filename_part(tag: Optional[str]) -> str:
    """
    将字符串转换为安全的文件名片段，移除或替换操作系统不允许的字符。
    
    - 移除以下字符：\\ / : * ? " < > | 以及 ASCII 控制字符 (0x00–0x1f, 0x7f–0x9f)
    - 多个连续下划线会被压缩为一个
    - 首尾下划线会被去除
    - 若结果为空，则返回 'empty'
    
    Args:
        tag: 输入字符串，可为 None
    
    Returns:
        安全的文件名片段
    """
    if not tag:
        return "empty"
    
    # 替换非法字符为下划线
    sanitized = re.sub(r'[\\/:\*\?"<>\|\x00-\x1f\x7f-\x9f]', '_', tag)
    # 压缩多个连续下划线为一个
    sanitized = re.sub(r'_+', '_', sanitized)
    # 去除首尾下划线
    sanitized = sanitized.strip('_')
    # 如果最终为空，返回默认值
    return sanitized if sanitized else "empty"


def safe_input(prompt):
    try:
        return input(prompt).strip()
    except (KeyboardInterrupt, EOFError):
        print("\n👋 操作已取消。")
        exit(0)
