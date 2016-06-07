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

out="hosts" # vendor/shk/prebuilt/system/etc/hosts
hosts=(
    "http://adaway.org/hosts.txt"
    # http://sourceforge.net/projects/adzhosts/files/FORADAWAY.txt/download
    "http://hosts-file.net/ad_servers.txt"
    "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype-plaintext"
    "http://winhelp2002.mvps.org/hosts.txt"
)

tmp=$(tempfile -s "_hosts")
for host in "${hosts[@]}" ; do
    echo -n "$host... "
    t=$(tempfile -s "_$(echo "$host" | sed -r 's;^https?://([^/]+)/.+$;\1;g')")
    curl -s "$host" \
        | egrep -v '^\s*#' \
        | egrep '^([0-9\.]+|::1)' \
        | tr -d '\r' \
        | sed -r 's;^([0-9\.]+|::1)\s+;\1 ;g' \
        | sed -r 's;\s*#.+$;;g' \
              2>/dev/null >> "$t"
    cat "$t" | wc -l
    cat "$t" >> "$tmp"
    rm -f "$t"
done
echo "127.0.0.1 localhost" >> "$tmp"
echo "::1 localhost" >> "$tmp"

cat "$tmp" | sed '/^$/d' | sort | uniq > "$out"
rm -f "$tmp"

echo "[ $out ]"
cat "$out" | wc -l

exit 0

# EOF
