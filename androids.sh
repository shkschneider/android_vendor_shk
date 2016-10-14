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

git ls-remote --heads https://android.googlesource.com/platform/manifest \
    | egrep 'android-[0-9]' \
    | rev | cut -d'/' -f1 | rev \
    | sort -V

manifest=".repo/manifests/default.xml"
[ ! -f "$manifest" ] && exit 0
default=$(grep '<default' $manifest 2>/dev/null | cut -d'"' -f2 | rev | cut -d'/' -f1 | rev)
[ -n "$default" ] && echo "[ $default ]"

exit 0

# EOF
