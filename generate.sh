#!/usr/bin/env bash
set -euo pipefail

inputs=(
    https://raw.githubusercontent.com/paketo-buildpacks/github-config/master/.github/data/language-family-cnbs
    https://raw.githubusercontent.com/paketo-buildpacks/github-config/master/.github/data/implementation-cnbs
)
output=
output_file=README.md

urlencode() {
    for (( i = 0; i < "${#1}"; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
        *) printf '%%%02X' "'$c" ;;
        esac
    done
}

writeout() { output="$output""$1"; }

parse_repo() {
    repo="https://github.com/$1"
    repotmp="$tmpd/$1"
    writeout "**$1**\n\n"
    rm -rf "$repotmp"
    git clone --bare "$repo" "$repotmp" 2> /dev/null

    count=0
    while read -r workflow; do
        name=$(yq r <(curl -sL "https://raw.githubusercontent.com/$1/master/$workflow") name)
        [ -z "$name" ] && name="$workflow"
        encoded_name="$(urlencode "$name")"
        writeout "["
        writeout "![${name}](${repo}/workflows/"$encoded_name"/badge.svg)"
        writeout "]"
        writeout "(${repo}/actions?query=workflow:\""$encoded_name"\")"
        count=$((count+1))
    done < <(git -C "$repotmp" ls-tree -r HEAD | awk '{print $4}' | grep '^.github/workflows/')

    [ $count -eq 0 ] && writeout "(none)"
    writeout "\n\n"
    echo " Generated markdown for $1"
}

command -v yq > /dev/null || { echo "Need yq"; exit 1; }
tmpd="$(mktemp -d -t dashboardXXXX)"
for input in "${inputs[@]}"; do
    echo Generating markdown for "${input##*/}"...
    writeout "\n\n"
    while read -r repo; do
        parse_repo "$repo"
    done < <(curl -sL "$input")
    writeout "\n\n"
done
echo -e "$output" > "$output_file"
echo Wrote to "$output_file"
rm -rf "$tmpd"
