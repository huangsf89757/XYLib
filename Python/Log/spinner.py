# spinner.py
import sys
import threading
import time

_spinner_active = False
_spinner_thread = None
_spinner_message = "操作中"  # 默认文案

def _spinner_animation():
    """后台线程执行的转圈动画"""
    chars = "|/-\\"
    idx = 0
    while _spinner_active:
        sys.stdout.write('\r⏳ ' + _spinner_message + ' ' + chars[idx % len(chars)])
        sys.stdout.flush()
        idx += 1
        time.sleep(0.1)
    # 清除当前行
    sys.stdout.write('\r' + ' ' * (len(_spinner_message) + 20) + '\r')
    sys.stdout.flush()

def start(message="操作中"):
    """启动加载动画，可自定义提示文案"""
    global _spinner_active, _spinner_thread, _spinner_message
    if _spinner_active:
        return  # 避免重复启动
    _spinner_message = message
    _spinner_active = True
    _spinner_thread = threading.Thread(target=_spinner_animation, daemon=True)
    _spinner_thread.start()

def stop():
    """停止加载动画"""
    global _spinner_active
    _spinner_active = False
    if _spinner_thread and _spinner_thread.is_alive():
        _spinner_thread.join(timeout=0.2)  # 等待线程结束（最多0.2秒）
