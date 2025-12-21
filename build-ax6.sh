#!/usr/bin/env bash
set -euo pipefail

echo ">>> 初始化环境"

sudo -E apt -yqq update
sudo -E apt -yqq full-upgrade
sudo -E apt -yqq autoremove --purge
sudo -E apt -yqq autoclean
sudo -E apt -yqq clean
sudo -E apt -yqq install dos2unix python3-netifaces libfuse-dev curl jq

# 这里是build-scripts.immortalwrt.org的初始化脚本
sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'

sudo -E systemctl daemon-reload
sudo -E timedatectl set-timezone "Asia/Shanghai"

#######################################
# 一、固定配置（你以后只改这里）
#######################################

# 设备 / 配置
WRT_CONFIG="IPQ807X-WIFI-YES"
WRT_NAME="AX6"
WRT_SSID="AX6"
WRT_WORD="12345678"
WRT_IP="10.0.0.1"
WRT_PW="无"
WRT_THEME="aurora"

# 源码
WRT_SOURCE="VIKINGYFY/immortalwrt"
WRT_REPO="https://github.com/VIKINGYFY/immortalwrt.git"
WRT_BRANCH="main"

# 行为控制
WRT_TEST="false"        # true = 只生成 .config
WORKDIR="$PWD/wrt"      # 编译目录

#######################################
# 二、派生变量（自动算）
#######################################

WRT_DATE="$(TZ=UTC-8 date +"%y.%m.%d-%H.%M.%S")"
WRT_INFO="${WRT_SOURCE%%/*}"
WRT_MARK="local"

echo "=============================="
echo " OpenWrt Build Script (AX6)"
echo "=============================="
echo "CONFIG : $WRT_CONFIG"
echo "SOURCE : $WRT_SOURCE"
echo "BRANCH : $WRT_BRANCH"
echo "TEST   : $WRT_TEST"
echo "DIR    : $WORKDIR"
echo "=============================="

#######################################
# 三、Clone / 更新源码
#######################################

if [ ! -d "$WORKDIR/.git" ]; then
  git clone --depth=1 -b "$WRT_BRANCH" "$WRT_REPO" "$WORKDIR"
fi

cd "$WORKDIR"
WRT_HASH="$(git rev-parse --short HEAD)"

#######################################
# 四、Feeds & 镜像清理
#######################################

sed -i '/.cn\//d; /aliyun/d; /tencent/d' \
  scripts/projectsmirrors.json 2>/dev/null || true

./scripts/feeds update -a
./scripts/feeds install -a

#######################################
# 五、自定义插件（你那套 UPDATE_PACKAGE）
#######################################

cd package
../Scripts/Packages.sh
../Scripts/Handles.sh
cd ..

#######################################
# 六、生成 .config
#######################################

rm -f .config

cat \
  ../Config/"$WRT_CONFIG".txt \
  ../Config/GENERAL.txt \
  >> .config

../Scripts/Settings.sh

make defconfig -j"$(nproc)"
make clean -j"$(nproc)"

#######################################
# 七、TEST 模式（不编译）
#######################################

if [ "$WRT_TEST" = "true" ]; then
  mkdir -p upload
  cp .config "upload/Config-$WRT_CONFIG-$WRT_DATE.txt"
  echo ">>> TEST 模式结束"
  exit 0
fi

#######################################
# 八、编译
#######################################

make download -j"$(nproc)"
make -j"$(nproc)" || make -j1 V=s

#######################################
# 九、整理输出
#######################################

mkdir -p upload

cp .config "upload/Config-$WRT_CONFIG-$WRT_DATE.txt"

find bin/targets/ -iregex '.*\(json\|buildinfo\|sha256sums\|packages\)$' -exec rm -rf {} +

for f in $(find bin/targets/ -type f); do
  base="$(basename "$f")"
  mv -f "$f" "upload/$WRT_INFO-$WRT_BRANCH-$base"
done

echo ">>> 编译完成"
echo ">>> 输出目录：$WORKDIR/upload"
