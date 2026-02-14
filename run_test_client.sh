#!/bin/bash
# 使用虚拟环境运行 test_client.py

cd "$(dirname "$0")"
source venv/bin/activate
python3 test_client.py
