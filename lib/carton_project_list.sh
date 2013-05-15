#
# Project list
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

if [ -z "${_CARTON_PROJECT_LIST_SH+set}" ]; then
declare _CARTON_PROJECT_LIST_SH=

. carton_util.sh
. carton_project.sh

# Repository directory
declare -r CARTON_PROJECT_LIST_DIR="$CARTON_DATA_DIR/project"

# Check if a string is a valid project name.
# Args: str
function carton_project_list_is_valid_name()
{
    carton_is_valid_fs_name "$1"
}

# Output the list of project names, one per line.
function carton_project_list_list_projects()
{
    carton_assert "[ -d \"\$CARTON_PROJECT_LIST_DIR\" ]"
    ls -1 "$CARTON_PROJECT_LIST_DIR"
}

# Get project location arguments.
# Args: _project_name
declare -r _CARTON_PROJECT_LIST_GET_PROJECT_LOC='
    declare -r _project_name="$1";   shift
    carton_assert "carton_project_list_is_valid_name \"\$_project_name\""
    carton_assert "[ -d \"\$CARTON_PROJECT_LIST_DIR\" ]"
    declare -r _project_dir="$CARTON_PROJECT_LIST_DIR/$_project_name"
'

# Check if a project exists.
# Args: _project_name
function carton_project_list_has_project()
{
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    [ -e "$_project_dir" ]
}

# Create and get a project.
# Args: _project_var _project_name _dir _repo_url [_tag_glob _tag_format]
function carton_project_list_add_project()
{
    declare -r _project_var
    carton_assert "carton_is_valid_var_name \"\$_project_var\""
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    carton_assert "! carton_project_list_has_project \"\$_project_name\""
    mkdir "$_project_dir"
    carton_project_init "$_project_var" "$_project_dir" "$@"
}

# Get a project.
# Args: _project_var _project_name
function carton_project_list_get_project()
{
    declare -r _project_var
    carton_assert "carton_is_valid_var_name \"\$_project_var\""
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    carton_assert "carton_project_list_has_project \"\$_project_name\""
    carton_project_load "$_project_var" "$_project_dir"
}

# Delete a project.
# Args: _project_name
function carton_project_list_del_project()
{
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    carton_assert 'carton_project_list_has "$_project_name"'
    rm -Rf -- "$_project_dir"
}

fi # _CARTON_PROJECT_LIST_SH
