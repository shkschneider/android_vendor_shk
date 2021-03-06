#!/usr/bin/env bash
#
# Copyright 2016 ShkMod
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# colors
bd=$(tput bold)
ok=$(tput setaf 2)
wn=$(tput setaf 3)
ko=$(tput setaf 1)
rz=$(tput sgr0)

# commands
command -v make >/dev/null 2>&1 || { echo "$ko[ make ]$rz" >&2 && exit 1 ; }
command -v unzip >/dev/null 2>&1 || { echo "$ko[ unzip ]$rz" >&2 && exit 1 ; }
command -v zip >/dev/null 2>&1 || { echo "$ko[ zip ]$rz" >&2 && exit 1 ; }

# id
[ ! -f "vendor/shk/products/common.mk" ] && echo "$ko[ vendor/shk/products/common.mk ]$rz" >&2 && exit 1
id=$(egrep '^\s*PRODUCT_NAME' "vendor/shk/products/common.mk" 2>/dev/null | cut -d'#' -f1 | awk '{print $NF}')
id=${id:-"shkmod"}
[[ ! $id =~ ^[a-zA-Z0-9]+$ ]] && echo "$ko[ id ]$rz" >&2 && exit 1

# jobs
j="$(grep 'cpu cores' /proc/cpuinfo uniq 2>/dev/null | uniq | awk '{print $NF}')"
[[ ! $j =~ ^[0-9]+$ ]] && j="2"

# general checks
[ -d ".repo" ] || { echo "$ko[ .repo ]$rz" >&2 && exit 1 ; }
[ -d ".repo/manifests" ] || { echo "$ko[ .repo/manifests ]$rz" >&2 && exit 1 ; }
[ -f ".repo/manifests/default.xml" ] || { echo "$ko[ .repo/manifests/default.xml ]$rz" >&2 && exit 1 ; }
[ -d ".repo/local_manifests" ] || { echo "$ko[ .repo/local_manifests ]$rz" >&2 && exit 1 ; }
[ -f ".repo/local_manifests/roomservice.xml" ] || { echo "$ko[ .repo/local_manifests/roomservice.xml ]$rz" >&2 && exit 1 ; }
[ -f "build/envsetup.sh" ] || { echo "$ko[ build/envsetup.sh ]$rz" >&2 && exit 1 ; }
source build/envsetup.sh >/dev/null \
    || { echo "$ko[ source build/envsetup.sh ]$rz" >&2 && exit 1 ; }
croot \
    || { echo "$ko[ croot ]$rz" >&2 && exit 1 ; }

# arguments parsing
info=0
clean=0
while getopts ":ic" opt ; do
    case $opt in
        i) info=1 ;;
        c) clean=1 ;;
        # allows no other option
        \?) echo "$ko[ -$OPTARG ]$rz" >&2 && exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 1 ] && shift && echo "$ko[ $@ ]$rz" >&2 && exit 1

# targets
target=""
while read file ; do
    t=$(egrep '^PRODUCT_NAME' "$file" | sed -r 's;#.+$;;g' | awk '{print $NF}')
    [ -z "$t" ] && continue
    [[ $t =~ _emulator$ ]] && variants="eng userdebug" || variants="user"
    # lists targets if none specified
    if [ $# -eq 0 ] ; then
        for variant in $variants ; do
            echo "$t-$variant"
        done
    # selects target
    else
        for variant in $variants ; do
            if [ "$t-$variant" = "$1" ] ; then
                target="$t-$variant"
                break
            fi
        done
    fi
done < <(find "vendor/shk/products/" -type f -name "shkmod_*.mk" | sort)
[ $# -eq 0 ] && exit 1

# lunch if needed
[[ ! $target =~ ^([a-z]+_)?[a-z0-9][a-z_0-9]*[a-z0-9]\-(eng|userdebug|user)$ ]] && echo "$ko[ target ]$rz" >&2 && exit 1
if [ -z "$TARGET_PRODUCT$TARGET_BUILD_VARIANT" -o "$TARGET_PRODUCT-$TARGET_BUILD_VARIANT" != "target" ] ; then
    lunch "$target" >/dev/null \
        || { echo "$ko[ lunch ]$rz" >&2 && exit 1 ; }
fi

# summary
modName=$(egrep "^PRODUCT_PROPERTY_OVERRIDES\s+\+=\s+ro.mod.name=" vendor/shk/products/common.mk 2>/dev/null | cut -d'=' -f3 | sort -n | tail -1)
[[ ! $modName =~ ^[a-zA-Z]+$ ]] && echo "$ko[ modName ]$rz" >&2 && exit 1
modVersion=$(egrep "^^PRODUCT_PROPERTY_OVERRIDES\s+\+=\s+ro.mod.version=" vendor/shk/products/common.mk 2>/dev/null | cut -d'=' -f3 | sort -n | tail -1)
[[ ! $modVersion =~ ^[0-9]+(\.[0-9]+)*$ ]] && echo "$ko[ modVersion ]$rz" >&2 && exit 1
echo "$bd[ $modName $modVersion ]$rz"
modName=$(echo "$modName" | tr '[A-Z]' '[a-z]')
androidRevision=$(egrep '^\s+<default\s+revision' .repo/manifests/default.xml 2>/dev/null | cut -d'"' -f2 | sed 's;refs/tags/;;' | tail -1)
[[ ! $androidRevision =~ ^android-[0-9\.]+(w?_r[0-9]+)?$ ]] && echo "$ko[ androidRevision ]$rz" >&2 && exit 1
androidVersion=$(egrep "^\s*PLATFORM_VERSION :=" build/core/version_defaults.mk 2>/dev/null | awk '{print $NF}' | sort -n | tail -1)
[[ ! $androidVersion =~ ^[0-9]+(\.[0-9]+)*$ ]] && echo "$ko[ androidVersion ]$rz" >&2 && exit 1
androidSdkVersion=$(egrep "^\s*PLATFORM_SDK_VERSION :=" build/core/version_defaults.mk 2>/dev/null | awk '{print $NF}' | sort -n | tail -1)
[[ ! $androidSdkVersion =~ ^[0-9]+$ ]] && echo "$ko[ androidSdkVersion ]$rz" >&2 && exit 1
androidBuildId=$(egrep "^(export\s)?\s*BUILD_ID=" build/core/build_id.mk 2>/dev/null | cut -d'=' -f2 | sort -n | tail -1)
[[ ! $androidBuildId =~ ^[A-Z0-9]{3}[0-9]{2}[A-Z]?$ ]] && echo "$ko[ androidBuildId ]$rz" >&2 && exit 1
androidSecurityPatch=$(egrep "^\s*PLATFORM_SECURITY_PATCH :=" build/core/version_defaults.mk 2>/dev/null | awk '{print $NF}' | sort -n | tail -1)
[[ ! $androidSecurityPatch =~ ^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$ ]] && echo "$ko[ androidSecurityPatch ]$rz" >&2 && exit 1
androidBuildVariant=$(echo "$TARGET_BUILD_VARIANT" | cut -d'=' -f2 | head -1)
[[ ! $androidBuildVariant =~ ^(eng|userdebug|user)$ ]] && echo "$ko[ androidBuildVariant ]$rz" >&2 && exit 1
device=$(echo "$TARGET_PRODUCT" | cut -d'_' -f2-)
[ -z "$device" ] && echo "$ko[ device ]$rz" >&2 && exit 1
echo "$bd[ Android $androidVersion $androidBuildId ]$rz"
echo "  API: $androidSdkVersion"
echo "  BuildId: $androidBuildId"
echo "  Revision: $androidRevision"
echo "  SecurityPatch: $androidSecurityPatch"
echo "$bd[ Target: $target ]$rz"
echo "  Device: $device"
echo "  Variant: $androidBuildVariant"

[ $info -eq 1 ] && exit 0
unset info
T=$(date +%s)

# preparing
echo "$bd[ Preparing... ]$rz"
if [ -n "$id" ] ; then
    echo "  user"
    export USER="$id"
    echo "  host"
    export HOST="$id"
fi
[ -z "$USER" ] && echo "$ko[ user ]$rz" >&2 && exit 1
updaterscript="META-INF/com/google/android/updater-script"
buildprop="system/build.prop"
signed="signed-${modName}-${modVersion}-${device}-android-${androidVersion}-${androidBuildId}.zip"
ota="ota-${modName}-${modVersion}-${device}-android-${androidVersion}-${androidBuildId}.zip"
rom="rom-${modName}-${modVersion}-${device}-android-${androidVersion}-${androidBuildId}.zip"
stock="stock-${modName}-${modVersion}-${device}-android-${androidVersion}-${androidBuildId}.zip"
ccache="./prebuilts/misc/$(uname -s | tr "[A-Z]" "[a-z]")-x86/ccache/ccache"
if [[ -f "$ccache" ]] && [[ -x "$ccache" ]] ; then
    echo "  ccache"
    export USE_CCACHE=1
    export CCACHE_DIR="$(pwd)/.ccache"
    $ccache -M ${androidSdkVersion}G >/dev/null \
        || { echo "$ko[ ccache ]$rz" >&2 && exit 1 ; }
else
    echo "$wn[ ccache ]$rz" >&2
fi
unset ccache
echo "  ulimit"
ulimit -S -n 1024 || echo "$wn[ ulimit ]$rz" >&2
out=$(echo "$ANDROID_PRODUCT_OUT" | sed -r "s;^$(pwd)/;;")

# cleaning
echo "$bd[ Cleaning... ]$rz"
[ -d "META-INF" ] && rm -rf META-INF
[ -d "$buildprop" ] && rm -f ${buildprop}
echo "  *.zip"
[ -f "$signed" ] && rm -f ${signed}
[ -f "$ota" ] && rm -f ${ota}
[ -f "$rom" ] && rm -f ${rom}
[ -f "$stock" ] && rm -f ${stock}
if [ $clean -eq 1 ] ; then
    echo "  *.img"
    rm -f "$out/*.img" 2>/dev/null
    echo "  make installclean"
    make -j$j installclean >/dev/null \
        || { echo "$ko[ make installclean ]$rz" >&2 && exit 1 ; }
fi

echo "$bd[ Building... ]$rz"
# emulator: make droid
if [ "$device" = "emulator" ] ; then
    echo "  make droid"
    make -j$j droid >/dev/null \
        || { echo "$ko[ make droid ]$rz" >&2 && exit 1 ; }
    [ ! -d "$out" ] && echo "$ko[ out: $out ]$rz" >&2 && exit 1
    [ ! -f "$out/sdcard.img" ] && mksdcard -l sdcard 1024M "$out/sdcard.img" 2>/dev/null
    # skins (even scales if necessary)
    skin="vendor/shk/skins/hammerhead"
    scale=100
    command -v xrandr >/dev/null 2>&1 && {
        if [ ! -d "$skin" ] ; then
            echo "$wn[ $skin ]$rz" >&2
        elif [ ! -f "$skin/layout" ] ; then
            echo "$wn[ $skin/layout ]$rz" >&2
        else
            layoutHeight=$(egrep 'height\s+[0-9]+' "$skin/layout" 2>/dev/null | awk '{print $NF}' | sort -rn | head -1)
            screenHeight=$(xrandr -q 2>/dev/null | egrep 'primary' | sed -r 's;^.+[0-9]+x([0-9]+)[^0-9].+$;\1;')
            if [[ ! $layoutHeight =~ ^[0-9]+$ ]] ; then
                echo "$wn[ $skin/layout ]$rz" >&2
            elif [[ ! $screenHeight =~ ^[0-9]+$ ]] ; then
                echo "$wn[ xrandr ]$rz" >&2
            else
                screenHeight=$(($(($screenHeight / 100)) * 90))
                for scale in {10..100} ; do
                    height=$(($(($layoutHeight / 100)) * $(($scale + 1))))
                    [ $height -ge $screenHeight ] && break
                done
            fi
            unset layoutHeight screenHeight
        fi
    } || {
        [ ! -d "$skin"  ] && echo "$wn[ $skin ]$rz" >&2 ; [ ! -f "$skin/layout"  ] && echo "$wn[ $skin/layout ]$rz" >&2
    }
    scale=$(echo "scale=2; $scale/100" | bc -ql)
    # harware acceleration <http://tools.android.com/tech-docs/emulator>
    gpu=$(egrep '^flags\s*:' "/proc/cpuinfo" 2>/dev/null | head -1 | egrep -w '(vmx|svm)' >/dev/null && echo "on")
    gpu=${gpu:-"off"}
    echo "$bd$ok[ source vendor/shk/envsetup.sh && emulator -skindir $(dirname "$skin") -skin $(basename "$skin") -scale $scale -gpu $gpu -sysdir \$ANDROID_PRODUCT_OUT ]$rz"
    unset skin scale gpu

# else: make dist
else
    echo "  make dist"
    make -j$j dist >/dev/null \
        || { echo "$ko[ make dist ]$rz" >&2 && exit 1 ; }
    [ ! -d "$out" ] && echo "$ko[ out: $out ]$rz" >&2 && exit 1
    echo "$bd[ Assembling... ]$rz"
    # sign_target_files_apks
    echo "  sign_target_files_apks"
    [ ! -f "./build/tools/releasetools/sign_target_files_apks" ] && echo "$ko[ sign_target_files_apks ]$rz" >&2 && exit 1
    dist="$(echo $out | sed -r "s;target/product/$device\$;;")dist"
    ./build/tools/releasetools/sign_target_files_apks ${dist}/${modName}_${device}-target_files-eng.${USER}.zip ${signed} >/dev/null \
        || { echo "$ko[ sign_target_files_apks ]$rz" >&2 && exit 1 ; }
    [ ! -f "$signed" ] && echo "$ko[ $(basename $signed) ]$rz" >&2 && exit 1
    # ota_from_target_files
    echo "  ota_from_target_files"
    [ ! -f "./build/tools/releasetools/ota_from_target_files" ] && echo "$ko[ ota_from_target_files ]$rz" >&2 && exit 1
    ./build/tools/releasetools/ota_from_target_files -n ${signed} ${ota} > /dev/null \
        || { echo "$ko[ ota_from_target_files ]$rz" >&2 && exit 1 ; }
    [ ! -f "$ota" ] && echo "$ko[ $(basename $ota) ]$rz" >&2 && exit 1
    rm -f ${signed}
    unset signed
    echo "$bd[ Finalizing... ]$rz"
    # updater-script
    echo "  updater-script"
    [ -d META-INF ] && { echo "$wn[ META-INF ]$rz" >&2 && exit 1 ; }
    mkdir -p $(dirname ${updaterscript}) >/dev/null
    rm -f ${updaterscript}
    echo "ui_print(\"  _________.__     __      _____             .___\");" >> ${updaterscript}
    echo "ui_print(\" /   _____/|  |__ |  | __ /     \\   ____   __| _/\");" >> ${updaterscript}
    echo "ui_print(\" \\_____  \\ |  |  \\|  |/ //  \\ /  \\ /  _ \\ / __ | \");" >> ${updaterscript}
    echo "ui_print(\" /        \\|   Y  \\    </    Y    (  <_> ) /_/ | \");" >> ${updaterscript}
    echo "ui_print(\"/_______  /|___|  /__|_ \\____|__  /\\____/\\____ | \");" >> ${updaterscript}
    echo "ui_print(\"        \\/      \\/     \\/       \\/            \\/ \");" >> ${updaterscript}
    echo "ui_print(\"Android ${androidVersion} #${androidBuildId} @ ${androidRevision}\");" >> ${updaterscript}
    echo "ui_print(\"\");" >> ${updaterscript}
    echo "show_progress(1.34, 999);" >> ${updaterscript}
    unzip -p ${ota} ${updaterscript} | egrep -v '^(ui_print|show_progress)' >> ${updaterscript} \
        || { echo "$ko[ unzip ${updaterscript} ]$rz" >&2 && exit 1 ; }
    [ -n "$(grep 'recovery' ${updaterscript})" ] \
        && { echo "$wn[ recovery ${updaterscript} ]$rz" >&2 ; }
    zip -u ${ota} ${updaterscript} >/dev/null \
        || { echo "$ko[ zip ${updaterscript} ]$rz" >&2 && exit 1 ; }
    rm -rf META-INF
    unset updaterscript
    # build.prop
    echo "  build.prop"
    unzip -p ${ota} ${buildprop} > ${buildprop} \
        || { echo "$ko[ unzip ${buildprop} ]$rz" >&2 && exit 1 ; }
    sed -i '/^$/d' ${buildprop}
    zip -u ${ota} ${buildprop} >/dev/null \
        || { echo "$ko[ zip ${buildprop} ]$rz" >&2 && exit 1 ; }
    rm -f ${buildprop}
    unset buildprop
    # recovery
    echo "  recovery"
    zip -d ${ota} 'system/etc/recovery-resource.dat' >/dev/null 2>&1 \
        || { echo "$ko[ system/etc/recovery-resource.dat ]$rz" >&2 && exit 1 ; }
    [ -n "$(unzip -l ${ota} | egrep 'system/bin/install-recovery.sh$')" ] \
        && { echo "$wn[ system/bin/install-recovery.sh ]$rz" >&2 ; }
    [ -n "$(unzip -l ${ota} | egrep 'system/recovery-from-boot.p$')" ] \
        && { echo "$wn[ system/recovery-from-boot.p ]$rz" >&2 ; }
    [ -n "$(unzip -l ${ota} | egrep 'recovery/recovery-from-boot.p$')" ] \
        && { echo "$wn[ recovery/recovery-from-boot.p ]$rz" >&2 ; }
    # rom
    mv ${ota} ${rom}
    unset ota
    [ ! -f "$rom" ] && echo "$ko[ $rom ]$rz" && exit 1
    echo "$bd$ok[ $rom $(md5sum "$rom" | awk '{print $1}') ]$rz"
    unset rom
    factory="$dist/${TARGET_PRODUCT}-img-eng.${id}.zip"
    if [ -f "$factory" ] ; then
        mv ${factory} ${stock}
        echo "$bd[ $stock $(md5sum "$stock" | awk '{print $1}') ]$rz"
    fi
    unset dist factory stock
fi

# done
T=$(($(date +%s) - $T))
printf "Done in %02d:%02d:%02d with %d jobs\n" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" "$j"

exit 0

# EOF
