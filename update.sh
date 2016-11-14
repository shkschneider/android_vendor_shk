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

command -v git >/dev/null 2>&1 \
    || { echo "$ko[ git ]$rz" >&2 && exit 1 ; }

# arguments parsing
push=0
while getopts ":p" opt ; do
    case $opt in
        p) push=1 ;;
        # allows no other option
        \?) echo "$ko[ -$OPTARG ]$rz" >&2 && exit 1 ;;
    esac
done
shift $((OPTIND - 1))
ref="$1"
[ -z "$ref" ] && echo "$ko[ ref ]$rz" >&2 && exit 1
[ -z "$(echo "$ref" | egrep 'android-[0-9\.]+(_.+)?')" ] && echo "$ko[ ref ]$rz" >&2 && exit 1
echo "$bd[ $ref ]$rz"

# manifests
[ -d ".repo" ] || { echo "$ko[ .repo ]$rz" >&2 && exit 1 ; }
[ -d ".repo/manifests" ] || { echo "$ko[ .repo/manifests ]$rz" >&2 && exit 1 ; }
default=".repo/manifests/default.xml"
[ -f "$default" ] || { echo "$ko[ $default ]$rz" >&2 && exit 1 ; }
[ -z "$(git -C ".repo/manifests" status --porcelain 2>/dev/null)" ] \
    || { echo "$ko[ .repo/manifests ]$rz" >&2 && exit 1 ; }
echo "$default"
revision=$(basename $(cat "$default" | egrep 'default\s+revision' | cut -d'"' -f2))
[ -z "$revision" ] && echo "$ko[ default revision ]$rz" >&2 && exit 1
if [ "$ref" != "$revision" ] ; then
    echo "$wn  $default: $revision$rz" >&2
    cd ".repo/manifests"
    r=$(git ls-remote --heads 2>/dev/null | grep "refs/heads/$ref" | wc -l)
    [ $r -eq 0 ] && echo "$wn  git ls-remote$rz" >&2 && exit 1
    git fetch -a >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$wn  git fetch$rz" >&2 && exit 1
    git checkout default >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$wn  git checkout$rz" >&2 && exit 1
    git reset --hard "origin/$ref" >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$wn  git reset --hard$rz" >&2 && exit 1
    git branch -u "origin/$ref" >/dev/null 2>&1
    [ $? -ne 0 ] && echo "$wn  git branch -u$rz" >&2 && exit 1
    echo "  $default: $ref" >&2
    cd - >/dev/null
fi
unset revision
[ -z "$(git -C ".repo/local_manifests" status --porcelain 2>/dev/null)" ] \
    || { echo "$ko[ .repo/local_manifests ]$rz" >&2 && exit 1 ; }
local_manifests=$(find ".repo/local_manifests" -type f -name "*.xml")

aosp="https://android.googlesource.com/platform"
shk="https://github.com/shkschneider/android_"
conflicts=0
while read manifest ; do
    echo "$manifest"
    # projects
    for project in $(cat "$manifest" | egrep ' path="' | sed -r 's/^.+\spath="([^"]+)".+$/\1/g') ; do
        echo "  $project"
        [[ $project =~ ^vendor/ ]] && continue
        # status
        remote=$(grep " path=\"$project\"" "$manifest" | sed -r 's/^.+\sremote="([^"]+)".+$/\1/g')
        [ -z "$remote" ] && echo "$wn    remote$rz" >&2 && continue
        revision=$(grep " path=\"$project\"" "$manifest" | sed -r 's/^.+\srevision="([^"]+)".+$/\1/g')
        [ -z "$revision" ] && echo "$wn    revision$rz" >&2 && continue
        [ -z "$(git -C "$project" status --porcelain 2>/dev/null)" ] || { echo "$wn    status$rz" >&2 && continue ; }
        cd "$project"
        commit="$(git rev-parse HEAD)"
        [ -z "$commit" ] && echo "$wn    commit$rz" >&2 && cd - >/dev/null && continue
        branch="$revision"
        echo "    $revision @ $remote"
        # checkout
        if [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" != "$branch" ] ; then
            echo "    checkout $branch"
            git checkout "$branch" 2>/dev/null >&2 \
                || { echo "$ko  git checkout$rz" >&2 && cd - >/dev/null && continue ; }
        fi
        # remote: aosp
        git remote show aosp 2>/dev/null >&2
        if [ $? -ne 0 ] ; then
            echo "    $aosp/$project"
            git remote add aosp "$aosp/$project" \
                || { echo "$wn    remote: aosp$rz" >&2 && cd - >/dev/null && continue ; }
        fi
        git fetch -a aosp 2>/dev/null >&2 \
            || { echo "$wn    fetch: aosp$rz" >&2 && cd - >/dev/null && continue ; }
        git show-ref "refs/tags/$ref" 2>/dev/null >&2 \
            || { echo "$wn    show-ref: $ref$rz" >&2 && cd - >/dev/null && continue ; }
        # pull
        if [ "$(git describe --abbrev=0 2>/dev/null)" != "$ref" ] ; then
            echo "    pulling (theirs) '$ref'..."
            git pull -X theirs aosp "$ref" 2>/dev/null >&2 \
                || { conflicts=$(($conflicts + 1)) ; echo "$wn    conflicts$rz" >&2 \
                         && cd - >/dev/null && continue ; }
            # push
            if [ $push -eq 1 ] ; then
                git remote show "$remote" 2>/dev/null >&2 \
                    || { echo "$wn    remote: $remote$rz" >&2 && cd - >/dev/null && continue ; }
                echo "    pushing '$remote'..."
                git push "$remote" "$branch" >/dev/null
            fi
        fi
        unset remote revision branch
        if [ -n "$(git status --porcelain 2>/dev/null)" ] ; then
            echo "$wn    status$rz" >&2
            conflicts=$(($conflicts + 1))
            cd - >/dev/null && continue
        fi
        # continue
        echo "    checkout $commit"
        git checkout "$commit" >/dev/null 2>&1
        unset commit
        cd - >/dev/null
    done
done < <(echo "$local_manifests" | egrep -v '^vendor/')

[ $conflicts -gt 0 ] && echo "$ko[ $conflicts conflicts ]$rz" >&2
# repo sync
echo "$bd[ repo sync ]$rz"

exit $conflicts

# EOF
