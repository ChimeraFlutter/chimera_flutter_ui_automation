#!/bin/bash
# 使用虚拟环境运行 click_button.py

cd "$(dirname "$0")"
source venv/bin/activate
python3 click_button.py "$@"
