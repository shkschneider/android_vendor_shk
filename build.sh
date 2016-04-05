#!/usr/bin/env bash

# general checks
[ -z "$(which java)" ] && echo -e "\\033[1;31m[ java ]\\033[0;0m" >&2 && exit 1
[ -z "$(java -version 2>&1 | grep OpenJDK)" ] && echo -e "\\033[1;31m[ OpenJDK ]\\033[0;0m" >&2 && exit 1
[ ! -d ".repo" ] && echo -e "\\033[1;31m[ .repo ]\\033[0;0m" >&2 && exit 1
[ ! -f ".repo/manifests/default.xml" ] && echo -e "\\033[1;31m[ .repo/manifests/default.xml ]\\033[0;0m" >&2 && exit 1
[ ! -f "build/envsetup.sh" ] && echo -e "\\033[1;31m[ build/envsetup.sh ]\\033[0;0m" >&2 && exit 1
source build/envsetup.sh >/dev/null
[ $? -ne 0 ] && echo -e "\\033[1;31m[ source ]\\033[0;0m" >&2 && exit 1
croot
[ $? -ne 0 ] && echo -e "\\033[1;31m[ croot ]\\033[0;0m" >&2 && exit 1

# arguments parsing
info=0
while getopts ":i" opt ; do
    case $opt in
        i) info=1 ;;
        # allows no other option
        \?) echo -e "\\033[1;31m[ -$OPTARG ]\\033[0;0m" >&2 && exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 1 ] && shift && echo -e "\\033[1;31m[ $@ ]\\033[0;0m" >&2 && exit 1
[ ! -f "vendor/shk/vendorsetup.sh" ] && echo -e "\\033[1;31m[ vendor/shk/vendorsetup.sh ]\\033[0;0m" >&2 && exit 1
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
[ -z "$target" ] && echo -e "\\033[1;31m[ target ]\\033[0;0m" >&2 && exit 1
# lunch if needed
if [ -z "$TARGET_PRODUCT$TARGET_BUILD_VARIANT" ] || [ "$TARGET_PRODUCT-$TARGET_BUILD_VARIANT" != "target" ] ; then
    lunch "$target" >/dev/null 2>&1
    [ $? -ne 0 ] && echo -e "\\033[1;31m[ lunch ]\\033[0;0m" >&2 && exit 1
fi

# summary
user=$(whoami 2>/dev/null)
[ -z "$user" ] && echo -e "\\033[1;31m[ user ]\\033[0;0m" >&2 && exit 1
androidRevision=$(cat .repo/manifests/default.xml | egrep 'default\s+revision' | cut -d'"' -f2 | sed 's#refs/tags/##')
[ -z "$androidRevision" ] && echo -e "\\033[1;31m[ androidRevision ]\\033[0;0m" >&2 && exit 1
androidVersion=$(grep "PLATFORM_VERSION :=" build/core/version_defaults.mk | awk '{print $NF}')
[ -z "$androidVersion" ] && echo -e "\\033[1;31m[ androidVersion ]\\033[0;0m" >&2 && exit 1
androidSdkVersion=$(grep "PLATFORM_SDK_VERSION :=" build/core/version_defaults.mk | awk '{print $NF}')
[ -z "$androidSdkVersion" ] && echo -e "\\033[1;31m[ androidSdkVersion ]\\033[0;0m" >&2 && exit 1
androidBuildId=$(grep "BUILD_ID=" build/core/build_id.mk | cut -d'=' -f2)
[ -z "$androidBuildId" ] && echo -e "\\033[1;31m[ androidBuildId ]\\033[0;0m" >&2 && exit 1
androidSecurityPatch=$(grep "PLATFORM_SECURITY_PATCH :=" build/core/version_defaults.mk | awk '{print $NF}')
[ -z "$androidSecurityPatch" ] && echo -e "\\033[1;31m[ androidSecurityPatch ]\\033[0;0m" >&2 && exit 1
androidBuildVariant=$(echo "$TARGET_BUILD_VARIANT" | cut -d'=' -f2)
[ -z "$androidBuildVariant" ] && echo -e "\\033[1;31m[ androidBuildVariant ]\\033[0;0m" >&2 && exit 1
device=$(echo "$TARGET_PRODUCT" | cut -d'_' -f2-)
[ -z "$device" ] && echo -e "\\033[1;31m[ device ]\\033[0;0m" >&2 && exit 1
modname=$(grep "ro.mod.name=" vendor/shk/products/common.mk 2>/dev/null | cut -d'=' -f2 | cut -d' ' -f1)
[ -z "$modname" ] && echo -e "\\033[1;31m[ modname ]\\033[0;0m" >&2 && exit 1
modversion=$(grep "ro.mod.version=" vendor/shk/products/common.mk 2>/dev/null | cut -d'=' -f2 | cut -d' ' -f1)
[ -z "$modversion" ] && echo -e "\\033[1;31m[ modversion ]\\033[0;0m" >&2 && exit 1
echo -ne "\\033[1m"
echo     "[ $modname $modversion ]"
echo -ne "\\033[0m"
modname=$(echo "$modname" | tr '[A-Z]' '[a-z]')
echo -ne "\\033[1m"
echo     "[ Android $androidVersion $androidBuildId ]"
echo -ne "\\033[0m"
echo     "  API: $androidSdkVersion"
echo     "  BuildId: $androidBuildId"
echo     "  Revision: $androidRevision"
echo     "  SecurityPatch: $androidSecurityPatch"
echo -ne "\\033[1m"
echo     "[ Target: $target ]"
echo -ne "\\033[0m"
echo     "  Device: $device"
echo     "  Variant: $androidBuildVariant"
[ $info -eq 1 ] && exit 0

# preparing
updaterscript="META-INF/com/google/android/updater-script"
buildprop="system/build.prop"
signed="signed-${modname}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
ota="ota-${modname}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
rom="rom-${modname}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
stock="stock-${modname}-${modversion}-android-${androidVersion}-${androidBuildId}.zip"
export USE_CCACHE=1
export CCACHE_DIR=$(pwd)/.ccache
./prebuilts/misc/linux-x86/ccache/ccache -M ${androidSdkVersion}G >/dev/null
[ $? -ne 0 ] && echo -e "\\033[1;31m[ ccache ]\\033[0;0m" >&2 && exit 1
ulimit -S -n 1024
out=$(echo $ANDROID_PRODUCT_OUT | sed -r "s#^$(pwd)/##")

# cooking
TIMEFORMAT="Done in %R seconds, using %P of ($(egrep '^processor' /proc/cpuinfo | wc -l)) CPU resources."
time {
    echo -ne "\\033[1m"
    echo     "[ Cleaning... ]"
    echo -ne "\\033[0m"
    [ -d "META-INF" ] && rm -rf META-INF
    [ -d "$buildprop" ] && rm -f ${buildprop}
    [ -f "$signed" ] && rm -f ${signed}
    [ -f "$ota" ] && rm -f ${ota}
    [ -f "$rom" ] && rm -f ${rom}
    [ -f "$stock" ] && rm -f ${stock}
    echo     "  make installclean"
    make -j installclean >/dev/null
    [ $? -ne 0 ] && echo -e "\\033[1;31m[ make ]\\033[0;0m" >&2 && exit 1
    echo -ne "\\033[1m"
    echo     "[ Building... ]"
    echo -ne "\\033[0m"
    # emulator: make droid
    if [ "$device" = "emulator" ] ; then
        echo     "  make droid"
        make -j droid >/dev/null
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ make ]\\033[0;0m" >&2 && exit 1
        [ ! -d "$out" ] && echo -e "\\033[1;31m[ out: $out ]\\033[0;0m" >&2 && exit 1
        sdcard="$out/sdcard.img"
        [ ! -f "$sdcard" ] && mksdcard -l sdcard 1024M ${sdcard}
        echo -ne "\\033[1;32m"
        echo     "[ source vendor/shk/envsetup.sh && emulator -skin WVGA800 -memory 2014 -gpu on -sysdir $out -sdcard $sdcard ]"
        echo -ne "\\033[0;00m"
    # else: make dist
    else
        echo     "  make dist"
        make -j dist >/dev/null
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ make ]\\033[0;0m" >&2 && exit 1
        [ ! -d "$out" ] && echo -e "\\033[1;31m[ out: $out ]\\033[0;0m" >&2 && exit 1
        echo -ne "\\033[1m"
        echo     "[ Assembling... ]"
        echo -ne "\\033[0m"
        echo     "  sign_target_files_apks"
        dist="$(echo $out | sed -r "s#target/product/$device\$##")dist"
        ./build/tools/releasetools/sign_target_files_apks ${dist}/${modname}_${device}-target_files-eng.${user}.zip ${signed} >/dev/null
        [ $? -ne 0 ] || [ ! -f "$signed" ] && echo -e "\\033[1;31m[ sign_target_files_apks ]\\033[0;0m" >&2 && exit 1
        echo     "  - $signed"
        echo     "  ota_from_target_files"
        ./build/tools/releasetools/ota_from_target_files ${signed} ${ota} > /dev/null
        [ $? -ne 0 ] || [ ! -f "$ota" ] && echo -e "\\033[1;31m[ ota_from_target_files ]\\033[0;0m" >&2 && exit 1
        echo     "  - $ota"
        rm -f ${signed}
        echo -ne "\\033[1m"
        echo     "[ Finalizing... ]"
        echo -ne "\\033[0m"
        # updater-script
        echo     "  updater-script"
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
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ unzip ]\\033[0;0m" >&2 && exit 1
        zip -u ${ota} ${updaterscript} >/dev/null
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ zip ]\\033[0;0m" >&2 && exit 1
        rm -rf META-INF
        # build.prop
        echo     "  build.prop"
        unzip -p ${ota} ${buildprop} > ${buildprop}
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ unzip ]\\033[0;0m" >&2 && exit 1
        sed -i "s/$user/shkmod/g" ${buildprop}
        sed -i -r 's/(ro.build.host)=.+$/\1=shkmod/' ${buildprop}
        sed -i '/ro.com.android.gps/d' ${buildprop}
        echo "ro.com.android.gps=false" >> ${buildprop}
        sed -i '/ro.com.android.mobiledata/d' ${buildprop}
        echo "ro.com.android.mobiledata=true" >> ${buildprop}
        sed -i '/ro.com.android.dataroaming/d' ${buildprop}
        echo "ro.com.android.dataroaming=false" >> ${buildprop}
        sed -i '/^$/d' ${buildprop}
        zip -u ${ota} ${buildprop} >/dev/null
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ zip ]\\033[0;0m" >&2 && exit 1
        rm -f ${buildprop}
        # recovery
        echo     "  recovery"
        zip -d ${ota} "system/etc/recovery-resource.dat" >/dev/null
        [ $? -ne 0 ] && echo -e "\\033[1;31m[ zip ]\\033[0;0m" >&2 && exit 1
        # rom
        mv ${ota} ${rom}
        [ ! -f "$rom" ] && echo -e "\\033[1;31m[ $rom ]\\033[0;00m" && exit 1
        echo -ne "\\033[1;32m"
        echo     "[ $rom $(md5sum "$rom" | awk '{print $1}') ]"
        echo -ne "\\033[0;00m"
        factory="$dist/$TARGET_PRODUCT-img-eng.$user.zip"
        if [ -f "$factory" ] ; then
            mv ${factory} ${stock}
            echo "  $stock"
        fi
        # root?
        # gapps
        echo     "  http://opengapps.org"
    fi
}

exit 0

# EOF
