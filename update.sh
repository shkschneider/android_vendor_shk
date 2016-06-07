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

id="shkschneider"

# colors
bd=$(tput bold)
ok=$(tput setaf 2)
wn=$(tput setaf 3)
ko=$(tput setaf 1)
rz=$(tput sgr0)

# general checks
[ ! -d ".repo" ] && echo "$ko[ .repo ]$rz" >&2 && exit 1
default=".repo/manifests/default.xml"
roomservice=".repo/local_manifests/roomservice.xml"

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
ref="$1"
[ -z "$ref" ] && echo "$ko[ ref ]$rz" >&2 && exit 1
[ -z "$(echo "$ref" | egrep 'android-[0-9\.]+(_.+)?')" ] && echo "$ko[ ref ]$rz" >&2 && exit 1
echo "$bd[ $ref ]$rz"

# default.xml
[ ! -f "$default" ] && echo "$ko[ $default ]$rz" >&2 && exit 1
cd ".repo/manifests"
git diff --exit-code -- default.xml 2>/dev/null >&2
[ $? -ne 0 ] && echo "$wn  git status$rz" >&2
cd - >/dev/null
c=$(basename $(cat "$default" | egrep 'default\s+revision' | cut -d'"' -f2))
[ -z "$c" ] && echo "$ko[ default revision ]$rz" >&2 && exit 1
if [ "$c" != "$ref" ] ; then
    echo "$wn  $default: $r$rz" >&2
    cd ".repo/manifests"
    r=$(git ls-remote --heads 2>/dev/null | grep "refs/heads/$ref" | wc -l)
    [ $r -eq 0 ] && echo "$wn  git ls-remote$rz" >&2 && exit 1
    git checkout "$ref" >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$wn  git checkout$rz" >&2 && exit 1
    git pull >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$wn  git pull$rz" >&2 && exit 1
    echo "  $default: $ref" >&2
    cd - >/dev/null
fi

# roomservice.xml
[ ! -f "$roomservice" ] && echo "$ko[ $roomservice ]$rz" >&2 && exit 1
cd ".repo/local_manifests"
git diff --exit-code -- roomservice.xml 2>/dev/null >&2
[ $? -ne 0 ] && echo "$wn  git status$rz" >&2
cd - >/dev/null

# all my repositories (except vendor)
aosp="https://android.googlesource.com/platform"
shk="https://github.com/shkschneider/android_"
conflicts=0
for p in $(cat "$roomservice" | grep ' remote="github"' | grep " name=\"$id/" | sed -r 's/^.+ path="([^"]+)".+$/\1/g' | grep -v 'vendor/shk') ; do
    echo "- $p"
    [ $info -ne 0 ] && continue
    branch=$(cat "$roomservice" | grep " path=\"$p\"" | grep ' remote="github"' | grep " name=\"$id/" | sed -r 's/^.+\srevision="(shk-[a-z]+)".+$/\1/g')
    [ -z "$branch" ] && echo "$ko  revision$rz" >&2 && exit 1
    cd "$p"
    [ ! -d ".git" ] && echo "$ko  git$rz" >&2 && exit 1
    git diff --exit-code >/dev/null
    [ $? -ne 0 ] && echo "$ko  git status$rz" >&2 && cd - >/dev/null && continue
    commit=$(git rev-parse HEAD)
    [ -z "$commit" ] && echo "$ko  git commit$rz" >&2 && cd - >/dev/null && continue
    if [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" != "$branch" ] ; then
        echo "  checkout $branch"
        git checkout "$branch" 2>/dev/null >&2
        [ $? -ne 0 ] && echo "$ko  git checkout$rz" >&2 && cd - >/dev/null && continue
    fi
    # github remote
    echo "  remote github"
    git remote show github 2>/dev/null >&2
    [ $? -ne 0 ] && echo "$ko  git remote: github$rz" >&2 && cd - >/dev/null && continue
    # aosp remote
    echo "  remote aosp"
    git remote show aosp 2>/dev/null >&2
    if [ $? -ne 0 ] ; then
        echo "  + $aosp/$p"
        git remote add aosp "$aosp/$p"
        [ $? -ne 0 ] && echo "$ko  git remote: aosp$rz" >&2 && cd - >/dev/null && continue
    fi
    git fetch -a aosp 2>/dev/null >&2
    [ $? -ne 0 ] && echo "$ko  git fetch: aosp$rz" >&2 && cd - >/dev/null && continue
    git show-ref "refs/tags/$ref" 2>/dev/null >&2
    [ $? -ne 0 ] && echo "$wn  git show-ref: $ref$rz" >&2 && cd - >/dev/null && continue
    # pull
    echo "  pulling..."
    git pull aosp "$ref" 2>/dev/null >&2
    if [ $? -ne 0 ] ; then
        conflicts=$(($conflicts + 1))
        echo "$wn  conflicts$rz" >&2
        cd - >/dev/null
        continue
    fi
    # push (if needed)
    if [ "$(git rev-parse HEAD)" != "$commit" ] ; then
        echo "  pushing..."
        git push github "$branch" >/dev/null
    else
        echo "  up-to-date"
    fi
    cd - >/dev/null
done

if [ $conflicts -gt 0 ] ; then
    echo "$ko[ $conflicts conflicts ]$rz"
fi
# repo sync
echo "$bd[ repo sync ]$rz"

exit 0

# EOF
