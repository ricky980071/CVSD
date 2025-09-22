#!/bin/bash
# 使用方法: ./run.sh <編號>
# 例如: ./run.sh 0  → 跑 INST0
#       ./run.sh 5  → 跑 INST5

if [ -z "$1" ]; then
  echo "未指定編號，將預設跑 INST0"
  vcs -full64 -R -f rtl.f +v2k -sverilog -debug_access+all | tee sim.log
else
  vcs -full64 -R -f rtl.f +v2k -sverilog -debug_access+all +define+I$1 | tee sim.log
fi
