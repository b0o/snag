#!/bin/bash

# Copyright (C) 2020-2021 Maddison Hellstrom <https://github.com/b0o>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -Eeuo pipefail
shopt -s inherit_errexit

declare -g self prog basedir reporoot
self="$(readlink -e "${BASH_SOURCE[0]}")"
prog="$(basename "$self")"
basedir="$(realpath -m "$self/..")"
reporoot="$(realpath -m "$basedir/..")"

# gendocs configuration {{{

declare -g snag="${reporoot}/snag"

declare -gA targets=(
  [readme]="$reporoot/README.md"
)

function target_readme() {
  section -s USAGE -c <<< "$("$snag" -h 2>&1)"
  section -s LICENSE << EOF
&copy; 2020-$(date +%Y) Maddison Hellstrom

Released under the GNU General Public License, version 3.0 or later.
EOF
}

# }}}

declare -gA sections

function section() {
  local section
  local -i code=0
  local lang

  local opt OPTARG
  local -i OPTIND
  while getopts "s:cC:" opt "$@"; do
    case "$opt" in
    s)
      section="$OPTARG"
      ;;
    c)
      code=1
      ;;
    C)
      code=1
      lang="$OPTARG"
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  local -a lines=()

  if [[ $code -eq 1 ]]; then
    lines+=('```'"${lang:-}")
  fi

  mapfile -tO ${#lines[@]} lines

  if [[ $code -eq 1 ]]; then
    lines+=('```')
  fi

  sections["$section"]="$(printf '%s\n' "${lines[@]}")"
}

function regen_section() {
  local section="$1"
  local content="${sections[$section]}"
  < "$target" awk -v "section=$section" -v "content=$content" '
    BEGIN {
      d = 0
    }

    {
      if (match($0, "^<!-- " section " -->$")) {
        d = 1
        print $0
        print content
        next
      }
      if (match($0, "^<!-- /" section " -->$")) {
        d = 0
        print $0
        next
      }
    }

    d == 0 {
      print $0
    }
  '
}

function main() {
  local opt OPTARG
  local -i OPTIND
  while getopts "h" opt "$@"; do
    case "$opt" in
    h)
      echo "usage: $prog [opt].. [target].." >&2
      return 0
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  local -a targets_selected=("${!targets[@]}")

  if [[ $# -gt 0 ]]; then
    targets_selected=("$@")
  fi

  local t target
  for t in "${targets_selected[@]}"; do
    [[ -v "targets[$t]" ]] || {
      echo "unknown target: $t" >&2
      return 1
    }
    target="${targets["$t"]}"
    [[ -e "$target" ]] || {
      echo "target file not found: $target" >&2
      return 1
    }
    sections=()
    "target_${t}" || {
      echo "unknown target: $t"
      return 1
    }
    local s
    for s in "${!sections[@]}"; do
      regen_section "$s" > "${target}_"
      mv "${target}_" "$target"
    done
  done
}

main "$@"
