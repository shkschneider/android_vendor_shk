# source

[ ! -f "vendor/shk/envsetup.sh" ] && return 1

export ANDROID_BUILD_TOP="$(pwd)"
[ ! -d "$ANDROID_BUILD_TOP" ] && echo "[ ANDROID_BUILD_TOP ]" >&2 && return 1
export ANDROID_PRODUCT_OUT="$ANDROID_BUILD_TOP/out/target/product/generic_x86_64"
[ ! -d "$ANDROID_PRODUCT_OUT" ] && echo "[ ANDROID_PRODUCT_OUT ]" >&2 && return 1
export ANDROID_EMULATOR_PREBUILTS="$ANDROID_BUILD_TOP/prebuilts/android-emulator/$(uname -s | tr "[A-Z]" "[a-z]")-x86_64"
[ ! -d "$ANDROID_EMULATOR_PREBUILTS" ] && echo "[ ANDROID_EMULATOR_PREBUILTS ]" >&2 && return 1

[[ ! -f "$ANDROID_EMULATOR_PREBUILTS/emulator" ]] || [[ ! -x "$ANDROID_EMULATOR_PREBUILTS/emulator" ]] \
    && echo "$[ $ANDROID_EMULATOR_PREBUILTS/emulator ]" >&2 && return 1

if [[ ":$PATH:" != *":$ANDROID_EMULATOR_PREBUILTS:"* ]] ; then
    export PATH="$ANDROID_EMULATOR_PREBUILTS:$PATH"
fi

return 0
