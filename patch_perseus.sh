#!/bin/bash
# 下载 apkeep
get_artifact_download_url () {
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl -s $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# 定义需要下载的工具
declare -A artifacts
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# 下载依赖工具
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "下载 $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# 下载碧蓝航线 APK
echo "获取碧蓝航线 APK"
7z x -y com.bilibili.AzurLane.zip  # 添加 -y 参数自动确认覆盖
echo "APK 下载完成！"

# 下载 JMBQ 资源
if [ ! -d "azurlane" ]; then
    echo "下载 JMBQ 资源"
    git clone https://github.com/feathers-l/azurlane
fi

# 反编译 APK
echo "反编译碧蓝航线 APK"
java -jar apktool.jar -q -f d com.bilibili.AzurLane.apk

# 应用修改
echo "复制 JMBQ 库文件"
cp -r azurlane/. com.bilibili.AzurLane/lib/

echo "使用 JMBQ 修改碧蓝航线"
oncreate=$(grep -n -m 1 'onCreate' com.bilibili.AzurLane/smali_classes3/com/unity3d/player/UnityPlayerActivity.smali | sed 's/[0-9]*\:\(.*\)/\1/')
sed -ir "N; s#\($oncreate\n    .locals 2\)#\1\n    const-string v0, \"JMBQ\"\n\n    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n#" com.bilibili.AzurLane/smali_classes3/com/unity3d/player/UnityPlayerActivity.smali

# 重新编译 APK
echo "构建修改版碧蓝航线 APK"
java -jar apktool.jar -q -f b com.bilibili.AzurLane -o build/com.bilibili.AzurLane.patched.apk

# === 新增：签名步骤 ===
echo "签名 APK"
# 创建签名密钥（如果不存在）
if [ ! -f "release-key.keystore" ]; then
    keytool -genkey -v -keystore release-key.keystore \
        -alias my-alias -keyalg RSA -keysize 2048 \
        -validity 10000 -storepass 123456 \
        -dname "CN=, OU=, O=, L=, S=, C="
fi

# 签名 APK
apksigner sign \
    --ks release-key.keystore \
    --ks-pass pass:123456 \
    --ks-key-alias my-alias \
    --out build/com.bilibili.AzurLane.patched.signed.apk \
    build/com.bilibili.AzurLane.patched.apk

echo "最终可安装 APK: build/com.bilibili.AzurLane.patched.signed.apk"
# === 签名步骤结束 ===

# 设置 GitHub Release 版本
s=($(./apkeep -a com.bilibili.AzurLane -l .))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
