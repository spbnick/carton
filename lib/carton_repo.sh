#
# Package repository object
#
# Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing
# to use, modify, copy, or redistribute it subject to the terms
# and conditions of the GNU General Public License version 2.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.

if [ -z "${_CARTON_REPO_SH+set}" ]; then
declare _CARTON_REPO_SH=

. carton_util.sh

# Load base repository parameters
# Args: dir
declare -r _CARTON_REPO_LOAD_BASE='
    declare -r dir="$1";       shift
    carton_assert "[ -d \"\$dir\" ]"

    declare -A repo=(
        [dir]="$dir"
        [rpm_dir]="$dir/rpm"
    )
'

# Initialize a repo and output its string.
# Args: dir
# Output: repo string
function carton_repo_init()
{
    eval "$_CARTON_REPO_LOAD_BASE"
    mkdir "${repo[rpm_dir]}"
    createrepo --quiet "${repo[rpm_dir]}"
    carton_arr_print repo
}

# Load and output a repo string.
# Args: dir
# Output: repo string
function carton_repo_load()
{
    eval "$_CARTON_REPO_LOAD_BASE"
    carton_arr_print repo
}

# Get repo/revision pair from arguments
# Args: repo_str rev_str
declare -r _CARTON_REPO_GET_REPO_AND_REV='
    declare -r repo_str="$1"; shift
    declare -r rev_str="$1"; shift
    declare -A repo
    carton_arr_parse "repo" <<<"$repo_str"
    declare -A rev
    carton_arr_parse "rev" <<<"$rev_str"
'

# Check if a commit revision is published in a repo.
# Args: repo_str rev_str
function carton_repo_is_published()
{
    eval "$_CARTON_REPO_GET_REPO_AND_REV"
    declare f
    while read -r f; do
        if ! [ -e "${repo[rpm_dir]}/$f" ]; then
            return 1
        fi
    done < <(
        find "${rev[rpm_dir]}" -name "*.rpm" -printf '%f\n'
    )
    return 0
}

#
# TODO Atomic publishing/withdrawing
#

# Publish a commit revision in a repo.
# Args: repo_str rev_str
function carton_repo_publish()
{
    eval "$_CARTON_REPO_GET_REPO_AND_REV"
    carton_assert '! carton_repo_is_published "$repo_str" "$rev_str"'
    find "${rev[rpm_dir]}" -name "*.rpm" -print0 |
        xargs -0 cp -t "${repo[rpm_dir]}"
    createrepo --quiet --update "${repo[rpm_dir]}"
}

# Withdraw (remove) a commit revision from a repo.
# Args: repo_str rev_str
function carton_repo_withdraw()
{
    eval "$_CARTON_REPO_GET_REPO_AND_REV"
    carton_assert 'carton_repo_is_published "$repo_str" "$rev_str"'
    declare f
    while read -r f; do
        rm "${repo[rpm_dir]}/$f"
    done < <(
        find "${rev[rpm_dir]}" -name "*.rpm" -printf '%f\n'
    )
    createrepo --quiet --update "${repo[rpm_dir]}"
}

fi # _CARTON_REPO_SH
