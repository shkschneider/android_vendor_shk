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

PRODUCT_NAME ?= shkmod

PRODUCT_PROPERTY_OVERRIDES += ro.mod.name=ShkMod
PRODUCT_PROPERTY_OVERRIDES += ro.mod.version=16.12.13
PRODUCT_PROPERTY_OVERRIDES += persist.adb.notify=0

ifeq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_PROPERTY_OVERRIDES += ro.adb.secure=1
endif

PRODUCT_PACKAGES += org.fdroid.fdroid

ifneq ("$(wildcard vendor/shk/prebuilt/system/media/bootanimation/$(PRODUCT_DEVICE).zip)","")
PRODUCT_COPY_FILES += vendor/shk/prebuilt/system/media/bootanimation/$(PRODUCT_DEVICE).zip:system/media/bootanimation.zip
else
PRODUCT_COPY_FILES += vendor/shk/prebuilt/system/media/bootanimation.zip:system/media/bootanimation.zip
endif

PRODUCT_RESTRICT_VENDOR_FILES := false

PRODUCT_PACKAGE_OVERLAYS += vendor/shk/overlay

ifneq ($(TARGET_BUILD_VARIANT),eng)
$(call inherit-product-if-exists, vendor/google/google.mk)
endif

# EOF
