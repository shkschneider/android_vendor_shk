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

PRODUCT_RESTRICT_VENDOR_FILES := false

PRODUCT_PROPERTY_OVERRIDES += \
	ro.mod.name=ShkMod \
	ro.mod.version=16.03.00 \
	persist.adb.notify=0

PRODUCT_COPY_FILES += \
        vendor/shk/prebuilt/system/media/bootanimation.zip:system/media/bootanimation.zip

PRODUCT_COPY_FILES += \
	vendor/shk/prebuilt/system/media/audio/ringtones/Enter_the_Nexus.ogg:system/media/audio/ringtones/Enter_the_Nexus.ogg \
	vendor/shk/prebuilt/system/media/audio/notifications/Teleport.ogg:system/media/audio/notifications/Teleport.ogg

PRODUCT_PACKAGE_OVERLAYS += \
	vendor/shk/overlay

# EOF
