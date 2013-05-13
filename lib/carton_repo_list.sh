#
# Repository list
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

if [ -z "${_CARTON_REPO_LIST_SH+set}" ]; then
declare _CARTON_REPO_LIST_SH=

. carton_util.sh
. carton_repo.sh

# Repository directory
declare -r CARTON_REPO_LIST_DIR="$CARTON_DATA_DIR/repo"

# Check if a string is a valid repo name.
# Args: str
function carton_repo_list_is_valid_name()
{
    carton_is_valid_fs_name "$1"
}

# Output the list of repo names, one per line.
function carton_repo_list_list_repos()
{
    carton_assert "[ -d \"\$CARTON_REPO_LIST_DIR\" ]"
    ls "$CARTON_REPO_LIST_DIR"
}

# Get repo location arguments.
# Args: _repo_name
declare -r _CARTON_REPO_LIST_GET_REPO_LOC='
    declare -r _repo_name="$1";   shift
    carton_assert "carton_repo_list_is_valid_name \"\$_repo_name\""
    carton_assert "[ -d \"\$CARTON_REPO_LIST_DIR\" ]"
    declare -r _repo_dir="$CARTON_REPO_LIST_DIR/$_repo_name"
'

# Check if a repository exists.
# Args: _repo_name
function carton_repo_list_has_repo()
{
    eval "$_CARTON_REPO_LIST_GET_REPO_LOC"
    [ -e "$_repo_dir" ]
}

# Create and get a repository.
# Args: _repo_var _repo_name
function carton_repo_list_add_repo()
{
    declare -r _repo_var="$1";  shift
    carton_assert "carton_is_valid_var_name \"\$_repo_var\""
    eval "$_CARTON_REPO_LIST_GET_REPO_LOC"
    carton_assert "! carton_repo_list_has_repo \"\$_repo_name\""
    mkdir "$_repo_dir"
    carton_repo_init "$_repo_var" "$_repo_dir" "$@"
}

# Get a repository.
# Args: _repo_var _repo_name
function carton_repo_list_get_repo()
{
    declare -r _repo_var="$1";  shift
    carton_assert "carton_is_valid_var_name \"\$_repo_var\""
    eval "$_CARTON_REPO_LIST_GET_REPO_LOC"
    carton_assert "carton_repo_list_has_repo \"\$_repo_name\""
    carton_repo_load "$_repo_var" "$_repo_dir"
}

# Delete a repository.
# Args: _repo_name
function carton_repo_list_del_repo()
{
    eval "$_CARTON_REPO_LIST_GET_REPO_LOC"
    carton_assert "carton_repo_list_has_repo \"\$_repo_name\""
    rm -Rf -- "$_repo_dir"
}

fi # _CARTON_REPO_LIST_SH
