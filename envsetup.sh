# source
[ ! -f "vendor/shk/envsetup.sh" ] && return 1
export ANDROID_BUILD_TOP=$(pwd)
export ANDROID_PRODUCT_OUT=$ANDROID_BUILD_TOP/out/target/product/generic_x86_64
return 0
