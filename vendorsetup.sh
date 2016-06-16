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

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -z "$dir" ] && exit 1
while read file ; do
    target=$(egrep '^PRODUCT_NAME' "$file" | sed -r 's;#.+$;;g' | awk '{print $NF}')
    [ -z "$target" ] && continue
    [[ $t =~ _emulator$ ]] && variants="eng userdebug" || variants="user"
    for variant in $variants ; do
        add_lunch_combo "$target-$variant"
    done
done < <(find "$dir" -type f -name "shkmod_*.mk")

# EOF
