# timeHelper.py

import re
from datetime import datetime, timedelta
from typing import Optional, Tuple

# === 时间解析相关正则与函数 ===

LOG_TIME_PATTERN = re.compile(
    r'\[(\w)\]\[(\d{4}-\d{2}-\d{2}) ([+-]?\d+\.?\d*) (\d{2}:\d{2}:\d{2}\.\d{3})\]'
)

def _extract_log_components(line: str) -> Optional[Tuple[str, str, str, str]]:
    """
    内部函数：从日志行中提取 (level, date_str, tz_str, time_str)。
    若不匹配，返回 None。
    """
    match = LOG_TIME_PATTERN.search(line)
    if match:
        return match.groups()  # (level, date, tz, time)
    return None


def extract_timestamp_string(log_line: str) -> Optional[str]:
    """
    从日志行中提取时间戳字符串部分，格式为：
        "2026-01-04 +8.0 23:55:14.370"
    如果未匹配，返回 None。
    
    示例输入:
        '[I][2026-01-04 +8.0 23:55:14.370][3916,...]...'
    输出:
        '2026-01-04 +8.0 23:55:14.370'
    """
    components = _extract_log_components(log_line)
    if components:
        _, date_str, tz_str, time_str = components
        return f"{date_str} {tz_str} {time_str}"
    return None


def parse_log_time_and_tz(line: str) -> Tuple[Optional[datetime], Optional[str]]:
    """
    从日志行中提取 naive datetime 对象和原始时区偏移字符串（如 '+8.0'）。
    若解析失败，返回 (None, None)。
    """
    components = _extract_log_components(line)
    if not components:
        return None, None

    _, date_str, tz_str, time_str = components
    try:
        dt = datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M:%S.%f")
        return dt, tz_str
    except ValueError:
        return None, None


def format_tz_to_hhmm(tz_str: str) -> str:
    """将浮点形式的时区偏移（如 -5.5）格式化为 '+0530' 或 '-0800' 等标准形式"""
    try:
        offset_hours = float(tz_str)
        total_minutes = round(abs(offset_hours) * 60)
        hours, minutes = divmod(int(total_minutes), 60)
        sign = '-' if offset_hours < 0 else '+'
        return f"{sign}{hours:02d}{minutes:02d}"
    except (ValueError, TypeError):
        return "+0000"


def datetime_to_timestamp(dt: datetime) -> float:
    """将 datetime 对象转换为 Unix 时间戳（秒，含毫秒精度）"""
    return dt.timestamp()


def _format_timedelta(td: timedelta, include_sign: bool = True) -> str:
    """
    内部通用函数：将 timedelta 格式化为 [±DD HH:MM:SS.mmm] 或 DD HH:MM:SS.mmm。
    若 timedelta 为 0，则返回 '-- --:--:--.---'（摘要）或 '[=-- --:--:--.---]'（带符号前缀）。
    """
    if td.total_seconds() == 0:
        placeholder = "-- --:--:--.---"
        if include_sign:
            return f"[= {placeholder}]"
        else:
            return f"[{placeholder}]"

    total_seconds = td.total_seconds()
    sign = '-' if total_seconds < 0 else ('+' if include_sign and total_seconds > 0 else '=')
    total_seconds = abs(total_seconds)

    days = int(total_seconds // 86400)
    remainder = total_seconds % 86400
    hours = int(remainder // 3600)
    remainder %= 3600
    minutes = int(remainder // 60)
    seconds = int(remainder % 60)
    milliseconds = int(round((total_seconds - int(total_seconds)) * 1000))

    # 安全进位处理（防御性编程）
    if milliseconds >= 1000:
        seconds += 1
        milliseconds -= 1000
    if seconds >= 60:
        minutes += 1
        seconds -= 60
    if minutes >= 60:
        hours += 1
        minutes -= 60
    if hours >= 24:
        days += 1
        hours -= 24

    base_str = f"[{days:02d} {hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}]"
    if include_sign:
        return f"[{sign} {base_str}]"
    else:
        return base_str


def format_timedelta_for_prefix(td: timedelta, include_sign: bool = True) -> str:
    """将 timedelta 格式化为前缀时间差字符串，用于行首标注。格式：[±DD HH:MM:SS.mmm]"""
    return _format_timedelta(td, include_sign)


def format_timedelta_for_summary(td: timedelta) -> str:
    """将 timedelta 格式化为摘要用的时间差字符串（无符号）。格式：DD HH:MM:SS.mmm"""
    return _format_timedelta(td, include_sign=False)
