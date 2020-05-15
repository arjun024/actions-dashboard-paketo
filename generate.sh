#!/usr/bin/env bash

set -euo pipefail

markdown_file=README.md
output=
tmpd="$(mktemp -d -t dashboardXXXX)"

urlencode() {
    for (( i = 0; i < "${#1}"; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
        *) printf '%%%02X' "'$c" ;;
        esac
    done
}

header() {
    output="${output}*(This is the dashboard. See [doc.md](doc.md) for documentation)*\n\n"
}

parse_repo() {
    repo="$1"
    repotmp="$tmpd/$repo"
    output="${output}#### ${repo}\n"
    rm -rf "$repotmp"

    git clone --bare https://github.com/"$repo" "$repotmp" 2> /dev/null

    count=0
    while read -r workflow; do
        name=$(yq r <(curl -sL 'https://raw.githubusercontent.com/'"$repo"'/master/'"$workflow") name)
        [ -z "$name" ] && name=workflow
        encoded_name="$(urlencode "$name")"
        output="${output}[![${name}]"'(https://github.com/'"${repo}/workflows/${encoded_name}"'/badge.svg)'
        output="${output}](https://github.com/${repo}/actions?query=workflow:\"${encoded_name}\")"
        output="${output}\n\n"
        count=$((count+1))
    done < <(git -C "$repotmp" ls-tree -r HEAD | awk '{print $4}' | grep '^.github/workflows/')

    [ $count -eq 0 ] && output="${output}\nNo workflows\n\n"
    echo " Generated markdown for $repo"
}

header
for type in 'language-family-cnbs' 'implementation-cnbs' ; do
    echo Generating markdown for "$type"...
    output="${output}### ${type}\n"
    while read -r repo; do
        parse_repo "$repo"
    done < <(curl -sL https://raw.githubusercontent.com/paketo-buildpacks/github-config/master/.github/data/${type})
    output="${output}---\n"
done
parse_repo paketo-buildpacks/github-config

echo -e "$output" > "$markdown_file"
echo Wrote to "$markdown_file"
rm -rf "$tmpd"
