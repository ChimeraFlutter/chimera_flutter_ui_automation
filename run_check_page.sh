#!/bin/bash
# 使用虚拟环境运行 check_page.py

cd "$(dirname "$0")"
source venv/bin/activate
python3 check_page.py
