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

declare -g basedir reporoot readme
basedir="$(realpath -e "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")")"
reporoot="$(realpath -e "$basedir/..")"
readme="$reporoot/README.md"
usage_cmd="$reporoot/snag -h"

function readme() {
  awk -v "usage_cmd=$usage_cmd" '
    BEGIN {
      d = 0
    }

    /<!-- USAGE -->/ {
      d = 1
      print $0
      print "```"
      system(usage_cmd)
      print "```"
      next
    }

    /<!-- \/USAGE -->/ {
      d = 0
      print $0
      next
    }

    d == 0 {
      print $0
    }
  ' "$readme"
}

readme > "${readme}_"
mv "${readme}_" "$readme"
