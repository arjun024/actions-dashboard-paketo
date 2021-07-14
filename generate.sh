#!/usr/bin/env bash
set -euo pipefail

inputs=(
    ./builders-and-composites
    ./implementations
    ./non-cnbs
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

isurl() { [[ "$1" =~ https?://* ]]; }

writeout() { output="$output""$1"; }

header() {
    writeout "*(Generated file. See [doc.md](doc.md) for documentation)*\n\n"
}

table_begin() {
    writeout '<table><tr>'
    for i in "${inputs[@]}"; do
        writeout '<td><b>'"${i##*/}"'</b></td>'
    done
    writeout '</tr><tr>'
}

table_end() { writeout '</tr></table>'; }

parse_repo() {
    repo="https://github.com/$1"
    repotmp="$tmpd/$1"
    writeout "**${repo##*/}**<br/>"
    rm -rf "$repotmp"
    git clone --depth=1 "$repo" "$repotmp" 2> /dev/null

    count=0
    while read -r workflow; do
        [[ "$workflow" != *.yaml ]] && [[ "$workflow" != *.yml ]] && continue
        name=$(yq r "${repotmp}/${workflow}" name)
        [ -z "$name" ] && name="$workflow"
        encoded_name="$(urlencode "$name")"
        writeout "["
        # query param to bust cache
        writeout "![${name}](${repo}/workflows/$encoded_name/badge.svg?kill_cache=1)"
        writeout "]"
        writeout "(${repo}/actions?query=workflow:\"$encoded_name\")"
        count=$((count+1))
    done < <(git -C "$repotmp" ls-tree -r HEAD | awk '{print $4}' | grep '^.github/workflows/')

    [ $count -eq 0 ] && writeout "\n(none)"
    writeout '<br/><br/>'
    echo " Generated markdown for $1"
}

command -v yq > /dev/null || { echo "Need yq"; exit 1; }
tmpd="$(mktemp -d -t dashboardXXXX)"
header
table_begin

for i in "${inputs[@]}"; do
    echo Generating markdown for "${i##*/}"...
    writeout "<td>\n\n"
    count=0
    while read -r line; do
        [[ "$line" = \#* ]] && continue
        [ -z "$line" ] && continue
        parse_repo "$line"
        count=$((count+1))
    done < <(if isurl "$i"; then curl -sL "$i"; else cat "$i"; fi)
    [ $count -eq 0 ] && { echo "Failed to read $i"; exit 1; }
    writeout "</td>\n\n"
done

table_end

echo -e "$output" > "$output_file"
echo Wrote to "$output_file"
rm -rf "$tmpd"
