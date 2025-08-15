#!/bin/bash
# 设置Android SDK路径
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/build-tools/32.0.0

# 下载工具函数
get_artifact_download_url () {
    # 保持不变
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

# 修复：处理分卷压缩文件
echo "解压碧蓝航线 APK 分卷包"
7z x -y com.bilibili.AzurLane.z*

# 反编译 APK
echo "反编译碧蓝航线 APK"
java -jar apktool.jar -q -f d com.bilibili.AzurLane.apk

# 应用修改（保持不变）

# 重新编译 APK
echo "构建修改版碧蓝航线 APK"
java -jar apktool.jar -q -f b com.bilibili.AzurLane -o build/com.bilibili.AzurLane.patched.unsigned.apk

# 移除签名步骤（使用工作流中的专业签名）
echo "生成未签名APK：build/com.bilibili.AzurLane.patched.unsigned.apk"

# 设置版本信息
s=($(./apkeep -a com.bilibili.AzurLane -l .))
echo "PERSEUS_VERSION=${s[-1]}" >> $GITHUB_ENV
