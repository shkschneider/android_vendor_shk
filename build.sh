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

id="shkmod"

# colors
bd=$(tput bold)
ok=$(tput setaf 2)
wn=$(tput setaf 3)
ko=$(tput setaf 1)
rz=$(tput sgr0)

# general checks
[ -z "$(which java)" ] && echo "$ko[ java ]$rz" >&2 && exit 1
[ -z "$(java -version 2>&1 | grep OpenJDK)" ] && echo "$ko[ OpenJDK ]$rz" >&2 && exit 1
[ ! -d ".repo" ] && echo "$ko[ .repo ]$rz" >&2 && exit 1
[ ! -f ".repo/manifests/default.xml" ] && echo "$ko[ .repo/manifests/default.xml ]$rz" >&2 && exit 1
[ ! -f "build/envsetup.sh" ] && echo "$ko[ build/envsetup.sh ]$rz" >&2 && exit 1
source build/envsetup.sh >/dev/null
[ $? -ne 0 ] && echo "$ko[ source ]$rz" >&2 && exit 1
croot
[ $? -ne 0 ] && echo "$ko[ croot ]$rz" >&2 && exit 1

# arguments parsing
info=0
while getopts ":i" opt ; do
    case $opt in
        i) info=1 ;;
        # allows no other option
        \?) echo "$ko[ -$OPTARG ]$rz" >&2 && exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 1 ] && shift && echo "$ko[ $@ ]$rz" >&2 && exit 1
[ ! -f "vendor/shk/vendorsetup.sh" ] && echo "$ko[ vendor/shk/vendorsetup.sh ]$rz" >&2 && exit 1
target=""
while read t ; do
    t=$(echo "$t" | cut -d' ' -f2)
    [ -z "$t" ] && continue
    # lists targets if none specified
    if [ $# -eq 0 ] ; then
        echo $t
    # selects target
    elif [ "$t" = "$1" ] ; then
        target=$t
        break
    fi
done < <(grep add_lunch_combo vendor/shk/vendorsetup.sh)
[ $# -eq 0 ] && exit 1

# lunch if needed
[ -z "$target" ] && echo "$ko[ target ]$rz" >&2 && exit 1
if [ -z "$TARGET_PRODUCT$TARGET_BUILD_VARIANT" ] || [ "$TARGET_PRODUCT-$TARGET_BUILD_VARIANT" != "target" ] ; then
    lunch "$target" >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$ko[ lunch ]$rz" >&2 && exit 1
fi

# summary
user=$(whoami 2>/dev/null)
[ -z "$user" ] && echo "$ko[ user ]$rz" >&2 && exit 1
androidRevision=$(cat .repo/manifests/default.xml | egrep 'default\s+revision' | cut -d'"' -f2 | sed 's#refs/tags/##')
[ -z "$androidRevision" ] && echo "$ko[ androidRevision ]$rz" >&2 && exit 1
androidVersion=$(grep "PLATFORM_VERSION :=" build/core/version_defaults.mk | awk '{print $NF}')
[ -z "$androidVersion" ] && echo "$ko[ androidVersion ]$rz" >&2 && exit 1
androidSdkVersion=$(grep "PLATFORM_SDK_VERSION :=" build/core/version_defaults.mk | awk '{print $NF}')
[ -z "$androidSdkVersion" ] && echo "$ko[ androidSdkVersion ]$rz" >&2 && exit 1
androidBuildId=$(grep "BUILD_ID=" build/core/build_id.mk | cut -d'=' -f2)
[ -z "$androidBuildId" ] && echo "$ko[ androidBuildId ]$rz" >&2 && exit 1
androidSecurityPatch=$(grep "PLATFORM_SECURITY_PATCH :=" build/core/version_defaults.mk | awk '{print $NF}')
[ -z "$androidSecurityPatch" ] && echo "$ko[ androidSecurityPatch ]$rz" >&2 && exit 1
androidBuildVariant=$(echo "$TARGET_BUILD_VARIANT" | cut -d'=' -f2)
[ -z "$androidBuildVariant" ] && echo "$ko[ androidBuildVariant ]$rz" >&2 && exit 1
device=$(echo "$TARGET_PRODUCT" | cut -d'_' -f2-)
[ -z "$device" ] && echo "$ko[ device ]$rz" >&2 && exit 1
modname=$(grep "ro.mod.name=" vendor/shk/products/common.mk 2>/dev/null | cut -d'=' -f2 | cut -d' ' -f1)
[ -z "$modname" ] && echo "$ko[ modname ]$rz" >&2 && exit 1
modversion=$(grep "ro.mod.version=" vendor/shk/products/common.mk 2>/dev/null | cut -d'=' -f2 | cut -d' ' -f1)
[ -z "$modversion" ] && echo "$ko[ modversion ]$rz" >&2 && exit 1
echo "$bd[ $modname $modversion ]$rz"
modname=$(echo "$modname" | tr '[A-Z]' '[a-z]')
echo "$bd[ Android $androidVersion $androidBuildId ]$rz"
echo "  API: $androidSdkVersion"
echo "  BuildId: $androidBuildId"
echo "  Revision: $androidRevision"
echo "  SecurityPatch: $androidSecurityPatch"
echo "$bd[ Target: $target ]$rz"
echo "  Device: $device"
echo "  Variant: $androidBuildVariant"
[ $info -eq 1 ] && exit 0

# preparing
updaterscript="META-INF/com/google/android/updater-script"
buildprop="system/build.prop"
signed="signed-${modname}-${device}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
ota="ota-${modname}-${device}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
rom="rom-${modname}-${device}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
stock="stock-${modname}-${device}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
export USE_CCACHE=1
export CCACHE_DIR=$(pwd)/.ccache
./prebuilts/misc/linux-x86/ccache/ccache -M ${androidSdkVersion}G >/dev/null
[ $? -ne 0 ] && echo "$ko[ ccache ]$rz" >&2 && exit 1
ulimit -S -n 1024
out=$(echo $ANDROID_PRODUCT_OUT | sed -r "s#^$(pwd)/##")

# cooking
TIMEFORMAT="Done in %R seconds, using %P of ($(egrep '^processor' /proc/cpuinfo | wc -l)) CPU resources."
time {
    echo "$bd[ Cleaning... ]$rz"
    [ -d "META-INF" ] && rm -rf META-INF
    [ -d "$buildprop" ] && rm -f ${buildprop}
    [ -f "$signed" ] && rm -f ${signed}
    [ -f "$ota" ] && rm -f ${ota}
    [ -f "$rom" ] && rm -f ${rom}
    [ -f "$stock" ] && rm -f ${stock}
    echo "  make installclean"
    make -j installclean >/dev/null
    [ $? -ne 0 ] && echo "$ko[ make ]$rz" >&2 && exit 1
    echo "$bd[ Building... ]$rz"
    # emulator: make droid
    if [ "$device" = "emulator" ] ; then
        echo "  make droid"
        make -j droid >/dev/null
        [ $? -ne 0 ] && echo "$ko[ make ]$rz" >&2 && exit 1
        [ ! -d "$out" ] && echo "$ko[ out: $out ]$rz" >&2 && exit 1
        sdcard="$out/sdcard.img"
        [ ! -f "$sdcard" ] && mksdcard -l sdcard 1024M ${sdcard}
        echo "$bd$ok[ source vendor/shk/envsetup.sh && ./prebuilts/android-emulator/linux-x86_64/emulator -skin WVGA800 -memory 2014 -gpu on -sysdir $out -sdcard $sdcard ]$rz"
    # else: make dist
    else
        echo "  make dist"
        make -j dist >/dev/null
        [ $? -ne 0 ] && echo "$ko[ make ]$rz" >&2 && exit 1
        [ ! -d "$out" ] && echo "$ko[ out: $out ]$rz" >&2 && exit 1
        echo "$bd[ Assembling... ]$rz"
        echo "  sign_target_files_apks"
        dist="$(echo $out | sed -r "s#target/product/$device\$##")dist"
        ./build/tools/releasetools/sign_target_files_apks ${dist}/${modname}_${device}-target_files-eng.${user}.zip ${signed} >/dev/null
        [ $? -ne 0 ] || [ ! -f "$signed" ] && echo "$ko[ sign_target_files_apks ]$rz" >&2 && exit 1
        echo "  - $signed"
        echo "  ota_from_target_files"
        ./build/tools/releasetools/ota_from_target_files -n ${signed} ${ota} > /dev/null
        [ $? -ne 0 ] || [ ! -f "$ota" ] && echo "$ko[ ota_from_target_files ]$rz" >&2 && exit 1
        echo "  - $ota"
        rm -f ${signed}
        echo "$bd[ Finalizing... ]$rz"
        # updater-script
        echo "  updater-script"
        mkdir -p $(dirname ${updaterscript}) >/dev/null
        rm -f ${updaterscript}
        echo "ui_print(\"  _________.__     __      _____             .___\");" >> ${updaterscript}
        echo "ui_print(\" /   _____/|  |__ |  | __ /     \\   ____   __| _/\");" >> ${updaterscript}
        echo "ui_print(\" \\_____  \\ |  |  \\|  |/ //  \\ /  \\ /  _ \\ / __ | \");" >> ${updaterscript}
        echo "ui_print(\" /        \\|   Y  \\    </    Y    (  <_> ) /_/ | \");" >> ${updaterscript}
        echo "ui_print(\"/_______  /|___|  /__|_ \\____|__  /\\____/\\____ | \");" >> ${updaterscript}
        echo "ui_print(\"        \\/      \\/     \\/       \\/            \\/ \");" >> ${updaterscript}
        echo "ui_print(\"\");" >> ${updaterscript}
        echo "ui_print(\"Android ${androidVersion} #${androidBuildId} @ $androidRevision\");" >> ${updaterscript}
        echo "ui_print(\"\");" >> ${updaterscript}
        echo "show_progress(1.34, 750);" >> ${updaterscript}
        unzip -p ${ota} ${updaterscript} | grep -v 'ui_print' | grep -v 'show_progress' >> ${updaterscript}
        [ $? -ne 0 ] && echo "$ko[ unzip ]$rz" >&2 && exit 1
        zip -u ${ota} ${updaterscript} >/dev/null
        [ $? -ne 0 ] && echo "$ko[ zip ]$rz" >&2 && exit 1
        rm -rf META-INF
        # build.prop
        echo "  build.prop"
        unzip -p ${ota} ${buildprop} > ${buildprop}
        [ $? -ne 0 ] && echo "$ko[ unzip ]$rz" >&2 && exit 1
        sed -i -r "s/^([^=]+)=(.+)?$user(.+)?/\1=\2$id\3/g" ${buildprop}
        sed -i -r "s/(ro.build.host)=.+$/\1=$id/" ${buildprop}
        sed -i '/^$/d' ${buildprop}
        zip -u ${ota} ${buildprop} >/dev/null
        [ $? -ne 0 ] && echo "$ko[ zip ]$rz" >&2 && exit 1
        rm -f ${buildprop}
        # recovery
        echo "  recovery"
        zip -d ${ota} "system/bin/install-recovery.sh" >/dev/null
        zip -d ${ota} "system/etc/recovery-resource.dat" >/dev/null
        # rom
        mv ${ota} ${rom}
        [ ! -f "$rom" ] && echo "$ko[ $rom ]$rz" && exit 1
        echo "$bd$ok[ $rom   $(md5sum "$rom" | awk '{print $1}') ]$rz"
        factory="$dist/$TARGET_PRODUCT-img-eng.$user.zip"
        if [ -f "$factory" ] ; then
            mv ${factory} ${stock}
            echo "$bd[ $stock $(md5sum "$stock" | awk '{print $1}') ]$rz"
        fi
        # root?
        # gapps
        echo "  http://opengapps.org"
    fi
}

exit 0

# EOF
