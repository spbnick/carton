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
# Args: _dir
declare -r _CARTON_REPO_LOAD_BASE='
    declare -r _dir="$1";       shift
    carton_assert "[ -d \"\$_dir\" ]"

    declare -A _repo=(
        [dir]="$_dir"
        [rpm_dir]="$_dir/rpm"
    )
'

# Initialize a repo.
# Args: _repo_var _dir
function carton_repo_init()
{
    declare -r _repo_var="$1";  shift
    carton_assert 'carton_is_valid_var_name "$_repo_var"'
    eval "$_CARTON_REPO_LOAD_BASE"
    createrepo "${_repo[dir]}"
    carton_arr_copy "$_repo_var" _repo
}

# Load a repo.
# Args: _repo_var _dir
function carton_repo_load()
{
    declare -r _repo_var="$1";  shift
    carton_assert 'carton_is_valid_var_name "$_repo_var"'
    eval "$_CARTON_REPO_LOAD_BASE"
    carton_arr_copy "$_repo_var" _repo
}

# Get repo/revision pair from arguments
# Args: _repo_var _rev_var
declare -r _CARTON_REPO_GET_REPO_AND_REV='
    declare -r _repo_var="$1"; shift
    carton_assert "carton_is_valid_var_name \"\$_repo_var\""
    declare -r _rev_var="$1"; shift
    carton_assert "carton_is_valid_var_name \"\$_rev_var\""
    declare -A _repo
    carton_arr_copy "_repo" "$_repo_var"
    declare -A _rev
    carton_arr_copy "_rev" "$_rev_var"
'

# Check if a commit revision is published in a repo.
# Args: _repo_var _rev_var
function carton_repo_is_published()
{
    eval "$_CARTON_REPO_GET_REPO_AND_REV"
    declare f
    while read -r f; do
        if ! [ -e "${_repo[rpm_dir]}/$f" ]; then
            return 1
        fi
    done < <(
        find "${_rev[rpm_dir]}" -name "*.rpm" -printf '%f\n'
    )
    return 0
}

#
# TODO Atomic publishing/withdrawing
#

# Publish a commit revision in a repo.
# Args: _repo_var _rev_var
function carton_repo_publish()
{
    eval "$_CARTON_REPO_GET_REPO_AND_REV"
    carton_assert '! carton_repo_is_published "$_repo_var" "$_rev_var"'
    find "${_rev[rpm_dir]}" -name "*.rpm" -print0 |
        xargs -0 cp -t "${_repo[rpm_dir]}"
    createrepo --update "${_repo[rpm_dir]}"
}

# Withdraw (remove) a commit revision from a repo.
# Args: _repo_var _rev_var
function carton_repo_withdraw()
{
    eval "$_CARTON_REPO_GET_REPO_AND_REV"
    carton_assert 'carton_repo_is_published "$_repo_var" "$_rev_var"'
    declare f
    while read -r f; do
        rm "${_repo[rpm_dir]}/$f"
    done < <(
        find "${_rev[rpm_dir]}" -name "*.rpm" -printf '%f\n'
    )
    createrepo --update "${_repo[rpm_dir]}"
}

fi # _CARTON_REPO_SH
