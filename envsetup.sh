# source

[ ! -f "vendor/shk/envsetup.sh" ] && return 1

export ANDROID_BUILD_TOP=$(pwd)
export ANDROID_PRODUCT_OUT=$ANDROID_BUILD_TOP/out/target/product/generic_x86_64

emulator="$ANDROID_BUILD_TOP/prebuilts/android-emulator/$(echo "$(uname -s | tr "[A-Z]" "[a-z]")-$(uname -m)")/emulator"
[ ! -f "$emulator" ] && echo "$ko[ $emulator ]$rz" >&2 && return 1
emulator="$(dirname "$emulator")"
# http://superuser.com/a/39995
if [[ ":$PATH:" != *":$emulator:"* ]] ; then
    export PATH="$emulator:$PATH"
fi

return 0
